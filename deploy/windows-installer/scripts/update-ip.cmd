@echo off
setlocal EnableExtensions EnableDelayedExpansion
title MyLikita - Update Server IP
color 0E

:: Re-bakes the server LAN IP into the frontend bundle and restarts the
:: service. Useful when the server's IP address changes after install.
:: Run as Administrator.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Run this script as Administrator.
    pause
    exit /b 1
)

set "APP_ROOT=%~dp0.."
set "FRONTEND_DIST=%APP_ROOT%\frontend\dist"
set "NSSM=%APP_ROOT%\runtime\nssm\nssm.exe"

set "SERVER_IP="
set /p "SERVER_IP=Enter the new server IP (blank to auto-detect): "
if "!SERVER_IP!"=="" (
    for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress" 2^>nul') do set "SERVER_IP=%%i"
)
if "!SERVER_IP!"=="" (
    for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1).IPAddress" 2^>nul') do set "SERVER_IP=%%i"
)
if "!SERVER_IP!"=="" (
    echo [ERROR] Could not determine the server IP.
    pause
    exit /b 1
)

echo Patching frontend bundle with IP: !SERVER_IP!
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ip='!SERVER_IP!'; Get-ChildItem -Path '!FRONTEND_DIST!' -Recurse -Filter *.js -ErrorAction SilentlyContinue | ForEach-Object { $c = Get-Content $_.FullName -Raw; if ($c.Contains('__MYLIKITA_SERVER_IP__')) { $c = $c.Replace('__MYLIKITA_SERVER_IP__', $ip); [System.IO.File]::WriteAllText($_.FullName, $c, (New-Object System.Text.UTF8Encoding($false))) } }"

echo Restarting MyLikita service...
"%NSSM%" restart MyLikita
timeout /t 5 /nobreak >nul

echo.
echo [OK] Done. Staff can now access: http://!SERVER_IP!:46990/
echo.
pause
