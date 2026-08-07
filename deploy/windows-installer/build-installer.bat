@echo off
setlocal EnableExtensions EnableDelayedExpansion
title MyLikita - Build Installer
color 0A

:: ============================================================================
::  Builds the self-contained MyLikita Windows installer.
::  MUST run on a 64-bit WINDOWS machine with Inno Setup 6 installed.
::  Produces: deploy\windows-installer\dist\output\MyLikita-Setup-<ver>.exe
::
::  What it does:
::   1. Downloads Node.js, MySQL (ZIP build) and NSSM into dist\cache
::   2. Builds the React frontend (with a server-IP placeholder)
::   3. Copies the backend and installs its dependencies (prebuilt node_modules)
::   4. Copies the Inno Setup script + helper scripts + prime-db.sql
::   5. Compiles the single-file installer with ISCC.exe
:: ============================================================================

set "HERE=%~dp0"
set "ROOT=%HERE%..\.."
set "DIST=%HERE%dist"
set "CACHE=%DIST%\cache"
set "RUNTIME=%DIST%\runtime"

:: ---------------------------------------------------------- configuration --
set "VERSION=1.0.0"
if defined MYLIKITA_VERSION set "VERSION=%MYLIKITA_VERSION%"
:: Node 20.19+ is required by the frontend's Vite 7 build (engines: ^20.19.0 || >=22.12.0)
set "NODE_VERSION=v20.19.0"
set "MYSQL_VERSION=8.0.42"
set "NSSM_VERSION=2.24"

:: Download-only mode (used by the nightly CI cache pre-warm workflow): fetch
:: the runtimes into %CACHE% and exit. No Inno Setup, frontend build, or
:: bundle is needed - the download cache is shared with the release build via
:: an identical GitHub Actions cache key.
set "DOWNLOAD_ONLY=0"
if /i "%MYLIKITA_DOWNLOAD_ONLY%"=="1" set "DOWNLOAD_ONLY=1"

set "NODE_URL=https://nodejs.org/dist/%NODE_VERSION%/node-%NODE_VERSION%-win-x64.zip"
:: dev.mysql.com/get is a flaky load balancer that intermittently serves an
:: Oracle "Technical Difficulties" page - use the canonical archives URL.
set "MYSQL_URL=https://cdn.mysql.com/archives/mysql-8.0/mysql-%MYSQL_VERSION%-winx64.zip"
set "NSSM_URL=https://nssm.cc/release/nssm-%NSSM_VERSION%.zip"

echo ============================================================
echo  MyLikita Installer Build  v%VERSION%
echo ============================================================
echo  Project root : %ROOT%
echo  Build dir    : %DIST%
echo  Node         : %NODE_VERSION%
echo  MySQL        : %MYSQL_VERSION%
echo  NSSM         : %NSSM_VERSION%
echo.

if not exist "%DIST%" mkdir "%DIST%"
if not exist "%CACHE%" mkdir "%CACHE%"
if not exist "%RUNTIME%" mkdir "%RUNTIME%"

:: ----------------------------------------------------- locate Inno Setup ---
:: Resolve ISCC.exe OUTSIDE any block. %ProgramFiles(x86)% carries parens in
:: its VALUE, and inside a parenthesized block even quoted parens break cmd's
:: block scanner ('not was unexpected at this time.'). On a plain line quoted
:: parens are harmless, so resolve the path here, then guard the rest below.
set "PF86=%ProgramFiles(x86)%"
set "PF=%ProgramFiles%"
set "ISCC="
if exist "%PF86%\Inno Setup 6\ISCC.exe" set "ISCC=%PF86%\Inno Setup 6\ISCC.exe"
if not defined ISCC if exist "%PF%\Inno Setup 6\ISCC.exe" set "ISCC=%PF%\Inno Setup 6\ISCC.exe"
if not "%DOWNLOAD_ONLY%"=="1" (
    where ISCC >nul 2>&1
    if not errorlevel 1 set "ISCC=ISCC"
    if not defined ISCC (
        echo [ERROR] Inno Setup 6 ISCC.exe not found.
        echo         Install it from https://jrsoftware.org/isinfo.php and re-run.
        exit /b 1
    )
    rem !ISCC! so the echoed value is the one actually found after where.
    echo  [OK] Inno Setup compiler: !ISCC!
)
echo.

