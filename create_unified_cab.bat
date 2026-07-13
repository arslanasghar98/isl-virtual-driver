@echo off
setlocal

set "SIGNTOOL=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
set "INF2CAT=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\inf2cat.exe"
set "THUMBPRINT=a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b"
set "TIMESTAMP=http://timestamp.digicert.com"
set "BASEDIR=D:\Datics\Virtual-Audio-Driver"

echo ========================================
echo Creating Unified Multi-Arch CAB
echo ========================================
echo.

:: Clean up
if exist "%BASEDIR%\UnifiedPackage" rmdir /s /q "%BASEDIR%\UnifiedPackage"
if exist "%BASEDIR%\VirtualAudioDriver_Unified.cab" del "%BASEDIR%\VirtualAudioDriver_Unified.cab"

:: Create directory structure
echo Creating directory structure...
mkdir "%BASEDIR%\UnifiedPackage"
mkdir "%BASEDIR%\UnifiedPackage\VirtualAudioDriver"
mkdir "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\amd64"
mkdir "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\arm64"

:: Copy architecture-specific binaries
echo Copying binaries...
copy "%BASEDIR%\x64\Release\virtualaudiodriver.sys" "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\amd64\"
copy "%BASEDIR%\ARM64\Release\virtualaudiodriver.sys" "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\arm64\"

:: Copy PDB files
copy "%BASEDIR%\x64\Release\virtualaudiodriver.pdb" "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\amd64\"
copy "%BASEDIR%\ARM64\Release\virtualaudiodriver.pdb" "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\arm64\"

:: Copy icon to root folder (same icon for all architectures)
copy "%BASEDIR%\x64\Release\CallJoyna.ico" "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\"

