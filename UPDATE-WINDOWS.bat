@echo off
setlocal EnableDelayedExpansion
title MyLikita - Update
color 0B

:: ============================================================
::  MyLikita — Update Script
::  Run when deploying a new version to an already-installed
::  client machine. Preserves the existing .env and database.
:: ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Run as Administrator.
    pause
    exit /b 1
)

set "INSTALL_ROOT=%~dp0"
if "%INSTALL_ROOT:~-1%"=="\" set "INSTALL_ROOT=%INSTALL_ROOT:~0,-1%"

set "BACKEND_DIR=%INSTALL_ROOT%\backend"
set "NSSM_EXE=%INSTALL_ROOT%\tools\nssm\nssm.exe"

echo.
echo  Stopping MyLikita service...
"%NSSM_EXE%" stop MyLikita
timeout /t 4 /nobreak >nul

echo  Installing updated backend dependencies...
cd /d "%BACKEND_DIR%"
call npm install --omit=dev --prefer-offline
if %errorLevel% neq 0 (
    echo [ERROR] npm install failed.
    "%NSSM_EXE%" start MyLikita
    pause
    exit /b 1
)

echo  Starting MyLikita service...
"%NSSM_EXE%" start MyLikita
timeout /t 4 /nobreak >nul

"%NSSM_EXE%" status MyLikita | find "SERVICE_RUNNING" >nul
if %errorLevel% equ 0 (
    echo  [OK] MyLikita updated and running.
) else (
    echo  [WARNING] Service may not have started. Check logs.
)

echo.
echo  Update complete. Press any key to exit...
pause >nul
endlocal
