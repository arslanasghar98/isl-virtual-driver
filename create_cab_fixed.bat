@echo off
setlocal

set "SIGNTOOL=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
set "INF2CAT=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\inf2cat.exe"
set "STAMPINF=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\stampinf.exe"
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

:: Copy x64 files (all in same folder for inf2cat)
echo Copying x64 files...
copy "%BASEDIR%\x64\Release\virtualaudiodriver.sys" "%BASEDIR%\MultiArchPackage\"
copy "%BASEDIR%\x64\Release\virtualaudiodriver.pdb" "%BASEDIR%\MultiArchPackage\"
copy "%BASEDIR%\DriverPackage\CallJoyna.ico" "%BASEDIR%\MultiArchPackage\"

:: Create a simple INF without icon reference for catalog generation
echo Creating INF for catalog...
(
echo [Version]
echo Signature   = "$Windows NT$"
echo Class       = MEDIA
echo Provider    = %%ProviderName%%
echo ClassGUID   = {4d36e96c-e325-11ce-bfc1-08002be10318}
echo DriverVer   = 07/09/2026,2.0.0.1
echo CatalogFile = VirtualAudioDriver.cat
echo PnpLockDown = 1
echo.
echo [SourceDisksNames]
echo 222="VIRTUALAUDIODRIVER Driver Disk","",222
echo.
echo [SourceDisksFiles]
echo virtualaudiodriver.sys=222
echo.
echo [Manufacturer]
echo %%MfgName%%=VIRTUALAUDIODRIVER,NTamd64.10.0...22000,NTARM64.10.0...22000
echo.
echo [VIRTUALAUDIODRIVER.NTamd64.10.0...22000]
echo %%VIRTUALAUDIODRIVER_SA.DeviceDesc%%=VIRTUALAUDIODRIVER_SA, ROOT\VirtualAudioDriver
echo.
echo [VIRTUALAUDIODRIVER.NTARM64.10.0...22000]
echo %%VIRTUALAUDIODRIVER_SA.DeviceDesc%%=VIRTUALAUDIODRIVER_SA, ROOT\VirtualAudioDriver
echo.
echo [DestinationDirs]
echo VIRTUALAUDIODRIVER_SA.CopyList=12
echo.
echo [VIRTUALAUDIODRIVER_SA.CopyList]
echo virtualaudiodriver.sys
echo.
echo [VIRTUALAUDIODRIVER_SA.AddReg]
echo HKR,,AssociatedFilters,,"wdmaud,swmidi,redbook"
echo HKR,,Driver,,virtualaudiodriver.sys
echo HKR,Drivers,SubClasses,,"wave,midi,mixer"
echo HKR,Drivers\wave\wdmaud.drv,Driver,,wdmaud.drv
echo HKR,Drivers\midi\wdmaud.drv,Driver,,wdmaud.drv
echo HKR,Drivers\mixer\wdmaud.drv,Driver,,wdmaud.drv
echo HKR,Drivers\wave\wdmaud.drv,Description,,"CallJoyna Audio"
echo HKR,Drivers\mixer\wdmaud.drv,Description,,"CallJoyna Audio"
echo.
echo [VIRTUALAUDIODRIVER_SA.NT]
echo Include=ks.inf,wdmaudio.inf
echo Needs=KS.Registration, WDMAUDIO.Registration
echo CopyFiles=VIRTUALAUDIODRIVER_SA.CopyList
echo AddReg=VIRTUALAUDIODRIVER_SA.AddReg
echo.
echo [VIRTUALAUDIODRIVER_SA.NT.Services]
echo AddService=VirtualAudioDriver,0x00000002,VirtualAudioDriver_Service_Inst
echo.
echo [VirtualAudioDriver_Service_Inst]
echo DisplayName=%%VirtualAudioDriver.SvcDesc%%
echo ServiceType=1
echo StartType=3
echo ErrorControl=1
echo ServiceBinary=%%12%%\virtualaudiodriver.sys
echo.
echo [VIRTUALAUDIODRIVER_SA.NT.HW]
echo AddReg = AUDIOHW.AddReg
echo.
echo [AUDIOHW.AddReg]
echo HKR,,DeviceType,0x10001,0x0000001D
echo HKR,,Security,,"D:P(A;;GA;;;SY)(A;;GRGWGX;;;BA)(A;;GRGWGX;;;WD)(A;;GRGWGX;;;RC)"
echo.
echo [VIRTUALAUDIODRIVER_SA.NT.Wdf]
echo KmdfService = VirtualAudioDriver, VIRTUALAUDIODRIVER_SA_WdfSect
echo.
echo [VIRTUALAUDIODRIVER_SA_WdfSect]
echo KmdfLibraryVersion = 1.33
echo.
echo [Strings]
echo ProviderName = "CallJoyna"
echo MfgName       = "CallJoyna"
echo VIRTUALAUDIODRIVER_SA.DeviceDesc="CallJoyna Audio"
echo VirtualAudioDriver.SvcDesc="CallJoyna Audio Service"
) > "%BASEDIR%\MultiArchPackage\VirtualAudioDriver.inf"