:: ------------------------------------------------------------- downloader --
:: NOTE: no caret line-continuations and no parens in text inside these
:: blocks - cmd's block scanner mishandles both (broken quote pairing on
:: continued lines, and parens in values break the scan).
set "DL=0"
if not exist "%CACHE%\node-%NODE_VERSION%-win-x64.zip" set "DL=1"
if not exist "%CACHE%\mysql-%MYSQL_VERSION%-winx64.zip" set "DL=1"
if not exist "%CACHE%\nssm-%NSSM_VERSION%.zip" set "DL=1"

if "%DL%"=="1" (
    echo  Downloading runtimes into %CACHE%  one-time ~350 MB total...
    set "DLFAIL=0"
    if not exist "%CACHE%\node-%NODE_VERSION%-win-x64.zip" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%NODE_URL%' -OutFile '%CACHE%\node-%NODE_VERSION%-win-x64.zip' -UseBasicParsing"
        if errorlevel 1 set "DLFAIL=1"
    )
    if not exist "%CACHE%\mysql-%MYSQL_VERSION%-winx64.zip" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%MYSQL_URL%' -OutFile '%CACHE%\mysql-%MYSQL_VERSION%-winx64.zip' -UseBasicParsing"
        if errorlevel 1 set "DLFAIL=1"
    )
    if not exist "%CACHE%\nssm-%NSSM_VERSION%.zip" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%NSSM_URL%' -OutFile '%CACHE%\nssm-%NSSM_VERSION%.zip' -UseBasicParsing"
        if errorlevel 1 set "DLFAIL=1"
    )
    rem !DLFAIL! (delayed): %-expansion happens once at block entry, before
    rem the set above runs - only delayed expansion sees the updated value.
    if "!DLFAIL!"=="1" (
        echo  [ERROR] Download failed. Check internet access / URLs above.
        exit /b 1
    )
)

:: ------------------------------------------------------ download-only mode --
:: Cache pre-warm (CI) stops here - the runtimes are in %CACHE% and the cache
:: save happens automatically at the end of the actions/cache job.
if "%DOWNLOAD_ONLY%"=="1" (
    echo.
    echo  [OK] Download-only mode: runtimes cached in %CACHE%
    echo       node, mysql, nssm - exiting before extract/build.
    exit /b 0
)

:: ------------------------------------------------------ extract runtimes ----
echo  Extracting runtimes...
if not exist "%RUNTIME%\node\node.exe" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%CACHE%\node-%NODE_VERSION%-win-x64.zip' -DestinationPath '%RUNTIME%\tmp-node' -Force; Move-Item '%RUNTIME%\tmp-node\node-%NODE_VERSION%-win-x64' '%RUNTIME%\node'"
    if errorlevel 1 (
        echo  [ERROR] Could not extract Node.js.
        exit /b 1
    )
)
if not exist "%RUNTIME%\mysql\bin\mysqld.exe" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%CACHE%\mysql-%MYSQL_VERSION%-winx64.zip' -DestinationPath '%RUNTIME%\tmp-mysql' -Force; Move-Item '%RUNTIME%\tmp-mysql\mysql-%MYSQL_VERSION%-winx64' '%RUNTIME%\mysql'"
    if errorlevel 1 (
        echo  [ERROR] Could not extract MySQL.
        exit /b 1
    )
)
if not exist "%RUNTIME%\nssm\nssm.exe" (
    if not exist "%RUNTIME%\nssm" mkdir "%RUNTIME%\nssm"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%CACHE%\nssm-%NSSM_VERSION%.zip' -DestinationPath '%RUNTIME%\tmp-nssm' -Force; Copy-Item '%RUNTIME%\tmp-nssm\nssm-%NSSM_VERSION%\win64\nssm.exe' -Destination '%RUNTIME%\nssm\nssm.exe'"
    if errorlevel 1 (
        echo  [ERROR] Could not extract NSSM.
        exit /b 1
    )
)
echo  [OK] Runtimes ready.

:: use the embedded Node for all npm operations so native modules match the
:: Node version that ships in the installer
set "PATH=%RUNTIME%\node;%PATH%"

:: --------------------------------------------------- build the frontend ----
echo.
echo  Building the React frontend (with server-IP placeholder)...
pushd "%ROOT%\frontend"
set "SAVED_ENV_PROD="
if exist ".env.production" (
    set "SAVED_ENV_PROD=1"
    copy /y ".env.production" "%CACHE%\env.production.saved" >nul
)
(
    echo VITE_API_URL=http://__MYLIKITA_SERVER_IP__:46990
) > ".env.production"

