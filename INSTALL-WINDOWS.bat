@echo off
setlocal EnableDelayedExpansion
title MyLikita - Windows Installer
color 0A

:: ============================================================
::  MyLikita — Windows Offline Installer
::  Run this as Administrator on the client machine.
::
::  Place this file at the root of the MyLikita folder, alongside
::  the "backend" and "frontend" subdirectories, with the runtimes
::  pre-placed in the "tools" folder (see the layout note below).
:;
;;  What this script does:
;;   [1/8] Create folders
;;   [2/8] Check / install Node.js (winget if missing)
;;   [3/8] Set up MySQL from an extracted ZIP build (no GUI installer):
;;         mysqld --initialize-insecure -> Windows service -> root password
;;   [4/8] Check embedded NSSM (no download)
;;   [5/8] npm install backend dependencies
;;   [6/8] Write backend\.env
;;   [7/8] Create database and import prime-db.sql
;;   [8/8] Register MyLikita Windows service, firewall, start
;;
;;  Expected folder layout (alongside this .bat):
;;    MyLikita\
;;      backend\                <- backend code (app.js)
;;      frontend\dist\          <- pre-built React app
;;      tools\mysql\            <- MySQL ZIP build, EXTRACTED here
;;                                 (or keep mysql-8.0.42-winx64.zip in
;;                                  tools\ and it will be extracted
;;                                  automatically, or it downloads once)
;;      tools\nssm\nssm.exe     <- embedded NSSM (REQUIRED)
;; ============================================================

echo.
echo  ================================================
echo   MyLikita - Offline Windows Installer
echo  ================================================
echo.

:: ── Check for Administrator privileges ─────────────────────
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  [ERROR] This installer must be run as Administrator.
    echo  Right-click INSTALL-WINDOWS.bat and choose "Run as administrator"
    pause
    exit /b 1
)

:: ── Determine install root (folder where this .bat lives) ──
set "INSTALL_ROOT=%~dp0"
if "%INSTALL_ROOT:~-1%"=="\" set "INSTALL_ROOT=%INSTALL_ROOT:~0,-1%"

set "BACKEND_DIR=%INSTALL_ROOT%\backend"
set "FRONTEND_DIST=%INSTALL_ROOT%\frontend\dist"
set "LOGS_DIR=%INSTALL_ROOT%\logs"
set "TOOLS_DIR=%INSTALL_ROOT%\tools"
set "MYSQL_VERSION=8.0.42"
set "MYSQL_DIR=%TOOLS_DIR%\mysql"
set "MYSQL_ZIP=%TOOLS_DIR%\mysql-%MYSQL_VERSION%-winx64.zip"
set "MYSQL_DATA=%INSTALL_ROOT%\mysql-data"
set "NSSM_EXE=%TOOLS_DIR%\nssm\nssm.exe"

set "DB_NAME=mylikita_db"
set "APP_PORT=46990"
set "DB_PORT=3306"
set "SERVER_IP=localhost"

echo  Install root : %INSTALL_ROOT%
echo  Backend      : %BACKEND_DIR%
echo  Frontend dist: %FRONTEND_DIST%
echo  MySQL        : %MYSQL_DIR%
echo  NSSM         : %NSSM_EXE%
echo.

:: ── Verify required folders exist ──────────────────────────
if not exist "%BACKEND_DIR%\app.js" (
    echo  [ERROR] Backend not found at %BACKEND_DIR%
    echo  Make sure this installer is in the root MyLikita folder.
    pause
    exit /b 1
)

if not exist "%FRONTEND_DIST%\index.html" (
    echo  [ERROR] Frontend dist not found at %FRONTEND_DIST%
    echo  Build the frontend first: cd frontend ^&^& npm run build
    pause
    exit /b 1
)

echo  [OK] Backend and frontend dist found.
echo.

:: ── Reuse credentials from a previous install, if present ──
set "DB_PASS="
if exist "%BACKEND_DIR%\.env" (
    for /f "tokens=1,* delims==" %%a in ('findstr /b "DB_PASSWORD=" "%BACKEND_DIR%\.env"') do set "DB_PASS=%%b"
    for /f "tokens=1,* delims==" %%a in ('findstr /b "DB_PORT=" "%BACKEND_DIR%\.env"') do set "DB_PORT=%%b"
)

