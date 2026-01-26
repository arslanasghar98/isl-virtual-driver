@echo off
setlocal enabledelayedexpansion
echo ========================================
echo ISL Audio Driver Build with WDK
echo ========================================
echo.

echo.
echo Setting WDK paths...

REM Set WDK installation path
set "WDKContentRoot=C:\Program Files (x86)\Windows Kits\10\"

REM Verify WDK installation
if not exist "!WDKContentRoot!build" (
    echo ERROR: WDK not found at expected location
    echo Please install Windows Driver Kit ^(WDK^) from Microsoft
    pause
    exit /b 1
)

echo Found WDK

REM Set SDK version (use the version installed on your system)
REM Common versions: 10.0.22621.0, 10.0.26100.0
set "WindowsSDKVersion=10.0.26100.0\"

REM Set additional WDK environment variables
set "WindowsDriverKitDir=%WDKContentRoot%"
set "WindowsDriverKitBinDir=%WDKContentRoot%bin"
set "WindowsDriverKitIncludeDir=%WDKContentRoot%Include\%WindowsSDKVersion%"
set "WindowsDriverKitLibDir=%WDKContentRoot%Lib\%WindowsSDKVersion%"

echo WDK Content Root: !WDKContentRoot!
echo SDK Version: !WindowsSDKVersion!
echo Include Dir: !WindowsDriverKitIncludeDir!
echo Lib Dir: !WindowsDriverKitLibDir!

echo.
echo Building ISL Audio Driver...
echo.

REM Navigate to script directory
cd /d "%~dp0"

REM Build using MSBuild directly
if "%1"=="" (
    set CONFIG=Release
    set PLATFORM=x64
) else (
    set CONFIG=%1
    set PLATFORM=%2
)

if "%PLATFORM%"=="" set PLATFORM=x64

echo Configuration: !CONFIG!
echo Platform: !PLATFORM!
echo.

REM Verify WDK build targets exist
set "WDKBuildPath=!WDKContentRoot!build\!WindowsSDKVersion!"
if exist "!WDKBuildPath!WindowsDriver.Default.props" (
    echo Found WDK build targets
) else (
    echo WARNING: WDK build targets not found
    pause
    exit /b 1
)

echo.
echo Starting build...
echo.

msbuild "VirtualAudioDriver.sln" /p:Configuration=%CONFIG% /p:Platform=%PLATFORM% /v:minimal /m

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Build completed successfully!
    echo ========================================
    echo.
    echo Output: !PLATFORM!\!CONFIG!\package\
    echo   - VirtualAudioDriver.sys
    echo   - VirtualAudioDriver.inf
    echo   - virtualaudiodriver.cat
) else (
    echo.
    echo ========================================
    echo Build failed!
    echo ========================================
)

echo.
pause