rem ckeditor4-react peers react ^18 but the app pins react ^16 - the lockfile
rem resolved with lax peer rules, so a clean npm 7+ install needs legacy peers.
call npm install --no-audit --no-fund --legacy-peer-deps
if errorlevel 1 (
    echo  [ERROR] Frontend npm install failed.
    if defined SAVED_ENV_PROD copy /y "%CACHE%\env.production.saved" ".env.production" >nul
    popd
    exit /b 1
)
rem The app is large (react-virtualized, ckeditor, ...): Vite minification
rem blows past Node's 2GB default heap on Windows runners.
set "NODE_OPTIONS=--max-old-space-size=4096"
call npm run build
if errorlevel 1 (
    echo  [ERROR] Frontend build failed.
    if defined SAVED_ENV_PROD copy /y "%CACHE%\env.production.saved" ".env.production" >nul
    popd
    exit /b 1
)
if defined SAVED_ENV_PROD copy /y "%CACHE%\env.production.saved" ".env.production" >nul
popd

rem ------------------------------------------- validate the built bundles ---
rem The v0.1.0 release shipped a bundle with an invalid regex that V8 rejects
rem at parse time ("Range out of order in character class") - the whole app
rem crashed on load with a blank page. esbuild's minifier doesn't catch it;
rem this guard parses every emitted .js with acorn and fails the build if any
rem bundle is unparseable, so it can never ship again.
echo.
echo  Validating frontend bundles parse (acorn syntax guard)...
"%RUNTIME%\node\node.exe" "%HERE%scripts\check-bundles.js" "%ROOT%\frontend\dist" "%ROOT%\frontend\node_modules"
if errorlevel 1 (
    echo  [ERROR] Frontend bundle syntax validation FAILED.
    echo          A bundle would crash the app on load - see messages above.
    exit /b 1
)
echo  [OK] All frontend bundles parse cleanly.

if not exist "%DIST%\frontend\dist" mkdir "%DIST%\frontend\dist"
xcopy /e /i /y /q "%ROOT%\frontend\dist\*" "%DIST%\frontend\dist\" >nul
echo  [OK] Frontend build copied.

