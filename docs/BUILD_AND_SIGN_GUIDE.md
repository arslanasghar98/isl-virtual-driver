# Virtual Audio Driver - Build, Sign, and CAB Creation Guide

This document describes the complete workflow for building, signing, and packaging the CallJoyna Virtual Audio Driver for Microsoft Partner Center attestation signing.

## Prerequisites

### Required Tools
- **Visual Studio 2022/2025** with Windows Driver Kit (WDK)
- **Windows SDK** (10.0.26100.0 or later)
- **MSBuild** (included with Visual Studio)
- **SignTool** (`C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe`)
- **Inf2Cat** (`C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\inf2cat.exe`)
- **MakeCab** (included with Windows)

### Code Signing Certificate
- **Certificate**: DigiCert EV Code Signing Certificate (ZipCeleb LLC)
- **Thumbprint**: `a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b`
- **Timestamp Server**: `http://timestamp.digicert.com`

## Directory Structure

```
D:\Datics\Virtual-Audio-Driver\
├── Source\
│   ├── Main\           # Main driver source
│   ├── Filters\        # Audio filter topology tables
│   ├── Utilities\      # Utility functions
│   └── Inc\            # Header files
├── x64\Release\        # Built x64 driver
├── ARM64\Release\      # Built ARM64 driver
├── UnifiedPackage\     # Generated unified package
│   └── VirtualAudioDriver\
│       ├── VirtualAudioDriver.inf
│       ├── VirtualAudioDriver.cat
│       ├── CallJoyna.ico
│       ├── amd64\virtualaudiodriver.sys
│       └── arm64\virtualaudiodriver.sys
├── rebuild_driver.bat  # Driver rebuild script
├── create_unified_cab.bat  # CAB creation script
└── VirtualAudioDriver_Unified.cab  # Final CAB for submission
```

## Step 1: Build the Driver

### Using rebuild_driver.bat
```batch
cd D:\Datics\Virtual-Audio-Driver
rebuild_driver.bat
```

This script:
1. Rebuilds x64 Release configuration
2. Rebuilds ARM64 Release configuration

### Manual Build (if needed)
```batch
set MSBUILD="C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe"

:: Build x64
%MSBUILD% VirtualAudioDriver.sln /p:Configuration=Release /p:Platform=x64 /t:Rebuild

:: Build ARM64
%MSBUILD% VirtualAudioDriver.sln /p:Configuration=Release /p:Platform=ARM64 /t:Rebuild
```

### Build Output
- `x64\Release\virtualaudiodriver.sys`
- `ARM64\Release\virtualaudiodriver.sys`

## Step 2: Create Unified CAB Package

### Using create_unified_cab.bat
```batch
cd D:\Datics\Virtual-Audio-Driver
create_unified_cab.bat
```

This script:
1. Creates `UnifiedPackage\VirtualAudioDriver\` directory structure
2. Copies binaries for both architectures
3. Generates unified INF file
4. Runs Inf2Cat to create catalog
5. Signs the catalog with DigiCert certificate
6. Creates CAB file with makecab
7. Signs the CAB file

### Version Update
Before running, update the version in `create_unified_cab.bat`:
```batch
echo DriverVer   = MM/DD/YYYY,X.X.X.0
```

## Step 3: INF File Structure

### Critical Sections

#### SourceDisksNames (Multi-Architecture)
```inf
[SourceDisksNames]
2 = %DiskName%                    ; For icon (architecture-neutral)

[SourceDisksNames.amd64]
1 = %DiskName%,,,amd64            ; x64 binaries

[SourceDisksNames.arm64]
1 = %DiskName%,,,arm64            ; ARM64 binaries
```

#### SourceDisksFiles
```inf
[SourceDisksFiles]
CallJoyna.ico = 2                 ; Icon from disk 2 (root)

[SourceDisksFiles.amd64]
virtualaudiodriver.sys = 1        ; Driver from disk 1 (amd64 folder)

