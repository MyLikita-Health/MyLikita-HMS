@echo off
setlocal EnableExtensions EnableDelayedExpansion
title MyLikita - Configuration
color 0A

:: ============================================================================
::  MyLikita post-install configuration (run hidden by the Inno Setup installer)
::  - Sets up MySQL from the embedded ZIP build (silent, offline)
::  - Imports prime-db.sql into a fresh database (skips if data exists)
::  - Writes backend\.env with auto-generated credentials
::  - Bakes the server LAN IP into the frontend bundle
::  - Registers the backend as an auto-start Windows service via NSSM
::  - Opens the firewall port and starts everything
::  - Logs every step to {app}\logs\install.log
::  Exit code 0 = success, 1 = failure (log explains why).
:: ============================================================================

set "APP_ROOT=%~dp0.."
set "BACKEND_DIR=%APP_ROOT%\backend"
set "FRONTEND_DIST=%APP_ROOT%\frontend\dist"
set "NODE_DIR=%APP_ROOT%\runtime\node"
set "MYSQL_DIR=%APP_ROOT%\runtime\mysql"
set "MYSQL_DATA=%APP_ROOT%\mysql-data"
set "NSSM=%APP_ROOT%\runtime\nssm\nssm.exe"
set "LOGS_DIR=%APP_ROOT%\logs"
set "MYSQL_DIR_FWD=%MYSQL_DIR:\=/%"
set "MYSQL_DATA_FWD=%MYSQL_DATA:\=/%"
set "LOGS_DIR_FWD=%LOGS_DIR:\=/%"
set "SQL_FILE=%APP_ROOT%\database\prime-db.sql"
set "DB_NAME=mylikita_db"
set "APP_PORT=46990"
set "DB_PORT=3306"
set "SERVER_IP=localhost"

if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"
set "INSTALL_LOG=%LOGS_DIR%\install.log"

call :log "============================================================"
call :log "MyLikita post-install started: %date% %time%"
call :log "App root: %APP_ROOT%"
call :log "============================================================"

:: ---------------------------------------------------------------- sanity --
call :verify "%BACKEND_DIR%\app.js"            "backend\app.js"
call :verify "%NODE_DIR%\node.exe"             "runtime\node\node.exe"
call :verify "%MYSQL_DIR%\bin\mysqld.exe"      "runtime\mysql\bin\mysqld.exe"
call :verify "%NSSM%"                          "runtime\nssm\nssm.exe"
call :verify "%FRONTEND_DIST%\index.html"      "frontend\dist\index.html"
call :verify "%SQL_FILE%"                      "database\prime-db.sql"

:: -------------------------------------------- reuse .env if already present --
set "DB_PASS="
set "DB_PORT=3306"
if exist "%BACKEND_DIR%\.env" (
    for /f "tokens=1,* delims==" %%a in ('findstr /b "DB_PASSWORD=" "%BACKEND_DIR%\.env"') do set "DB_PASS=%%b"
    for /f "tokens=1,* delims==" %%a in ('findstr /b "DB_PORT=" "%BACKEND_DIR%\.env"') do set "DB_PORT=%%b"
)

if "!DB_PASS!"=="" (
    for /f "delims=" %%i in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N')"') do set "DB_PASS=%%i"
)
for /f "delims=" %%i in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N')"') do set "JWT_SECRET=%%i"

:: --------------------------------------------------- detect LAN IP (if free) --
:: prefer the NIC that has a default gateway (the real LAN adapter); fall
:: back to the first non-link-local IPv4 address
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress" 2^>nul') do set "SERVER_IP=%%i"
if "!SERVER_IP!"=="" (
    for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1).IPAddress" 2^>nul') do set "SERVER_IP=%%i"
)
if "!SERVER_IP!"=="" set "SERVER_IP=localhost"
call :log "Server LAN IP detected as: !SERVER_IP!"

:: ============================================================ MYSQL =========
call :log "------------------------------------------------------------"
call :log "MySQL setup (port !DB_PORT!)..."

