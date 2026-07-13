@echo off
setlocal

set "MSBUILD=C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe"
set "SOLUTION=D:\Datics\Virtual-Audio-Driver\VirtualAudioDriver.sln"

echo ========================================
echo Rebuilding Virtual Audio Driver
echo ========================================

echo.
echo Building x64 Release...
"%MSBUILD%" "%SOLUTION%" /p:Configuration=Release /p:Platform=x64 /t:Rebuild
if errorlevel 1 (
    echo ERROR: x64 build failed!
    exit /b 1
)

echo.
echo Building ARM64 Release...
"%MSBUILD%" "%SOLUTION%" /p:Configuration=Release /p:Platform=ARM64 /t:Rebuild
if errorlevel 1 (
    echo ERROR: ARM64 build failed!
    exit /b 1
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo x64:   D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.sys
echo ARM64: D:\Datics\Virtual-Audio-Driver\ARM64\Release\virtualaudiodriver.sys