[SourceDisksFiles.arm64]
virtualaudiodriver.sys = 1        ; Driver from disk 1 (arm64 folder)
```

#### DestinationDirs
```inf
[DestinationDirs]
DefaultDestDir = 12                           ; %SystemRoot%\System32\drivers
VIRTUALAUDIODRIVER_SA.CopyList = 12           ; Driver files
VIRTUALAUDIODRIVER_SA.IconCopyList = 13       ; DIRID 13 = Driver Store
```

#### CopyFiles (MUST include icon)
```inf
[VIRTUALAUDIODRIVER_SA.NT]
CopyFiles=VIRTUALAUDIODRIVER_SA.CopyList,VIRTUALAUDIODRIVER_SA.IconCopyList

[VIRTUALAUDIODRIVER_SA.CopyList]
virtualaudiodriver.sys

[VIRTUALAUDIODRIVER_SA.IconCopyList]
CallJoyna.ico
```

#### DeviceIcon Property (IMPORTANT: 4 commas, not 5)
```inf
[VIRTUALAUDIODRIVER_SA.NT]
AddProperty=DeviceIconProperty

[DeviceIconProperty]
DeviceIcon,,,,"%13%\CallJoyna.ico"
```

#### MediaCategories for Custom Endpoint Names
```inf
[VIRTUALAUDIODRIVER_SA.AddReg]
; Register custom Name GUIDs with friendly names
HKR,MediaCategories\%GUID.MicArray1%,Name,,%MicArray1.Name%
HKR,MediaCategories\%GUID.Speaker%,Name,,%Speaker.Name%

[Strings]
; Custom Name GUIDs (must match driver source code)
GUID.MicArray1="{6ae81ff4-203e-4fe1-88aa-f2d57775cd4a}"
GUID.Speaker="{7ae81ff4-203e-4fe1-88aa-f2d57775cd4b}"
MicArray1.Name="CallJoyna Mic"
Speaker.Name="CallJoyna Speaker"
```

## Step 4: Driver Source - Endpoint Names

### KSNODETYPE for Endpoint Type
The endpoint type (Microphone/Speaker vs Line In/Line Out) is determined by KSNODETYPE in the driver source:

**micarray1toptable.h** (line ~64):
```cpp
&KSNODETYPE_MICROPHONE,  // Category - shows as "Microphone" type
```

**speakertoptable.h** (line ~85):
```cpp
&KSNODETYPE_SPEAKER,     // Category - shows as "Speaker" type
```

### Custom Name GUIDs
The custom endpoint names come from Name GUIDs registered via INF MediaCategories:

**micarray1toptable.h**:
```cpp
DEFINE_GUID(MICARRAY1_CUSTOM_NAME,
    0x6ae81ff4, 0x203e, 0x4fe1, 0x88, 0xaa, 0xf2, 0xd5, 0x77, 0x75, 0xcd, 0x4a);
```

**speakertoptable.h**:
```cpp
DEFINE_GUID(SPEAKER_CUSTOM_NAME,
    0x7ae81ff4, 0x203e, 0x4fe1, 0x88, 0xaa, 0xf2, 0xd5, 0x77, 0x75, 0xcd, 0x4b);
```

## Step 5: Submit to Microsoft Partner Center

1. Go to https://partner.microsoft.com/dashboard/hardware
2. Create new hardware submission
3. Upload `VirtualAudioDriver_Unified.cab`
4. Select "Attestation Signing"
5. Leave all checkboxes blank for attestation signing
6. Wait for Microsoft to sign (usually 1-2 hours)
7. Download signed package

## Step 6: Deploy to Desktop App

After receiving Microsoft-signed package:

```bash
# Extract signed package
unzip Signed_XXXX.zip -d Signed_XXXX

