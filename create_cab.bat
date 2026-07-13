@echo off
setlocal

set "SIGNTOOL=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
set "INF2CAT=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\inf2cat.exe"
set "THUMBPRINT=a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b"
set "TIMESTAMP=http://timestamp.digicert.com"
set "BASEDIR=D:\Datics\Virtual-Audio-Driver"

echo ========================================
echo Creating Multi-Arch Driver Package
echo ========================================
echo.

:: Create staging directory
echo Creating staging directory...
if exist "%BASEDIR%\MultiArchPackage" rmdir /s /q "%BASEDIR%\MultiArchPackage"
mkdir "%BASEDIR%\MultiArchPackage"
mkdir "%BASEDIR%\MultiArchPackage\x64"
mkdir "%BASEDIR%\MultiArchPackage\ARM64"

:: Copy x64 files
echo Copying x64 files...
copy "%BASEDIR%\x64\Release\virtualaudiodriver.sys" "%BASEDIR%\MultiArchPackage\x64\"
copy "%BASEDIR%\x64\Release\virtualaudiodriver.pdb" "%BASEDIR%\MultiArchPackage\x64\"
copy "%BASEDIR%\x64\Release\package\VirtualAudioDriver.inf" "%BASEDIR%\MultiArchPackage\x64\" 2>nul
if not exist "%BASEDIR%\MultiArchPackage\x64\VirtualAudioDriver.inf" (
    copy "%BASEDIR%\DriverPackage\VirtualAudioDriver.inf" "%BASEDIR%\MultiArchPackage\x64\"
)

:: Copy ARM64 files
echo Copying ARM64 files...
copy "%BASEDIR%\ARM64\Release\virtualaudiodriver.sys" "%BASEDIR%\MultiArchPackage\ARM64\"
copy "%BASEDIR%\ARM64\Release\virtualaudiodriver.pdb" "%BASEDIR%\MultiArchPackage\ARM64\"
copy "%BASEDIR%\ARM64\Release\package\VirtualAudioDriver.inf" "%BASEDIR%\MultiArchPackage\ARM64\" 2>nul
if not exist "%BASEDIR%\MultiArchPackage\ARM64\VirtualAudioDriver.inf" (
    copy "%BASEDIR%\DriverPackage\VirtualAudioDriver.inf" "%BASEDIR%\MultiArchPackage\ARM64\"
)

:: Copy icon
echo Copying icon...
copy "%BASEDIR%\DriverPackage\CallJoyna.ico" "%BASEDIR%\MultiArchPackage\" 2>nul

:: Generate catalog for x64 (with ARM64 OS target)
echo.
echo Generating catalog...
"%INF2CAT%" /driver:"%BASEDIR%\MultiArchPackage\x64" /os:10_X64,10_ARM64 /uselocaltime
if %errorlevel% neq 0 (
    echo Warning: inf2cat returned error, trying alternate approach...
    "%INF2CAT%" /driver:"%BASEDIR%\MultiArchPackage\x64" /os:10_X64 /uselocaltime
)

:: Sign catalog
echo.
echo Signing catalog...
"%SIGNTOOL%" sign /sha1 %THUMBPRINT% /fd sha256 /tr %TIMESTAMP% /td sha256 "%BASEDIR%\MultiArchPackage\x64\VirtualAudioDriver.cat"
if %errorlevel% neq 0 echo ERROR: Catalog signing failed

:: Create CAB
echo.
echo Creating CAB file...
cd /d "%BASEDIR%"

:: Create DDF file
echo .OPTION EXPLICIT > multiarch.ddf
echo .Set CabinetNameTemplate=VirtualAudioDriver_MultiArch.cab >> multiarch.ddf
echo .Set CompressionType=MSZIP >> multiarch.ddf
echo .Set Cabinet=on >> multiarch.ddf
echo .Set DiskDirectoryTemplate=. >> multiarch.ddf
echo .Set DestinationDir=VirtualAudioDriver >> multiarch.ddf
echo. >> multiarch.ddf
echo "%BASEDIR%\MultiArchPackage\x64\virtualaudiodriver.sys" "x64\virtualaudiodriver.sys" >> multiarch.ddf
echo "%BASEDIR%\MultiArchPackage\x64\virtualaudiodriver.pdb" "x64\virtualaudiodriver.pdb" >> multiarch.ddf
echo "%BASEDIR%\MultiArchPackage\x64\VirtualAudioDriver.inf" "x64\VirtualAudioDriver.inf" >> multiarch.ddf
echo "%BASEDIR%\MultiArchPackage\ARM64\virtualaudiodriver.sys" "ARM64\virtualaudiodriver.sys" >> multiarch.ddf
echo "%BASEDIR%\MultiArchPackage\ARM64\virtualaudiodriver.pdb" "ARM64\virtualaudiodriver.pdb" >> multiarch.ddf
echo "%BASEDIR%\MultiArchPackage\ARM64\VirtualAudioDriver.inf" "ARM64\VirtualAudioDriver.inf" >> multiarch.ddf
echo "%BASEDIR%\MultiArchPackage\x64\VirtualAudioDriver.cat" "VirtualAudioDriver.cat" >> multiarch.ddf

makecab /F multiarch.ddf

:: Cleanup
del multiarch.ddf 2>nul
del setup.inf 2>nul
del setup.rpt 2>nul

echo.
echo ========================================
echo Package Complete!
echo ========================================
echo.
echo CAB file: %BASEDIR%\VirtualAudioDriver_MultiArch.cab
echo.
dir "%BASEDIR%\VirtualAudioDriver_MultiArch.cab"
echo.
pause