sc query MyLikitaMySQL >nul 2>&1
if !errorlevel! equ 0 (
    call :log "MySQL service MyLikitaMySQL already registered - reusing it."
) else (
    call :find_free_port
    call :log "Using MySQL port !DB_PORT!."

    if exist "%MYSQL_DATA%\mysql" (
        call :log "MySQL data directory already initialized - reusing data."
    ) else (
        call :log "Initializing MySQL data directory (--initialize-insecure)..."
        if not exist "%MYSQL_DATA%" mkdir "%MYSQL_DATA%"
        "%MYSQL_DIR%\bin\mysqld.exe" --no-defaults --initialize-insecure --basedir="%MYSQL_DIR%" --datadir="%MYSQL_DATA%" --console >> "%INSTALL_LOG%" 2>&1
        if errorlevel 1 (
            call :log "[ERROR] MySQL data directory initialization failed. See log above."
            exit /b 1
        )
        call :log "MySQL initialized."
    )

rem always rewrite my.ini with the chosen port so the service and the
rem connections below agree, even when reusing an existing data directory
    call :log "Writing MySQL configuration (port !DB_PORT!)..."
    rem MySQL option files treat backslash as an escape char, so runtime
    rem paths would break mysqld. Use forward slashes - the standard
    rem Windows my.ini form - and log errors to the diagnostics file.
    (
        echo [mysqld]
        echo basedir=!MYSQL_DIR_FWD!
        echo datadir=!MYSQL_DATA_FWD!
        echo log-error=!LOGS_DIR_FWD!/mysql-error.log
        echo port=!DB_PORT!
        echo character-set-server=utf8mb4
        echo collation-server=utf8mb4_unicode_ci
        echo max_allowed_packet=64M
        echo [client]
        echo port=!DB_PORT!
    ) > "%MYSQL_DATA%\my.ini"

    call :log "Registering MySQL Windows service..."
    "%MYSQL_DIR%\bin\mysqld.exe" --install MyLikitaMySQL --defaults-file="%MYSQL_DATA%\my.ini" >> "%INSTALL_LOG%" 2>&1
    if errorlevel 1 (
        call :log "[ERROR] Could not register MySQL service. See log above."
        exit /b 1
    )
)

call :log "Starting MySQL service..."
net start MyLikitaMySQL >> "%INSTALL_LOG%" 2>&1

call :log "Waiting for MySQL to accept connections..."
set /a WAIT=0
:wait_mysql
:: probe with the empty root password (fresh install) OR the existing one
:: (reinstall - the .env password is loaded at the top of this script)
"%MYSQL_DIR%\bin\mysql.exe" -u root --port=!DB_PORT! -e "SELECT 1" >nul 2>&1
if errorlevel 1 (
    "%MYSQL_DIR%\bin\mysql.exe" -u root -p!DB_PASS! --port=!DB_PORT! -e "SELECT 1" >nul 2>&1
)
if errorlevel 1 (
    set /a WAIT+=1
    if !WAIT! lss 60 (
        call :sleep 2
        goto wait_mysql
    )
    call :log "[ERROR] MySQL did not become ready in time."
    exit /b 1
)
call :log "MySQL is up."

:: --------------------------------------------------- set password + db ------
call :log "Setting root password and creating database !DB_NAME!..."
:: on a reinstall root already has a password (from .env) - the empty-password
:: attempt fails with access denied and we retry with the known password, so
:: the ALTER USER is idempotent and CREATE DATABASE IF NOT EXISTS is a no-op
"%MYSQL_DIR%\bin\mysql.exe" -u root --port=!DB_PORT! -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '!DB_PASS!'; CREATE DATABASE IF NOT EXISTS !DB_NAME! CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; FLUSH PRIVILEGES;" >> "%INSTALL_LOG%" 2>&1
if errorlevel 1 (
    call :log "Root already has a password (reinstall) - retrying with the .env password."
    "%MYSQL_DIR%\bin\mysql.exe" -u root -p!DB_PASS! --port=!DB_PORT! -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '!DB_PASS!'; CREATE DATABASE IF NOT EXISTS !DB_NAME! CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; FLUSH PRIVILEGES;" >> "%INSTALL_LOG%" 2>&1
)
if errorlevel 1 (
    call :log "[ERROR] Could not set MySQL root password / create database. See log above."
    exit /b 1
)