# Copy to desktop app
cp Signed_XXXX/drivers/VirtualAudioDriver/VirtualAudioDriver.inf D:/Datics/virtual-mic-isl/build/driver/
cp Signed_XXXX/drivers/VirtualAudioDriver/VirtualAudioDriver.cat D:/Datics/virtual-mic-isl/build/driver/virtualaudiodriver.cat
cp Signed_XXXX/drivers/VirtualAudioDriver/CallJoyna.ico D:/Datics/virtual-mic-isl/build/driver/
cp Signed_XXXX/drivers/VirtualAudioDriver/amd64/virtualaudiodriver.sys D:/Datics/virtual-mic-isl/build/driver/amd64/
cp Signed_XXXX/drivers/VirtualAudioDriver/arm64/virtualaudiodriver.sys D:/Datics/virtual-mic-isl/build/driver/arm64/
```

## Common Issues and Fixes

### 1. "Unreferenced files" Warning in Partner Center
**Cause**: Files in CAB not referenced by INF
**Fix**: Ensure ALL files have:
- Entry in `SourceDisksFiles`
- Entry in `CopyFiles` directive
- Entry in `DestinationDirs`

### 2. Generic Endpoint Names (Microphone/Speakers instead of CallJoyna Mic/Speaker)
**Cause**: Custom Name GUIDs not registered in MediaCategories
**Fix**: Add `HKR,MediaCategories\%GUID.xxx%,Name,,%xxx.Name%` to AddReg section

### 3. Device Icon Not Showing
**Cause**: Wrong DeviceIcon format (5 commas instead of 4)
**Fix**: Use `DeviceIcon,,,,"%13%\icon.ico"` (4 commas)

### 4. ARM64 Install Path Wrong (Program Files x86)
**Cause**: NSIS installer not detecting ARM64 properly
**Fix**: Add customInit macro in installer.nsh:
```nsh
!macro customInit
  ReadEnvStr $R0 "PROCESSOR_ARCHITEW6432"
  ${If} $R0 == "ARM64"
    StrCpy $INSTDIR "$PROGRAMFILES64\${PRODUCT_NAME}"
  ${EndIf}
!macroend
```

### 5. Scanning Takes Too Long in Partner Center
**Cause**: PDB files or unreferenced files
**Fix**: Remove PDB files from CAB, ensure all files are referenced

## Quick Reference Commands

```batch
:: Rebuild driver
D:\Datics\Virtual-Audio-Driver\rebuild_driver.bat

:: Create and sign CAB
D:\Datics\Virtual-Audio-Driver\create_unified_cab.bat

:: Verify signature
signtool verify /pa /v VirtualAudioDriver_Unified.cab

:: Check driver timestamp
stat x64\Release\virtualaudiodriver.sys

:: Verify INF syntax
inf2cat /driver:UnifiedPackage\VirtualAudioDriver /os:10_NI_X64,10_NI_ARM64
```

## Version History

| Version | Date | Changes | Partner Center ID |
|---------|------|---------|-------------------|
| 2.0.10.0 | 2026-07-10 | Initial multi-arch support | 1152921505701397908 |
| 2.0.11.0 | 2026-07-10 | Added IconCopyList for proper icon handling | - |
| 2.0.12.0 | 2026-07-13 | Driver rebuild with KSNODETYPE fixes | 1152921505701407471 |
| 2.0.13.0 | 2026-07-13 | Added MediaCategories for custom endpoint names | - |
| 2.0.14.0 | 2026-07-13 | Fixed DeviceIcon format (4 commas), MediaCategories | 1152921505701408470 |

## Deployment Log

### v2.0.14.0 - Deployed 2026-07-13
- **Signed Package**: `E:\Downloads\Signed_1152921505701408470.zip`
- **Deployed to**: `D:\Datics\virtual-mic-isl\build\driver\`
- **Features**:
  - Fixed DeviceIcon property format (4 commas)
  - MediaCategories registry entries for custom endpoint names
  - Both x64 and ARM64 drivers Microsoft-signed
- **Files**:
  - `VirtualAudioDriver.inf` (v2.0.14.0)
  - `virtualaudiodriver.cat` (Microsoft signed)
  - `CallJoyna.ico`
  - `amd64/virtualaudiodriver.sys` (Microsoft signed)
  - `arm64/virtualaudiodriver.sys` (Microsoft signed)

## References

- [Friendly Names for Audio Endpoint Devices](https://learn.microsoft.com/en-us/windows-hardware/drivers/audio/friendly-names-for-audio-endpoint-devices)
- [Providing Icons for a Device](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/providing-vendor-icons-for-the-shell-and-autoplay)
- [Run From Driver Store (DIRID 13)](https://learn.microsoft.com/en-us/windows-hardware/drivers/develop/run-from-driver-store)
- [INF SourceDisksFiles Section](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-sourcedisksfiles-section)