:: Create unified INF with architecture subfolders and FULL interface sections
echo Creating unified INF...
(
echo [Version]
echo Signature   = "$Windows NT$"
echo Class       = MEDIA
echo Provider    = %%ProviderName%%
echo ClassGUID   = {4d36e96c-e325-11ce-bfc1-08002be10318}
echo DriverVer   = 07/10/2026,2.0.15.0
echo CatalogFile = VirtualAudioDriver.cat
echo PnpLockDown = 1
echo.
echo [SourceDisksNames]
echo 2 = %%DiskName%%
echo.
echo [SourceDisksNames.amd64]
echo 1 = %%DiskName%%,,,amd64
echo.
echo [SourceDisksNames.arm64]
echo 1 = %%DiskName%%,,,arm64
echo.
echo [SourceDisksFiles]
echo CallJoyna.ico = 2
echo.
echo [SourceDisksFiles.amd64]
echo virtualaudiodriver.sys = 1
echo.
echo [SourceDisksFiles.arm64]
echo virtualaudiodriver.sys = 1
echo.
echo [Manufacturer]
echo %%MfgName%% = VIRTUALAUDIODRIVER,NTamd64.10.0...22000,NTARM64.10.0...22000
echo.
echo [VIRTUALAUDIODRIVER.NTamd64.10.0...22000]
echo %%VIRTUALAUDIODRIVER_SA.DeviceDesc%% = VIRTUALAUDIODRIVER_SA, ROOT\VirtualAudioDriver
echo.
echo [VIRTUALAUDIODRIVER.NTARM64.10.0...22000]
echo %%VIRTUALAUDIODRIVER_SA.DeviceDesc%% = VIRTUALAUDIODRIVER_SA, ROOT\VirtualAudioDriver
echo.
echo [DestinationDirs]
echo DefaultDestDir = 12
echo VIRTUALAUDIODRIVER_SA.CopyList = 12
echo VIRTUALAUDIODRIVER_SA.IconCopyList = 13
echo.
echo [VIRTUALAUDIODRIVER_SA.CopyList]
echo virtualaudiodriver.sys
echo.
echo [VIRTUALAUDIODRIVER_SA.IconCopyList]
echo CallJoyna.ico
echo.
echo ;======================================================
echo ; Capture interfaces: microphone
echo ;======================================================
echo [VIRTUALAUDIODRIVER.I.WaveMicArray1]
echo AddReg=VIRTUALAUDIODRIVER.I.WaveMicArray1.AddReg
echo.
echo [VIRTUALAUDIODRIVER.I.WaveMicArray1.AddReg]
echo HKR,,CLSID,,%%Proxy.CLSID%%
echo HKR,,FriendlyName,,%%VIRTUALAUDIODRIVER.WaveMicArray1.szPname%%
echo.
echo [VIRTUALAUDIODRIVER.I.TopologyMicArray1]
echo AddReg=VIRTUALAUDIODRIVER.I.TopologyMicArray1.AddReg
echo.
echo [VIRTUALAUDIODRIVER.I.TopologyMicArray1.AddReg]
echo HKR,,CLSID,,%%Proxy.CLSID%%
echo HKR,,FriendlyName,,%%VIRTUALAUDIODRIVER.TopologyMicArray1.szPname%%
echo HKR,EP\0,%%PKEY_AudioEndpoint_Association%%,,%%KSNODETYPE_ANY%%
echo HKR,EP\0,%%PKEY_AudioEndpoint_Supports_EventDriven_Mode%%,0x00010001,0x1
echo.
echo ;======================================================
echo ; Render interfaces: speaker
echo ;======================================================
echo [VIRTUALAUDIODRIVER.I.WaveSpeaker]
echo AddReg=VIRTUALAUDIODRIVER.I.WaveSpeaker.AddReg
echo.
echo [VIRTUALAUDIODRIVER.I.WaveSpeaker.AddReg]
echo HKR,,CLSID,,%%Proxy.CLSID%%
echo HKR,,FriendlyName,,%%VIRTUALAUDIODRIVER.WaveSpeaker.szPname%%
echo.
echo [VIRTUALAUDIODRIVER.I.TopologySpeaker]
echo AddReg=VIRTUALAUDIODRIVER.I.TopologySpeaker.AddReg
echo.
echo [VIRTUALAUDIODRIVER.I.TopologySpeaker.AddReg]
echo HKR,,CLSID,,%%Proxy.CLSID%%
echo HKR,,FriendlyName,,%%VIRTUALAUDIODRIVER.TopologySpeaker.szPname%%
echo HKR,EP\0,%%PKEY_AudioEndpoint_Association%%,,%%KSNODETYPE_ANY%%
echo HKR,EP\0,%%PKEY_AudioEndpoint_Supports_EventDriven_Mode%%,0x00010001,0x1
echo.
echo ;======================================================
echo ; VIRTUALAUDIODRIVER_SA
echo ;======================================================
echo [VIRTUALAUDIODRIVER_SA]
echo CopyFiles = VIRTUALAUDIODRIVER_SA.CopyList
echo AddReg = VIRTUALAUDIODRIVER_SA.AddReg
echo.
echo [VIRTUALAUDIODRIVER_SA.AddReg]
echo HKR,,AssociatedFilters,,"wdmaud,swmidi,redbook"
echo HKR,,Driver,,virtualaudiodriver.sys
echo HKR,Drivers,SubClasses,,"wave,midi,mixer"
echo HKR,Drivers\wave\wdmaud.drv,Driver,,wdmaud.drv
echo HKR,Drivers\midi\wdmaud.drv,Driver,,wdmaud.drv
echo HKR,Drivers\mixer\wdmaud.drv,Driver,,wdmaud.drv
echo HKR,Drivers\wave\wdmaud.drv,Description,,%%VIRTUALAUDIODRIVER_SA.DeviceDesc%%
echo HKR,Drivers\mixer\wdmaud.drv,Description,,%%VIRTUALAUDIODRIVER_SA.DeviceDesc%%
echo ; Register custom Name GUIDs with friendly names for endpoints
echo HKR,MediaCategories\%%GUID.MicArray1%%,Name,,%%MicArray1.Name%%
echo HKR,MediaCategories\%%GUID.Speaker%%,Name,,%%Speaker.Name%%
echo.
echo [VIRTUALAUDIODRIVER_SA.NT]
echo Include=ks.inf,wdmaudio.inf
echo Needs=KS.Registration, WDMAUDIO.Registration
echo CopyFiles=VIRTUALAUDIODRIVER_SA.CopyList,VIRTUALAUDIODRIVER_SA.IconCopyList
echo AddReg=VIRTUALAUDIODRIVER_SA.AddReg
echo AddProperty=DeviceIconProperty
echo.
echo [DeviceIconProperty]
echo DeviceIcon,,,,"%%13%%\CallJoyna.ico"
echo.
echo [VIRTUALAUDIODRIVER_SA.NT.Interfaces]
echo ; Speaker render endpoint
echo AddInterface=%%KSCATEGORY_AUDIO%%, %%KSNAME_WaveSpeaker%%, VIRTUALAUDIODRIVER.I.WaveSpeaker
echo AddInterface=%%KSCATEGORY_RENDER%%, %%KSNAME_WaveSpeaker%%, VIRTUALAUDIODRIVER.I.WaveSpeaker
echo AddInterface=%%KSCATEGORY_REALTIME%%, %%KSNAME_WaveSpeaker%%, VIRTUALAUDIODRIVER.I.WaveSpeaker
echo AddInterface=%%KSCATEGORY_AUDIO%%, %%KSNAME_TopologySpeaker%%, VIRTUALAUDIODRIVER.I.TopologySpeaker
echo AddInterface=%%KSCATEGORY_TOPOLOGY%%, %%KSNAME_TopologySpeaker%%, VIRTUALAUDIODRIVER.I.TopologySpeaker
echo ; Microphone capture endpoint
echo AddInterface=%%KSCATEGORY_AUDIO%%, %%KSNAME_WaveMicArray1%%, VIRTUALAUDIODRIVER.I.WaveMicArray1
echo AddInterface=%%KSCATEGORY_REALTIME%%, %%KSNAME_WaveMicArray1%%, VIRTUALAUDIODRIVER.I.WaveMicArray1
echo AddInterface=%%KSCATEGORY_CAPTURE%%, %%KSNAME_WaveMicArray1%%, VIRTUALAUDIODRIVER.I.WaveMicArray1
echo AddInterface=%%KSCATEGORY_AUDIO%%, %%KSNAME_TopologyMicArray1%%, VIRTUALAUDIODRIVER.I.TopologyMicArray1
echo AddInterface=%%KSCATEGORY_TOPOLOGY%%, %%KSNAME_TopologyMicArray1%%, VIRTUALAUDIODRIVER.I.TopologyMicArray1
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
echo ; Non-localizable
echo KSNAME_WaveSpeaker="WaveSpeaker"
echo KSNAME_TopologySpeaker="TopologySpeaker"
echo KSNAME_WaveMicArray1="WaveMicArray1"
echo KSNAME_TopologyMicArray1="TopologyMicArray1"
echo Proxy.CLSID="{17CCA71B-ECD7-11D0-B908-00A0C9223196}"
echo KSCATEGORY_AUDIO="{6994AD04-93EF-11D0-A3CC-00A0C9223196}"
echo KSCATEGORY_RENDER="{65E8773E-8F56-11D0-A3B9-00A0C9223196}"
echo KSCATEGORY_CAPTURE="{65E8773D-8F56-11D0-A3B9-00A0C9223196}"
echo KSCATEGORY_REALTIME="{EB115FFC-10C8-4964-831D-6DCB02E6F23F}"
echo KSCATEGORY_TOPOLOGY="{DDA54A40-1E4C-11D1-A050-405705C10000}"
echo KSNODETYPE_ANY="{00000000-0000-0000-0000-000000000000}"
echo PKEY_AudioEndpoint_Association="{1DA5D803-D492-4EDD-8C23-E0C0FFEE7F0E},2"
echo PKEY_AudioEndpoint_Supports_EventDriven_Mode="{1DA5D803-D492-4EDD-8C23-E0C0FFEE7F0E},7"
echo ; Custom Name GUIDs for endpoint friendly names
echo GUID.MicArray1="{6ae81ff4-203e-4fe1-88aa-f2d57775cd4a}"
echo GUID.Speaker="{7ae81ff4-203e-4fe1-88aa-f2d57775cd4b}"
echo MicArray1.Name="CallJoyna Mic"
echo Speaker.Name="CallJoyna Speaker"
echo ; Localizable
echo ProviderName = "CallJoyna"
echo MfgName = "CallJoyna"
echo DiskName = "CallJoyna Audio Driver Installation Disk"
echo VIRTUALAUDIODRIVER_SA.DeviceDesc = "CallJoyna Audio"
echo VirtualAudioDriver.SvcDesc = "CallJoyna Audio Service"
echo VIRTUALAUDIODRIVER.WaveSpeaker.szPname = "CallJoyna Speaker"
echo VIRTUALAUDIODRIVER.TopologySpeaker.szPname = "CallJoyna Speaker"
echo VIRTUALAUDIODRIVER.WaveMicArray1.szPname = "CallJoyna Mic"
echo VIRTUALAUDIODRIVER.TopologyMicArray1.szPname = "CallJoyna Mic"
) > "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\VirtualAudioDriver.inf"

