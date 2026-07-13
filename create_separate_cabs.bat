@echo off
setlocal

set "SIGNTOOL=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
set "THUMBPRINT=a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b"
set "TIMESTAMP=http://timestamp.digicert.com"
set "BASEDIR=D:\Datics\Virtual-Audio-Driver"

echo ========================================
echo Creating Separate x64 and ARM64 CABs
echo ========================================
echo.

:: Clean up old CABs
if exist "%BASEDIR%\VirtualAudioDriver_x64.cab" del "%BASEDIR%\VirtualAudioDriver_x64.cab"
if exist "%BASEDIR%\VirtualAudioDriver_ARM64.cab" del "%BASEDIR%\VirtualAudioDriver_ARM64.cab"

:: ========================================
:: Create x64 CAB
:: ========================================
echo Creating x64 CAB...

if exist "%BASEDIR%\CabPackage_x64" rmdir /s /q "%BASEDIR%\CabPackage_x64"
mkdir "%BASEDIR%\CabPackage_x64"
mkdir "%BASEDIR%\CabPackage_x64\VirtualAudioDriver"

:: Copy x64 files to subfolder
copy "%BASEDIR%\x64\Release\virtualaudiodriver.sys" "%BASEDIR%\CabPackage_x64\VirtualAudioDriver\"
copy "%BASEDIR%\x64\Release\virtualaudiodriver.pdb" "%BASEDIR%\CabPackage_x64\VirtualAudioDriver\"
copy "%BASEDIR%\MultiArchPackage\VirtualAudioDriver.inf" "%BASEDIR%\CabPackage_x64\VirtualAudioDriver\"
copy "%BASEDIR%\MultiArchPackage\virtualaudiodriver.cat" "%BASEDIR%\CabPackage_x64\VirtualAudioDriver\"

:: Create x64 DDF
(
echo .OPTION EXPLICIT
echo .Set CabinetNameTemplate=VirtualAudioDriver_x64.cab
echo .Set CompressionType=MSZIP
echo .Set Cabinet=on
echo .Set DiskDirectoryTemplate=.
echo .Set DestinationDir=VirtualAudioDriver
echo.
echo "%BASEDIR%\CabPackage_x64\VirtualAudioDriver\virtualaudiodriver.sys"
echo "%BASEDIR%\CabPackage_x64\VirtualAudioDriver\virtualaudiodriver.pdb"
echo "%BASEDIR%\CabPackage_x64\VirtualAudioDriver\VirtualAudioDriver.inf"
echo "%BASEDIR%\CabPackage_x64\VirtualAudioDriver\virtualaudiodriver.cat"
) > "%BASEDIR%\x64.ddf"

cd /d "%BASEDIR%"
makecab /F x64.ddf
del x64.ddf setup.inf setup.rpt 2>nul

:: Sign x64 CAB
echo Signing x64 CAB...
"%SIGNTOOL%" sign /sha1 %THUMBPRINT% /fd sha256 /tr %TIMESTAMP% /td sha256 "%BASEDIR%\VirtualAudioDriver_x64.cab"

:: ========================================
:: Create ARM64 CAB
:: ========================================
echo.
echo Creating ARM64 CAB...

if exist "%BASEDIR%\CabPackage_ARM64" rmdir /s /q "%BASEDIR%\CabPackage_ARM64"
mkdir "%BASEDIR%\CabPackage_ARM64"
mkdir "%BASEDIR%\CabPackage_ARM64\VirtualAudioDriver"

:: Copy ARM64 files to subfolder
copy "%BASEDIR%\ARM64\Release\virtualaudiodriver.sys" "%BASEDIR%\CabPackage_ARM64\VirtualAudioDriver\"
copy "%BASEDIR%\ARM64\Release\virtualaudiodriver.pdb" "%BASEDIR%\CabPackage_ARM64\VirtualAudioDriver\"
copy "%BASEDIR%\MultiArchPackage\VirtualAudioDriver.inf" "%BASEDIR%\CabPackage_ARM64\VirtualAudioDriver\"
copy "%BASEDIR%\MultiArchPackage\virtualaudiodriver.cat" "%BASEDIR%\CabPackage_ARM64\VirtualAudioDriver\"

:: Create ARM64 DDF
(
echo .OPTION EXPLICIT
echo .Set CabinetNameTemplate=VirtualAudioDriver_ARM64.cab
echo .Set CompressionType=MSZIP
echo .Set Cabinet=on
echo .Set DiskDirectoryTemplate=.
echo .Set DestinationDir=VirtualAudioDriver
echo.
echo "%BASEDIR%\CabPackage_ARM64\VirtualAudioDriver\virtualaudiodriver.sys"
echo "%BASEDIR%\CabPackage_ARM64\VirtualAudioDriver\virtualaudiodriver.pdb"
echo "%BASEDIR%\CabPackage_ARM64\VirtualAudioDriver\VirtualAudioDriver.inf"
echo "%BASEDIR%\CabPackage_ARM64\VirtualAudioDriver\virtualaudiodriver.cat"
) > "%BASEDIR%\arm64.ddf"

cd /d "%BASEDIR%"
makecab /F arm64.ddf
del arm64.ddf setup.inf setup.rpt 2>nul

:: Sign ARM64 CAB
echo Signing ARM64 CAB...
"%SIGNTOOL%" sign /sha1 %THUMBPRINT% /fd sha256 /tr %TIMESTAMP% /td sha256 "%BASEDIR%\VirtualAudioDriver_ARM64.cab"

:: ========================================
:: Verify
:: ========================================
echo.
echo ========================================
echo CAB Files Created:
echo ========================================
echo.
dir "%BASEDIR%\VirtualAudioDriver_x64.cab"
dir "%BASEDIR%\VirtualAudioDriver_ARM64.cab"

echo.
echo Structure inside CABs:
echo.
echo x64 CAB contents:
expand -D "%BASEDIR%\VirtualAudioDriver_x64.cab"
echo.
echo ARM64 CAB contents:
expand -D "%BASEDIR%\VirtualAudioDriver_ARM64.cab"

echo.
echo ========================================
echo Done! Submit these separately:
echo   1. VirtualAudioDriver_x64.cab (select x64 OS versions)
echo   2. VirtualAudioDriver_ARM64.cab (select ARM64 OS versions)
echo ========================================
pause
