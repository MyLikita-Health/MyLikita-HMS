@echo off
setlocal EnableExtensions EnableDelayedExpansion
title MyLikita - Reconfigure
color 0A

:: Re-runs the full post-install configuration. Safe to run multiple times:
:: MySQL data, the database and .env credentials are preserved/reused.
:: Run as Administrator.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Run this script as Administrator.
    pause
    exit /b 1
)

cd /d "%~dp0"
call "%~dp0postinstall.cmd" install
echo.
if %errorLevel% equ 0 (
    echo [OK] MyLikita reconfigured successfully.
) else (
    echo [FAILED] See "%cd%..\logs\install.log" for details.
)
echo.
pause
