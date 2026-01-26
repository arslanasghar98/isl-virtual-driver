@echo off
REM Virtual Audio Driver - Installation Launcher
REM This batch file launches the PowerShell installation script

echo ========================================
echo Virtual Audio Driver Installation
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

echo Starting installation...
echo.

REM Execute PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Install-VirtualAudioDriver.ps1"

echo.
echo Installation script completed.
pause
