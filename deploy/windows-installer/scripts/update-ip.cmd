@echo off
setlocal EnableExtensions EnableDelayedExpansion
title MyLikita - Server IP (no re-bake needed)
color 0E

:: UPDATE: as of the dynamic-base change the frontend derives its API base
:: from window.location (the browser loads the app FROM this server), so an IP
:: change needs NO re-bake and NO bundle patch. Staff simply open the new URL:
::   http://<new-server-ip>:46990/
:: This script is kept for legacy clients only - it detects the LAN IP and
:: prints the URL, and no longer patches anything.

set "SERVER_IP="
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress" 2^>nul') do set "SERVER_IP=%%i"
if "!SERVER_IP!"=="" (
    for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1).IPAddress" 2^>nul') do set "SERVER_IP=%%i"
)
if "!SERVER_IP!"=="" set "SERVER_IP=localhost"

echo.
echo  MyLikita now derives its API base from the browser's own address -
echo  the bundle is NOT baked with an IP, so nothing needs re-patching when
echo  the server's IP changes.
echo.
echo  Staff access URL : http://!SERVER_IP!:46990/
echo.
echo  If the URL above is stale (server IP changed), no action is needed -
echo  just open the app at the new URL. Only restart the MyLikita service
echo  if the backend itself failed to start.
echo.
pause
