@echo off
REM Virtual Audio Driver - Self-Signed Installation (All-in-One)
REM This script runs all three steps to create certificate, sign driver, and install

echo ========================================
echo Virtual Audio Driver
echo Self-Signed Installation (All Steps)
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

echo This will perform the following steps:
echo   1. Create a self-signed certificate
echo   2. Sign the driver files
echo   3. Install the signed driver
echo.
echo No Test Mode required!
echo.
pause

echo.
echo ========================================
echo Step 1/3: Creating Certificate
echo ========================================
powershell.exe -ExecutionPolicy Bypass -File "%~dp01-Create-Certificate.ps1"
if %errorLevel% neq 0 (
    echo.
    echo ERROR: Certificate creation failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo Step 2/3: Signing Driver
echo ========================================
powershell.exe -ExecutionPolicy Bypass -File "%~dp02-Sign-Driver.ps1"
if %errorLevel% neq 0 (
    echo.
    echo ERROR: Driver signing failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo Step 3/3: Installing Driver
echo ========================================
powershell.exe -ExecutionPolicy Bypass -File "%~dp03-Install-Signed-Driver.ps1"

echo.
echo ========================================
echo All steps completed!
echo ========================================
pause
