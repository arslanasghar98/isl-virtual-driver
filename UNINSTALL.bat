@echo off
REM Virtual Audio Driver - Uninstallation Launcher
REM This batch file launches the PowerShell uninstallation script

echo ========================================
echo Virtual Audio Driver Uninstallation
echo ========================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires Administrator privileges.
    echo.
    echo Please right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo Starting uninstallation...
echo.

REM Execute PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Uninstall-VirtualAudioDriver.ps1"

echo.
echo Uninstallation script completed.
pause