:: Generate catalog
echo.
echo Generating catalog...
"%INF2CAT%" /driver:"%BASEDIR%\UnifiedPackage\VirtualAudioDriver" /os:10_NI_X64,10_NI_ARM64 /uselocaltime

if not exist "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\VirtualAudioDriver.cat" (
    echo ERROR: Catalog was not created!
    echo Trying with lowercase cat name...
    dir "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\*.cat"
)

:: Find and sign catalog (might be lowercase)
for %%f in ("%BASEDIR%\UnifiedPackage\VirtualAudioDriver\*.cat") do (
    echo Signing catalog: %%f
    "%SIGNTOOL%" sign /sha1 %THUMBPRINT% /fd sha256 /tr %TIMESTAMP% /td sha256 "%%f"
)

:: Create CAB with proper structure
echo.
echo Creating CAB...
cd /d "%BASEDIR%"

(
echo .OPTION EXPLICIT
echo .Set CabinetNameTemplate=VirtualAudioDriver_Unified.cab
echo .Set CompressionType=MSZIP
echo .Set Cabinet=on
echo .Set DiskDirectoryTemplate=.
echo .Set DestinationDir=VirtualAudioDriver
echo.
echo "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\VirtualAudioDriver.inf"
echo "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\VirtualAudioDriver.cat"
echo.
echo .Set DestinationDir=VirtualAudioDriver\amd64
echo "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\amd64\virtualaudiodriver.sys"
echo.
echo .Set DestinationDir=VirtualAudioDriver\arm64
echo "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\arm64\virtualaudiodriver.sys"
echo.
echo .Set DestinationDir=VirtualAudioDriver
echo "%BASEDIR%\UnifiedPackage\VirtualAudioDriver\CallJoyna.ico"
) > unified.ddf

