@echo off
setlocal EnableExtensions EnableDelayedExpansion
title MyLikita - Uninstall

set "APP_ROOT=%~dp0.."
set "NSSM=%APP_ROOT%\runtime\nssm\nssm.exe"

echo Stopping MyLikita services...
"%NSSM%" stop MyLikitaPrintAgent >nul 2>&1
"%NSSM%" stop MyLikita >nul 2>&1
timeout /t 3 /nobreak >nul

echo Removing MyLikita services...
"%NSSM%" remove MyLikitaPrintAgent confirm >nul 2>&1
"%NSSM%" remove MyLikita confirm >nul 2>&1

echo.
echo The MyLikita service was removed.
echo.
echo NOTE: MySQL data was NOT deleted. The MyLikitaMySQL service and the
echo database at "%APP_ROOT%\mysql-data" are kept so a reinstall keeps all
echo patient data. To remove them too, run as Administrator:
echo   net stop MyLikitaMySQL ^&^& sc delete MyLikitaMySQL
echo   rmdir /s /q "%APP_ROOT%\mysql-data"
echo.
exit /b 0