:: ── Collect configuration from user ────────────────────────
echo  ------------------------------------------------
echo   CONFIGURATION
echo  ------------------------------------------------
echo.
if "!DB_PASS!"=="" (
    set /p "DB_PASS=Enter MySQL root password (letters and numbers only, no symbols): "
    if "!DB_PASS!"=="" (
        echo  [ERROR] MySQL password cannot be empty.
        pause
        exit /b 1
    )
) else (
    echo  [OK] Reusing MySQL password from existing backend\.env
)

set /p "DB_NAME=Database name [default: mylikita_db]: "
if "!DB_NAME!"=="" set "DB_NAME=mylikita_db"

set /p "APP_PORT=App port [default: 46990]: "
if "!APP_PORT!"=="" set "APP_PORT=46990"

set /p "SERVER_IP=Server LAN IP address (e.g. 192.168.1.100) [default: localhost]: "
if "!SERVER_IP!"=="" set "SERVER_IP=localhost"

set /p "JWT_SECRET=JWT secret key [press Enter for auto-generated]: "
if "!JWT_SECRET!"=="" (
    for /f "delims=" %%i in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N')"') do set "JWT_SECRET=%%i"
)

echo.
echo  Settings summary:
echo    Database  : !DB_NAME!
echo    MySQL port: !DB_PORT!   (auto-picks a free port if 3306 is busy)
echo    App port  : !APP_PORT!
echo    Server IP : !SERVER_IP!
echo.
set /p "CONFIRM=Proceed with installation? (Y/N): "
if /i "!CONFIRM!" neq "Y" (
    echo  Installation cancelled.
    pause
    exit /b 0
)

:: ── Create folders ──────────────────────────────────────────
echo.
echo  [1/8] Creating directories...
if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"
if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"
echo  [OK] Directories ready.

:: ── Check / Install Node.js ─────────────────────────────────
echo.
echo  [2/8] Checking Node.js...
where node >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=*" %%v in ('node --version') do echo  [OK] Node.js %%v already installed.
) else (
    echo  Node.js not found. Installing via winget...
    winget install --id OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements
    if %errorLevel% neq 0 (
        echo  [ERROR] Failed to install Node.js via winget.
        echo  Please install manually from https://nodejs.org and re-run this installer.
        pause
        exit /b 1
    )
    :: Refresh PATH
    call refreshenv >nul 2>&1
    echo  [OK] Node.js installed.
)

:: ── Set up MySQL from the extracted ZIP build ───────────────
echo.
echo  [3/8] Setting up MySQL (silent ZIP build)...

:: 3a. Locate / extract the MySQL ZIP build
if not exist "%MYSQL_DIR%\bin\mysqld.exe" (
    if exist "%MYSQL_ZIP%" (
        echo  Extracting %MYSQL_ZIP%...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '!MYSQL_ZIP!' -DestinationPath '!TOOLS_DIR!\tmp-mysql' -Force; Move-Item '!TOOLS_DIR!\tmp-mysql\mysql-!MYSQL_VERSION!-winx64' '!MYSQL_DIR!'"
        if errorlevel 1 (
            echo  [ERROR] Could not extract the MySQL ZIP. Check that the archive is complete.
            pause
            exit /b 1
        )
    ) else (
        echo  MySQL not found in %TOOLS_DIR%.
        echo  Downloading MySQL ZIP build (one-time, ~220 MB)...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-!MYSQL_VERSION!-winx64.zip' -OutFile '!MYSQL_ZIP!' -UseBasicParsing"
        if errorlevel 1 (
            echo.
            echo  [ERROR] Could not download MySQL automatically. Do one of:
            echo    - Download https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-!MYSQL_VERSION!-winx64.zip
            echo      and place it in: %TOOLS_DIR%
            echo    - Or extract it manually to: %MYSQL_DIR%
            echo  Then re-run this installer.
            pause
            exit /b 1
        )
        echo  Extracting downloaded MySQL...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '!MYSQL_ZIP!' -DestinationPath '!TOOLS_DIR!\tmp-mysql' -Force; Move-Item '!TOOLS_DIR!\tmp-mysql\mysql-!MYSQL_VERSION!-winx64' '!MYSQL_DIR!'"
        if errorlevel 1 (
            echo  [ERROR] Could not extract the downloaded MySQL ZIP.
            pause
            exit /b 1
        )
    )
    echo  [OK] MySQL extracted to %MYSQL_DIR%
) else (
    echo  [OK] MySQL already present at %MYSQL_DIR%
)