:: ------------------------------------------- import baseline schema ---------
for /f %%c in ('"%MYSQL_DIR%\bin\mysql.exe" -u root -p!DB_PASS! --port=!DB_PORT! -N -s -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='!DB_NAME!'"') do set "TABLE_COUNT=%%c"

if "!TABLE_COUNT!"=="0" (
    call :log "Database is empty - importing baseline schema (prime-db.sql)..."
    rem prime-db.sql is a MariaDB 10.4 dump; MySQL 8.0 needs it sanitized:
    rem  - NO_AUTO_CREATE_USER was removed in MySQL 8, error 1231 if left in
    rem    SET sql_mode statements - mirrors the sed in backend/entrypoint.sh
    rem  - the dump's own CREATE DATABASE prime and USE prime lines would
    rem    land all data in the wrong schema; drop them and import below
    rem    targets !DB_NAME! explicitly
    rem single line on purpose: caret continuations inside a block mangle
    rem cmd's quote pairing [the build script hit the same trap]
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$c = [IO.File]::ReadAllText('%SQL_FILE%'); $c = $c -replace 'NO_AUTO_CREATE_USER,', '' -replace ',NO_AUTO_CREATE_USER', '' -replace 'NO_AUTO_CREATE_USER', ''; $c = $c -replace '(?m)^CREATE DATABASE.*?;\r?\n', '' -replace '(?m)^USE `prime`;\r?\n', ''; [IO.File]::WriteAllText('%APP_ROOT%\database\prime-db.mysql8.sql', $c, (New-Object System.Text.UTF8Encoding($false)))" >> "%INSTALL_LOG%" 2>&1
    if errorlevel 1 (
        call :log "[ERROR] Could not sanitize prime-db.sql for MySQL 8."
        exit /b 1
    )
    call :log "Importing with MySQL 8 compatible settings (--force, relaxed sql_mode)..."
    "%MYSQL_DIR%\bin\mysql.exe" -u root -p!DB_PASS! --port=!DB_PORT! --default-character-set=utf8mb4 --force "--init-command=SET SESSION sql_mode='NO_ENGINE_SUBSTITUTION'; SET FOREIGN_KEY_CHECKS=0;" "!DB_NAME!" < "%APP_ROOT%\database\prime-db.mysql8.sql" >> "%INSTALL_LOG%" 2>&1
    if errorlevel 1 (
        call :log "[ERROR] Database import failed. See log above."
        exit /b 1
    )
rem mark the baseline migration as applied [mirrors entrypoint.sh]
    "%MYSQL_DIR%\bin\mysql.exe" -u root -p!DB_PASS! --port=!DB_PORT! "!DB_NAME!" -e "CREATE TABLE IF NOT EXISTS SequelizeMeta (name VARCHAR(255) NOT NULL PRIMARY KEY); INSERT IGNORE INTO SequelizeMeta VALUES ('20200101000000-initial-schema.js');" >> "%INSTALL_LOG%" 2>&1
    call :log "Baseline schema imported."
) else (
    call :log "Database already has !TABLE_COUNT! tables - skipping import to preserve data."
)

:: ============================================== FRONTEND IP BAKE-IN ==========
call :log "Baking server LAN IP (!SERVER_IP!) into frontend bundle..."
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ip='!SERVER_IP!'; Get-ChildItem -Path '!FRONTEND_DIST!' -Recurse -Filter *.js -ErrorAction SilentlyContinue | ForEach-Object { $c = Get-Content $_.FullName -Raw; if ($c.Contains('__MYLIKITA_SERVER_IP__')) { $c = $c.Replace('__MYLIKITA_SERVER_IP__', $ip); [System.IO.File]::WriteAllText($_.FullName, $c, (New-Object System.Text.UTF8Encoding($false))); Write-Output ('patched ' + $_.Name) } }" >> "%INSTALL_LOG%" 2>&1