:: Generate catalog
echo.
echo Generating catalog...
"%INF2CAT%" /driver:"%BASEDIR%\MultiArchPackage" /os:10_NI_X64,10_NI_ARM64 /uselocaltime

if not exist "%BASEDIR%\MultiArchPackage\VirtualAudioDriver.cat" (
    echo ERROR: Catalog was not created!
    pause
    exit /b 1
)

:: Sign catalog
echo.
echo Signing catalog...
"%SIGNTOOL%" sign /sha1 %THUMBPRINT% /fd sha256 /tr %TIMESTAMP% /td sha256 "%BASEDIR%\MultiArchPackage\VirtualAudioDriver.cat"

:: Verify catalog
echo.
echo Verifying catalog...
"%SIGNTOOL%" verify /pa "%BASEDIR%\MultiArchPackage\VirtualAudioDriver.cat"

:: Now create separate x64 and ARM64 folders for CAB
echo.
echo Preparing CAB structure...
mkdir "%BASEDIR%\MultiArchPackage\x64"
mkdir "%BASEDIR%\MultiArchPackage\ARM64"

:: x64 files
copy "%BASEDIR%\x64\Release\virtualaudiodriver.sys" "%BASEDIR%\MultiArchPackage\x64\"
copy "%BASEDIR%\x64\Release\virtualaudiodriver.pdb" "%BASEDIR%\MultiArchPackage\x64\"
copy "%BASEDIR%\MultiArchPackage\VirtualAudioDriver.inf" "%BASEDIR%\MultiArchPackage\x64\"

:: ARM64 files
copy "%BASEDIR%\ARM64\Release\virtualaudiodriver.sys" "%BASEDIR%\MultiArchPackage\ARM64\"
copy "%BASEDIR%\ARM64\Release\virtualaudiodriver.pdb" "%BASEDIR%\MultiArchPackage\ARM64\"
copy "%BASEDIR%\MultiArchPackage\VirtualAudioDriver.inf" "%BASEDIR%\MultiArchPackage\ARM64\"

:: Create CAB
echo.
echo Creating CAB file...
cd /d "%BASEDIR%"

:: Delete old CAB if exists
if exist VirtualAudioDriver_MultiArch.cab del VirtualAudioDriver_MultiArch.cab

:: Create DDF file
(
echo .OPTION EXPLICIT
echo .Set CabinetNameTemplate=VirtualAudioDriver_MultiArch.cab
echo .Set CompressionType=MSZIP
echo .Set Cabinet=on
echo .Set DiskDirectoryTemplate=.
echo .Set DestinationDir=VirtualAudioDriver
echo.
echo "%BASEDIR%\MultiArchPackage\x64\virtualaudiodriver.sys" "x64\virtualaudiodriver.sys"
echo "%BASEDIR%\MultiArchPackage\x64\virtualaudiodriver.pdb" "x64\virtualaudiodriver.pdb"
echo "%BASEDIR%\MultiArchPackage\x64\VirtualAudioDriver.inf" "x64\VirtualAudioDriver.inf"
echo "%BASEDIR%\MultiArchPackage\ARM64\virtualaudiodriver.sys" "ARM64\virtualaudiodriver.sys"
echo "%BASEDIR%\MultiArchPackage\ARM64\virtualaudiodriver.pdb" "ARM64\virtualaudiodriver.pdb"
echo "%BASEDIR%\MultiArchPackage\ARM64\VirtualAudioDriver.inf" "ARM64\VirtualAudioDriver.inf"
echo "%BASEDIR%\MultiArchPackage\VirtualAudioDriver.cat" "VirtualAudioDriver.cat"
) > multiarch.ddf

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
if exist "%BASEDIR%\VirtualAudioDriver_MultiArch.cab" (
    echo SUCCESS: CAB file created!
    echo.
    echo CAB file: %BASEDIR%\VirtualAudioDriver_MultiArch.cab
    echo.
    dir "%BASEDIR%\VirtualAudioDriver_MultiArch.cab"
) else (
    echo ERROR: CAB file was not created!
)
echo.
pause