:: 3b. Register the MySQL service if it does not exist yet
sc query MyLikitaMySQL >nul 2>&1
if !errorlevel! equ 0 (
    echo  [OK] MySQL service MyLikitaMySQL already registered - reusing it.
) else (
    call :find_free_port
    echo  Using MySQL port !DB_PORT!.

    if exist "%MYSQL_DATA%\mysql" (
        echo  [OK] MySQL data directory already initialized - reusing data.
    ) else (
        echo  Initializing MySQL data directory (--initialize-insecure)...
        if not exist "%MYSQL_DATA%" mkdir "%MYSQL_DATA%"
        "%MYSQL_DIR%\bin\mysqld.exe" --no-defaults --initialize-insecure --basedir="%MYSQL_DIR%" --datadir="%MYSQL_DATA%" --console >> "%LOGS_DIR%\mysql-init.log" 2>&1
        if errorlevel 1 (
            echo  [ERROR] MySQL initialization failed. See %LOGS_DIR%\mysql-init.log
            pause
            exit /b 1
        )
        echo  [OK] MySQL data initialized.
    )

    echo  Writing MySQL configuration...
    (
        echo [mysqld]
        echo basedir="%MYSQL_DIR%"
        echo datadir="%MYSQL_DATA%"
        echo port=!DB_PORT!
        echo default-authentication-plugin=mysql_native_password
        echo character-set-server=utf8mb4
        echo collation-server=utf8mb4_unicode_ci
        echo max_allowed_packet=64M
        echo [client]
        echo port=!DB_PORT!
    ) > "%MYSQL_DATA%\my.ini"

    echo  Registering MySQL Windows service...
    "%MYSQL_DIR%\bin\mysqld.exe" --install MyLikitaMySQL --defaults-file="%MYSQL_DATA%\my.ini" >> "%LOGS_DIR%\mysql-init.log" 2>&1
    if errorlevel 1 (
        echo  [ERROR] Could not register MySQL service. See %LOGS_DIR%\mysql-init.log
        pause
        exit /b 1
    )
    echo  [OK] MySQL service registered.
)

:: 3c. Start MySQL and wait until it accepts connections
echo  Starting MySQL service...
net start MyLikitaMySQL >> "%LOGS_DIR%\mysql-init.log" 2>&1

echo  Waiting for MySQL to accept connections...
set /a WAIT=0
:wait_mysql
:: probe with the empty root password (fresh install) OR the existing one (reinstall)
"%MYSQL_DIR%\bin\mysql.exe" -u root --port=!DB_PORT! -e "SELECT 1" >nul 2>&1
if errorlevel 1 (
    "%MYSQL_DIR%\bin\mysql.exe" -u root -p!DB_PASS! --port=!DB_PORT! -e "SELECT 1" >nul 2>&1
)
if errorlevel 1 (
    set /a WAIT+=1
    if !WAIT! lss 60 (
        timeout /t 2 /nobreak >nul
        goto wait_mysql
    )
    echo  [ERROR] MySQL did not become ready in time. Check %LOGS_DIR%\mysql-init.log
    pause
    exit /b 1
)
echo  [OK] MySQL is running.

:: 3d. Set the root password (no-op safe if already set)
"%MYSQL_DIR%\bin\mysql.exe" -u root --port=!DB_PORT! -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '!DB_PASS!'; FLUSH PRIVILEGES;" >> "%LOGS_DIR%\mysql-init.log" 2>&1
if errorlevel 1 (
    echo  [WARNING] Could not set the root password. If this was a reinstall,
    echo  the existing password is still in use (stored in backend\.env).
)

:: ── Check embedded NSSM (no download) ───────────────────────
echo.
echo  [4/8] Checking NSSM (service manager)...
if exist "%NSSM_EXE%" (
    echo  [OK] NSSM present at %NSSM_EXE%
) else (
    echo.
    echo  [ERROR] NSSM was not found at: %NSSM_EXE%
    echo.
    echo  NSSM is deliberately NOT downloaded at install time (offline-safe).
    echo  Do one of the following, then re-run this installer:
    echo    - Copy nssm.exe (from the nssm win64/ folder) to: %NSSM_EXE%
    echo    - Or download https://nssm.cc/download and extract it there
    pause
    exit /b 1
)

:: ── Install backend npm dependencies ────────────────────────
echo.
echo  [5/8] Installing backend dependencies (npm install)...
if exist "%BACKEND_DIR%\node_modules\express" (
    echo  [OK] node_modules already present - skipping.
) else (
    cd /d "%BACKEND_DIR%"
    call npm install --omit=dev --prefer-offline
    if %errorLevel% neq 0 (
        echo  [ERROR] npm install failed. Check your Node.js installation.
        pause
        exit /b 1
    )
    echo  [OK] Backend dependencies installed.
)