:: ============================================== BACKEND DEPS (fallback) ======
if exist "%BACKEND_DIR%\node_modules\express" (
    call :log "node_modules present - skipping npm install."
) else (
    call :log "node_modules not found - running npm install (requires internet)..."
    pushd "%BACKEND_DIR%"
    call "%NODE_DIR%\npm.cmd" install --omit=dev --no-audit --no-fund >> "%INSTALL_LOG%" 2>&1
    if errorlevel 1 (
        call :log "[ERROR] npm install failed. See log above."
        exit /b 1
    )
    popd
    call :log "npm install complete."
)

:: ================================================== BACKEND .env ============
call :log "Writing backend\.env..."
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
    echo MAIL_HOST=
    echo MAIL_USER=
    echo MAIL_PASS=
    echo.
    rem ---- SMS via Termii [https://termii.com] - leave empty to disable ----
    echo TERMII_API_KEY=
    echo TERMII_SENDER_ID=MyLikita
    rem ---- WhatsApp via Termii - set TERMII_WHATSAPP_ID to enable WhatsApp reminders ----
    echo TERMII_WHATSAPP_ID=
    echo.
    rem ---- Email via Resend [https://resend.com] - leave empty to disable ----
    echo RESEND_API_KEY=
    echo EMAIL_FROM=MyLikita ^<hello@mylikita.clinic^>
    echo.
    echo PUPPETEER_SKIP_DOWNLOAD=true
) > "%BACKEND_DIR%\.env"
call :log ".env written."

:: ============================================== DB MIGRATIONS ==========
:: prime-db.sql is a snapshot of the FULL current schema, but the installer
:: previously only marked the baseline migration as applied and never ran the
:: pending migration chain. That left offline installs missing post-baseline
:: columns (e.g. hospitals.app_url, the onboarding fields). Mirror what
:: backend/entrypoint.sh does on the cloud: run the pending migrations now
:: that .env (DB_*) is in place so offline schema matches cloud schema.
call :log "Running pending database migrations..."
pushd "%BACKEND_DIR%"
set "NODE_ENV=development"
call "%NODE_DIR%\npx.cmd" --no-install sequelize db:migrate >> "%INSTALL_LOG%" 2>&1
if errorlevel 1 (
    call :log "[ERROR] Database migrations failed. See log above."
    exit /b 1
)
popd
call :log "Database migrations complete."

:: Mark the seeded facility (Amisal Dental Care, the default login used by
rem offline installs] as needing onboarding, and flag the deployment as
rem offline. The post-login redirect then sends the first admin to the
rem /onboarding/claim wizard, which finalizes the facility profile and
rem replaces the shared default admin credentials [admin/123456].
"%MYSQL_DIR%\bin\mysql.exe" -u root -p!DB_PASS! --port=!DB_PORT! "!DB_NAME!" -e "UPDATE hospitals SET deployment_type='offline', onboarding_status='pending', onboarding_step=0 WHERE id='1be0a9da-bff9-4ab6-a36c-edfd8ca88f1a' AND (onboarding_status IS NULL OR onboarding_status='' OR deployment_type IS NULL);" >> "%INSTALL_LOG%" 2>&1
if errorlevel 1 (
    call :log "[WARN] Could not mark seeded facility for onboarding (id may differ on this install)."
) else (
    call :log "Seeded facility marked for first-run onboarding (offline)."
)

rem ============================================== NSSM WINDOWS SERVICE ========
call :log "Registering MyLikita Windows service..."
"%NSSM%" status MyLikita >nul 2>&1
if !errorlevel! equ 0 (
    call :log "Removing previous MyLikita service..."
    "%NSSM%" stop MyLikita >nul 2>&1
    call :sleep 3
    "%NSSM%" remove MyLikita confirm >nul 2>&1
)

"%NSSM%" install MyLikita "%NODE_DIR%\node.exe"
"%NSSM%" set MyLikita AppDirectory "%BACKEND_DIR%"
"%NSSM%" set MyLikita AppParameters "app.js"
"%NSSM%" set MyLikita AppEnvironmentExtra "NODE_ENV=production"
"%NSSM%" set MyLikita Start SERVICE_AUTO_START
"%NSSM%" set MyLikita AppStdout "%LOGS_DIR%\out.log"
"%NSSM%" set MyLikita AppStderr "%LOGS_DIR%\err.log"
"%NSSM%" set MyLikita AppRotateFiles 1
"%NSSM%" set MyLikita AppRotateBytes 5242880
"%NSSM%" set MyLikita DisplayName "MyLikita Hospital System"
"%NSSM%" set MyLikita Description "MyLikita hospital management system backend"
if errorlevel 1 (
    call :log "[ERROR] Could not register MyLikita service."
    exit /b 1
)

rem =================================================== FIREWALL ===============
call :log "Opening firewall port !APP_PORT!..."
netsh advfirewall firewall delete rule name="MyLikita" >nul 2>&1
netsh advfirewall firewall add rule name="MyLikita" dir=in action=allow protocol=TCP localport=!APP_PORT! >nul
call :log "Firewall rule added."

rem ===================================================== START + CHECK ========
call :log "Starting MyLikita service..."
"%NSSM%" start MyLikita >> "%INSTALL_LOG%" 2>&1
call :sleep 10

call :log "Verifying the app responds..."
set "HEALTH=not-checked"
set /a ATTEMPT=0
:health_loop
set /a ATTEMPT+=1
for /f "delims=" %%r in ('powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:!APP_PORT!/' -UseBasicParsing -TimeoutSec 10; 'HTTP ' + [int]$r.StatusCode } catch { 'ERROR' }"') do set "HEALTH=%%r"
call :log "Health check attempt !ATTEMPT! of 6: !HEALTH!"
echo !HEALTH! | findstr /i "HTTP" >nul
if errorlevel 1 (
    if !ATTEMPT! lss 6 (
        call :sleep 5
        goto health_loop
    )
)
call :log "Final health check: !HEALTH!"

rem ===================================================== CREDENTIALS =========
(
    echo MyLikita is installed and running.
    echo.
    echo Access from this machine : http://localhost:!APP_PORT!/
    echo Access from the network   : http://!SERVER_IP!:!APP_PORT!/
    echo.
    echo Database   : !DB_NAME!  ^(MySQL port !DB_PORT!^)
    echo MySQL root password and JWT secret are stored in:
    echo   %BACKEND_DIR%\.env
    echo.
    echo Logs: %LOGS_DIR%\out.log  /  err.log
    echo Need help? Send %INSTALL_LOG% to MyLikita support.
) > "%APP_ROOT%\CREDENTIALS.txt"

call :log "============================================================"
call :log "MyLikita post-install COMPLETED: %date% %time%"
call :log "URL: http://!SERVER_IP!:!APP_PORT!/"
call :log "============================================================"
exit /b 0

rem ============================================================ helpers ======
:log
echo [%time%] %* >> "%INSTALL_LOG%"
echo %*
exit /b 0

:sleep
rem The built-in `timeout` command fails with "Input redirection is not
rem supported" when stdin is not attached to a console - which is exactly how
rem the installer's hidden `cmd /c postinstall.cmd` runs [and how CI runs it].
rem Use PowerShell Start-Sleep instead so delays always work headless.
powershell -NoProfile -Command "Start-Sleep -Seconds %~1" >nul 2>&1
exit /b 0

:verify
if not exist "%~1" (
    call :log "[ERROR] Required file not found: %~2"
    call :log "        Expected at: %~1"
    exit /b 1
)
exit /b 0

:find_free_port
rem find a free TCP port if the current DB_PORT is taken by another MySQL
rem instance; starts from the persisted port [.env] or 3306 by default
:find_port_loop
netstat -ano | findstr /c:":!DB_PORT! " | findstr /i "LISTENING" >nul 2>&1
if !errorlevel! neq 0 exit /b 0
set /a DB_PORT+=1
if !DB_PORT! lss 3312 goto find_port_loop
call :log "[ERROR] No free MySQL port found (3306-3311 all busy)."
exit /b 1