rem ----------------------------------------- bundle the booking widget ----
rem Embed the @mylikita/booking-widget dist under frontend\dist\widget so the
rem offline app serves it at /widget/* (the backend statically serves the
rem whole frontend/dist tree). A clinic website can then embed the booking
rem form straight from its own install - no npm registry or CDN needed.
rem The widget dist is committed to the repo (v0.1.1), so this is a plain
rem copy; if it is ever missing the build MUST fail loudly.
if not exist "%DIST%\frontend\dist\widget" mkdir "%DIST%\frontend\dist\widget"
xcopy /e /i /y /q "%ROOT%\packages\booking-widget\dist\*" "%DIST%\frontend\dist\widget\" >nul
if not exist "%DIST%\frontend\dist\widget\mylikita-booking-widget.min.js" (
    echo  [ERROR] booking-widget bundle missing - expected:
    echo          %DIST%\frontend\dist\widget\mylikita-booking-widget.min.js
    exit /b 1
)
echo  [OK] Booking widget bundled (frontend\dist\widget).

:: ----------------------------------------------- bundle the backend --------
echo.
echo  Bundling backend code...
if not exist "%DIST%\backend" mkdir "%DIST%\backend"
robocopy "%ROOT%\backend" "%DIST%\backend" /E /XD node_modules uploads log .git /XF *.log .env .env.* /NFL /NDL /NJH /NJS /NP
if %errorlevel% geq 8 (
    echo  [ERROR] robocopy failed to copy the backend.
    exit /b 1
)

:: prebuilt node_modules - install with the SAME embedded Node version so the
:: native binaries (bcrypt etc.) match what ships in the installer.
echo.
echo  Installing backend dependencies (prebuilt node_modules) with embedded Node %NODE_VERSION%...
set "PUPPETEER_SKIP_DOWNLOAD=1"
pushd "%DIST%\backend"
call "%RUNTIME%\node\npm.cmd" install --omit=dev --no-audit --no-fund
if errorlevel 1 (
    echo  [ERROR] Backend npm install failed.
    popd
    exit /b 1
)
popd
echo  [OK] Backend + node_modules bundled.

:: ----------------------------------------------------- database + scripts ---
if not exist "%DIST%\database" mkdir "%DIST%\database"
copy /y "%ROOT%\backend\prime-db.sql" "%DIST%\database\prime-db.sql" >nul

rem ------------------------------------------------------ installer icon ----
rem The Inno script's SetupIconFile + shortcut icons come from the app favicon
rem (committed at frontend\public\icons\favicon.ico and copied to dist by Vite).
rem If it is ever missing the build MUST fail loudly - the .iss references
rem SetupIconFile=mylikita.ico unconditionally, so a silent "fallback" would
rem just produce a confusing ISCC compile error later.
if not exist "%DIST%\frontend\dist\icons\favicon.ico" (
    echo  [ERROR] frontend favicon.ico not found - the installer needs it for
    echo          SetupIconFile and the desktop/Start Menu shortcut icons.
    echo          Expected at: %DIST%\frontend\dist\icons\favicon.ico
    exit /b 1
)
copy /y "%DIST%\frontend\dist\icons\favicon.ico" "%DIST%\mylikita.ico" >nul
echo  [OK] Installer icon: mylikita.ico

if not exist "%DIST%\scripts" mkdir "%DIST%\scripts"
copy /y "%HERE%scripts\*.cmd" "%DIST%\scripts\" >nul
copy /y "%HERE%scripts\check-bundles.js" "%DIST%\scripts\" >nul
copy /y "%HERE%scripts\launch-app.vbs" "%DIST%\scripts\" >nul 2>nul

copy /y "%HERE%MyLikita-Setup.iss" "%DIST%\MyLikita-Setup.iss" >nul

:: ------------------------------------------------------------ compile -------
echo.
echo  Compiling installer (this takes a few minutes)...
pushd "%DIST%"
"%ISCC%" "/dMyAppVersion=%VERSION%" "MyLikita-Setup.iss"
if errorlevel 1 (
    popd
    echo  [ERROR] Inno Setup compilation failed.
    exit /b 1
)
popd

::: --------------------------------------------------- bundle manifest ----
::: Write a machine-readable manifest of what went into the installer. The
::: CI smoke test reads this instead of trying to extract the .exe with a
::: third-party unpacker (7-Zip and innounp both break on recent Inno Setup
::: releases). Every entry is a Test-Path on the ACTUAL assembled bundle.
echo.
echo  Writing bundle manifest...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m=@{}; $f=@{ 'backend\app.js'='%DIST%\backend\app.js'; 'backend\express'='%DIST%\backend\node_modules\express\package.json'; 'frontend\index.html'='%DIST%\frontend\dist\index.html'; 'runtime\node.exe'='%DIST%\runtime\node\node.exe'; 'runtime\mysqld.exe'='%DIST%\runtime\mysql\bin\mysqld.exe'; 'runtime\nssm.exe'='%DIST%\runtime\nssm\nssm.exe'; 'database\prime-db.sql'='%DIST%\database\prime-db.sql'; 'scripts\postinstall.cmd'='%DIST%\scripts\postinstall.cmd'; 'widget\mylikita-booking-widget.min.js'='%DIST%\frontend\dist\widget\mylikita-booking-widget.min.js' }; foreach ($k in $f.Keys) { $m[$k]=[bool](Test-Path $f[$k]) }; $ph=Get-ChildItem '%DIST%\frontend\dist' -Recurse -Filter *.js -ErrorAction SilentlyContinue | Select-String -Pattern '__MYLIKITA_SERVER_IP__' -List -SimpleMatch | Select-Object -First 1; $m['placeholder_present']=[bool]$ph; $wg=Get-Content '%DIST%\frontend\dist\widget\mylikita-booking-widget.min.js' -Raw -ErrorAction SilentlyContinue; $m['widget_global_present']=[bool]($wg -match 'MyLikitaBookingWidget'); $wh=Get-FileHash '%DIST%\frontend\dist\widget\mylikita-booking-widget.min.js' -Algorithm SHA256 -ErrorAction SilentlyContinue; $m['widget_sha256']=if($wh){$wh.Hash}else{$null}; $exe=Get-Item '%DIST%\output\MyLikita-Setup-%VERSION%.exe' -ErrorAction SilentlyContinue; $m['installer_mb']=[math]::Round($exe.Length/1MB); $m['version']='%VERSION%'; $m | ConvertTo-Json | Set-Content '%DIST%\bundle-manifest.json' -Encoding UTF8"
if errorlevel 1 (
    echo  [ERROR] Could not write the bundle manifest.
    exit /b 1
)
echo  [OK] bundle-manifest.json written.

echo.
echo  ============================================================
echo   BUILD COMPLETE
echo   Installer : %DIST%\output\MyLikita-Setup-%VERSION%.exe
echo   Bundle    : %DIST%\  (backend, frontend, runtimes, scripts)
echo  ============================================================
echo.
echo   Next steps:
echo   1. Test on a CLEAN Windows VM: copy the .exe, double-click, run.
echo   2. Verify http://localhost:46990/ opens the login page.
echo   3. Ship ONLY the .exe to the client - it is fully self-contained.
echo.
if not defined CI pause
endlocal