:: ── Write .env file ─────────────────────────────────────────
echo.
echo  [6/8] Writing backend .env configuration...
set "ENV_FILE=%BACKEND_DIR%\.env"

(
    echo PORT=!APP_PORT!
    echo NODE_ENV=production
    echo SERVE_FRONTEND=true
    echo.
    echo DB_HOST=localhost
    echo DB_PORT=!DB_PORT!
    echo DB_USER=root
    echo DB_PASSWORD=!DB_PASS!
    echo DB_NAME=!DB_NAME!
    echo.
    echo JWT_SECRET=!JWT_SECRET!
    echo.
    echo # Email - leave blank for offline deployment
    echo MAIL_HOST=
    echo MAIL_USER=
    echo MAIL_PASS=
) > "!ENV_FILE!"

echo  [OK] .env written to %ENV_FILE%

:: ── Create / import the database ────────────────────────────
echo.
echo  [7/8] Setting up database !DB_NAME!...

:: Create the database if it doesn't exist
"%MYSQL_DIR%\bin\mysql.exe" -u root -p!DB_PASS! --port=!DB_PORT! -e "CREATE DATABASE IF NOT EXISTS !DB_NAME! CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >> "%LOGS_DIR%\mysql-init.log" 2>&1
if %errorLevel% neq 0 (
    echo  [WARNING] Could not create the database. Check the password in backend\.env
) else (
    echo  [OK] Database !DB_NAME! ready.

    for /f %%c in ('"%MYSQL_DIR%\bin\mysql.exe" -u root -p!DB_PASS! --port=!DB_PORT! -N -s -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='!DB_NAME!'"') do set "TABLE_COUNT=%%c"

    if "!TABLE_COUNT!"=="0" (
        echo  Importing initial database schema...
        if exist "%BACKEND_DIR%\prime-db.sql" (
            rem prime-db.sql is a MariaDB 10.4 dump; MySQL 8.0 needs sanitizing:
            rem  - NO_AUTO_CREATE_USER was removed in MySQL 8, error 1231;
            rem    same strip as backend/entrypoint.sh does with sed
            rem  - the dump's CREATE DATABASE prime and USE prime lines are
            rem    dropped so all data lands in !DB_NAME! (the .env database)
            powershell -NoProfile -ExecutionPolicy Bypass -Command ^
              "$c = [IO.File]::ReadAllText('%BACKEND_DIR%\prime-db.sql');" ^
              "$c = $c -replace 'NO_AUTO_CREATE_USER,', '' -replace ',NO_AUTO_CREATE_USER', '' -replace 'NO_AUTO_CREATE_USER', '';" ^
              "$c = $c -replace '(?m)^CREATE DATABASE.*?;\r?\n', '' -replace '(?m)^USE `prime`;\r?\n', '';" ^
              "[IO.File]::WriteAllText('%TEMP%\prime-db.mysql8.sql', $c, (New-Object System.Text.UTF8Encoding($false)))" >> "%LOGS_DIR%\mysql-init.log" 2>&1
            if errorlevel 1 (
                echo  [WARNING] Could not sanitize prime-db.sql for MySQL 8 - skipping import.
            ) else (
                "%MYSQL_DIR%\bin\mysql.exe" -u root -p!DB_PASS! --port=!DB_PORT! --default-character-set=utf8mb4 --force "--init-command=SET SESSION sql_mode='NO_ENGINE_SUBSTITUTION'; SET FOREIGN_KEY_CHECKS=0;" "!DB_NAME!" < "%TEMP%\prime-db.mysql8.sql" >> "%LOGS_DIR%\mysql-init.log" 2>&1
                if !errorlevel! equ 0 (
                    echo  [OK] Database imported successfully.
                ) else (
                    echo  [WARNING] Database import encountered errors. See %LOGS_DIR%\mysql-init.log
                )
            )
        ) else (
            echo  [INFO] prime-db.sql not found - skipping import.
        )
        :: Mark the baseline migration as applied (mirrors backend/entrypoint.sh)
        "%MYSQL_DIR%\bin\mysql.exe" -u root -p!DB_PASS! --port=!DB_PORT! "!DB_NAME!" -e "CREATE TABLE IF NOT EXISTS SequelizeMeta (name VARCHAR(255) NOT NULL PRIMARY KEY); INSERT IGNORE INTO SequelizeMeta VALUES ('20200101000000-initial-schema.js');" >> "%LOGS_DIR%\mysql-init.log" 2>&1
    ) else (
        echo  [OK] Database already has !TABLE_COUNT! tables - skipping import to preserve data.
    )
)