makecab /F unified.ddf
del unified.ddf setup.inf setup.rpt 2>nul

:: Sign CAB
echo.
echo Signing CAB...
"%SIGNTOOL%" sign /sha1 %THUMBPRINT% /fd sha256 /tr %TIMESTAMP% /td sha256 "%BASEDIR%\VirtualAudioDriver_Unified.cab"

:: Verify
echo.
echo ========================================
echo Unified CAB Created!
echo ========================================
if exist "%BASEDIR%\VirtualAudioDriver_Unified.cab" (
    echo SUCCESS!
    dir "%BASEDIR%\VirtualAudioDriver_Unified.cab"
    echo.
    echo CAB Contents:
    expand -D "%BASEDIR%\VirtualAudioDriver_Unified.cab" 2>nul || (
        echo [expand not available in this shell]
    )
) else (
    echo FAILED - CAB not created
)

echo.
echo Structure:
echo   VirtualAudioDriver/
echo   +-- VirtualAudioDriver.inf  ^(references both archs^)
echo   +-- VirtualAudioDriver.cat  ^(covers both^)
echo   +-- amd64/
echo   ^|   +-- virtualaudiodriver.sys
echo   ^|   +-- virtualaudiodriver.pdb
echo   +-- arm64/
echo       +-- virtualaudiodriver.sys
echo       +-- virtualaudiodriver.pdb
echo.
pause
