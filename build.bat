@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Virtual Audio Driver Build Script
echo ========================================
echo.

:: ------------------------------------------------------------
:: Set Windows SDK version to match WDK version
:: ------------------------------------------------------------
set TARGET_SDK=10.0.26100.0

:: Check if MSBuild is available in PATH first
where msbuild >nul 2>&1
if %errorlevel% equ 0 (
    echo Found MSBuild in PATH
    goto msbuild_found
)

:: MSBuild not in PATH, search common locations
echo MSBuild not found in PATH, searching common locations...

set MSBUILD_PATHS[0]=C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe
set MSBUILD_PATHS[1]=C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe
set MSBUILD_PATHS[2]=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe
set MSBUILD_PATHS[3]=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe
set MSBUILD_PATHS[4]=C:\Program Files\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe
set MSBUILD_PATHS[5]=C:\Program Files\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe
set MSBUILD_PATHS[6]=C:\Program Files\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe
set MSBUILD_PATHS[7]=C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe
set MSBUILD_PATHS[8]=C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe

set MSBUILD_EXE=
for /L %%i in (0,1,8) do (
    call set CURRENT_PATH=%%MSBUILD_PATHS[%%i]%%
    if exist "!CURRENT_PATH!" (
        set "MSBUILD_EXE=!CURRENT_PATH!"
        echo Found MSBuild
        goto msbuild_found
    )
)

echo ERROR: MSBuild not found
pause >nul
exit /b 1

:msbuild_found
if defined MSBUILD_EXE (
    echo Using MSBuild from specific location
    set "MSBUILD_CMD=%MSBUILD_EXE%"
) else (
    echo Using MSBuild from PATH
    set "MSBUILD_CMD=msbuild"
)

:: Default values
set CONFIG=Release
set PLATFORM=x64
set BUILD_ALL=0

:: Parse command line arguments
:parse_args
if "%1"=="" goto build_start
if /i "%1"=="debug" set CONFIG=Debug
if /i "%1"=="release" set CONFIG=Release
if /i "%1"=="x64" set PLATFORM=x64
if /i "%1"=="arm64" set PLATFORM=ARM64
if /i "%1"=="all" set BUILD_ALL=1
if /i "%1"=="help" goto show_help
shift
goto parse_args

:show_help
echo Usage: build.bat [debug|release] [x64|arm64|all]
pause >nul
exit /b 0

:build_start
if %BUILD_ALL%==1 goto build_all

echo Building Virtual Audio Driver...
echo Configuration: %CONFIG%
echo Platform: %PLATFORM%
echo Windows SDK: %TARGET_SDK%
echo.

if /i "%PLATFORM%"=="ARM64" (
    echo Building ARM64 with validation disabled...
    "%MSBUILD_CMD%" "VirtualAudioDriver.sln" ^
        /p:Configuration=%CONFIG% ^
        /p:Platform=ARM64 ^
        /p:TargetPlatformVersion=%TARGET_SDK% ^
        /p:VisualStudioVersion=17.0 ^
        /p:RunCodeAnalysis=false ^
        /p:DriverTargetPlatform=Universal ^
        /p:UseInfVerifierEx=false ^
        /p:ValidateDrivers=false ^
        /p:StampInf=false ^
        /p:ApiValidator_Enable=false ^
        /p:InfVerif_Enable=false ^
        /p:DisableVerification=true ^
        /p:SignMode=Off ^
        /p:ApiValidator_ExcludedTargets=ARM64 ^
        /p:EnableInf2cat=false
) else (
    echo Building x64 with full validation...
    "%MSBUILD_CMD%" "VirtualAudioDriver.sln" ^
        /p:Configuration=%CONFIG% ^
        /p:Platform=%PLATFORM% ^
        /p:TargetPlatformVersion=%TARGET_SDK% ^
        /p:VisualStudioVersion=17.0
)

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed with exit code %errorlevel%
    pause >nul
    exit /b %errorlevel%
)

echo.
echo Build completed successfully!
goto show_output

:build_all
echo Building all configurations...
echo Windows SDK: %TARGET_SDK%

set CONFIGS=Debug Release
set PLATFORMS=x64 ARM64

for %%c in (%CONFIGS%) do (
    for %%p in (%PLATFORMS%) do (
        echo.
        echo ========================================
        echo Building %%c %%p
        echo ========================================

        if /i "%%p"=="ARM64" (
            "%MSBUILD_CMD%" "VirtualAudioDriver.sln" ^
                /p:Configuration=%%c ^
                /p:Platform=ARM64 ^
                /p:TargetPlatformVersion=%TARGET_SDK% ^
                /p:VisualStudioVersion=17.0 ^
                /p:RunCodeAnalysis=false ^
                /p:DriverTargetPlatform=Universal ^
                /p:UseInfVerifierEx=false ^
                /p:ValidateDrivers=false ^
                /p:StampInf=false ^
                /p:ApiValidator_Enable=false ^
                /p:InfVerif_Enable=false ^
                /p:DisableVerification=true ^
                /p:SignMode=Off ^
                /p:ApiValidator_ExcludedTargets=ARM64 ^
                /p:EnableInf2cat=false
        ) else (
            "%MSBUILD_CMD%" "VirtualAudioDriver.sln" ^
                /p:Configuration=%%c ^
                /p:Platform=%%p ^
                /p:TargetPlatformVersion=%TARGET_SDK% ^
                /p:VisualStudioVersion=17.0
        )

        if !errorlevel! neq 0 (
            echo ERROR: Build failed for %%c %%p
            pause >nul
            exit /b !errorlevel!
        )
    )
)

echo ========================================
echo All builds completed successfully!
echo ========================================

:show_output
echo.
echo Output directory:
if %BUILD_ALL%==1 (
    echo   x64\Debug\package\
    echo   x64\Release\package\
    echo   ARM64\Debug\package\
    echo   ARM64\Release\package\
) else (
    echo   %PLATFORM%\%CONFIG%\package\
)

pause >nul
exit /b 0