:: ── Register Windows Service with NSSM ──────────────────────
echo.
echo  [8/8] Registering MyLikita as a Windows Service...

:: Remove existing service if present
"%NSSM_EXE%" status MyLikita >nul 2>&1
if %errorLevel% equ 0 (
    echo  Existing MyLikita service found - removing...
    "%NSSM_EXE%" stop MyLikita >nul 2>&1
    timeout /t 3 /nobreak >nul
    "%NSSM_EXE%" remove MyLikita confirm >nul 2>&1
    echo  [OK] Old service removed.
)

:: Find node.exe path
for /f "tokens=*" %%p in ('where node') do set "NODE_EXE=%%p"
if "!NODE_EXE!"=="" (
    set "NODE_EXE=C:\Program Files\nodejs\node.exe"
)

:: Install the service
"%NSSM_EXE%" install MyLikita "!NODE_EXE!"
"%NSSM_EXE%" set MyLikita AppDirectory "%BACKEND_DIR%"
"%NSSM_EXE%" set MyLikita AppParameters "app.js"
"%NSSM_EXE%" set MyLikita AppEnvironmentExtra "NODE_ENV=production"
"%NSSM_EXE%" set MyLikita Start SERVICE_AUTO_START
"%NSSM_EXE%" set MyLikita AppStdout "%LOGS_DIR%\out.log"
"%NSSM_EXE%" set MyLikita AppStderr "%LOGS_DIR%\err.log"
"%NSSM_EXE%" set MyLikita AppRotateFiles 1
"%NSSM_EXE%" set MyLikita AppRotateBytes 5242880
"%NSSM_EXE%" set MyLikita DisplayName "MyLikita Hospital System"
"%NSSM_EXE%" set MyLikita Description "MyLikita hospital management system backend"

:: Open Windows Firewall port
echo  Opening firewall port !APP_PORT!...
netsh advfirewall firewall show rule name="MyLikita" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="MyLikita" dir=in action=allow protocol=TCP localport=!APP_PORT! >nul
    echo  [OK] Firewall rule added for port !APP_PORT!.
) else (
    echo  [OK] Firewall rule already exists.
)

:: Start the service
echo  Starting MyLikita service...
"%NSSM_EXE%" start MyLikita
timeout /t 5 /nobreak >nul

:: Check if it started
"%NSSM_EXE%" status MyLikita | find "SERVICE_RUNNING" >nul
if %errorLevel% equ 0 (
    echo  [OK] MyLikita service is RUNNING.
) else (
    echo  [WARNING] Service may not have started yet.
    echo  Check logs at: %LOGS_DIR%\err.log
)

:: ── Done ─────────────────────────────────────────────────────
echo.
echo  ================================================
echo   Installation Complete!
echo  ================================================
echo.
echo  Access the application at:
echo    Local machine : http://localhost:!APP_PORT!/
if "!SERVER_IP!" neq "localhost" (
    echo    Other devices : http://!SERVER_IP!:!APP_PORT!/
)
echo.
echo  Service management:
echo    nssm start MyLikita    - start
echo    nssm stop MyLikita     - stop
echo    nssm restart MyLikita  - restart
echo.
echo  Log files:
echo    %LOGS_DIR%\out.log
echo    %LOGS_DIR%\err.log
echo.
echo  The app will start automatically whenever this machine boots.
echo.

:: Ask to open the browser
set /p "OPEN_BROWSER=Open the app in your browser now? (Y/N): "
if /i "!OPEN_BROWSER!"=="Y" (
    timeout /t 3 /nobreak >nul
    start "" "http://localhost:!APP_PORT!/"
)

echo.
echo  Press any key to exit...
pause >nul
endlocal
exit /b 0

:: ============================================================
::  Helpers
:: ============================================================

:find_free_port
:: find a free TCP port if the current DB_PORT is taken by another MySQL
:: instance; starts from the persisted port (.env) or 3306 by default
:find_port_loop
netstat -ano | findstr /c:":!DB_PORT! " | findstr /i "LISTENING" >nul 2>&1
if !errorlevel! neq 0 exit /b 0
set /a DB_PORT+=1
if !DB_PORT! lss 3312 goto find_port_loop
echo  [ERROR] No free MySQL port found (3306-3311 all busy).
exit /b 1
