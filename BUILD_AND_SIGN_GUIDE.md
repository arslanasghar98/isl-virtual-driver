# CallJoyna Audio Driver - Build and Sign Guide

This document describes how to compile, sign, and package the CallJoyna Audio Driver.

---

## Prerequisites

### Required Software
- **Visual Studio 2022** (with C++ Desktop Development)
- **Windows Driver Kit (WDK) 10** (matching VS version)
- **Windows SDK 10**
- **DigiCert KeyLocker** (for EV code signing)

### Required Paths (verify these exist)
```
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat
C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\inf2cat.exe
C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe
```

---

## Step 1: Build the Driver

### Option A: Using Developer Command Prompt

```cmd
:: Open Developer Command Prompt for VS 2022, then:
cd D:\Datics\Virtual-Audio-Driver
msbuild VirtualAudioDriver.sln /p:Configuration=Release /p:Platform=x64 /t:Build
```

### Option B: Using Command Line (Full Path)

```cmd
"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"
cd /d D:\Datics\Virtual-Audio-Driver
msbuild VirtualAudioDriver.sln /p:Configuration=Release /p:Platform=x64 /t:Build
```

### Build Output
After successful build, files are in `x64\Release\`:
- `virtualaudiodriver.sys` - Driver binary
- `virtualaudiodriver.pdb` - Debug symbols
- `VirtualAudioDriver.inf` - Installation info file

---

## Step 2: Generate Catalog File

The catalog file (.cat) contains hashes of all driver files for Windows to verify integrity.

```powershell
# Generate catalog
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\inf2cat.exe" `
    /driver:"D:\Datics\Virtual-Audio-Driver\x64\Release" `
    /os:10_X64 `
    /uselocaltime
```

**Output:** `x64\Release\virtualaudiodriver.cat`

---

## Step 3: Sign the Driver

### 3.1 Sync DigiCert Certificate

```powershell
smctl windows certsync --keypair-alias key_1435973180
```

### 3.2 Sign the .sys File

```powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" sign `
    /tr http://timestamp.digicert.com `
    /td SHA256 `
    /fd SHA256 `
    /sha1 a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b `
    "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.sys"
```

### 3.3 Sign the .cat File

```powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" sign `
    /tr http://timestamp.digicert.com `
    /td SHA256 `
    /fd SHA256 `
    /sha1 a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b `
    "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.cat"
```

### 3.4 Verify Signatures

```powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" verify /pa `
    "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.sys"

& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" verify /pa `
    "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.cat"
```

Expected output: `Successfully verified`

---

## Step 4: Create CAB File for Desktop App

### 4.1 Create DDF File

Create `build_cab.ddf`:
```
.OPTION EXPLICIT
.Set CabinetFileCountThreshold=0
.Set FolderFileCountThreshold=0
.Set FolderSizeThreshold=0
.Set MaxCabinetSize=0
.Set MaxDiskFileCount=0
.Set MaxDiskSize=0
.Set CompressionType=MSZIP
.Set Cabinet=on
.Set Compress=on
.Set CabinetNameTemplate=VirtualAudioDriver.cab
.Set DestinationDir=VirtualAudioDriver
D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf
D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.sys
D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.cat
```

### 4.2 Build CAB

```cmd
cd /d D:\Datics\Virtual-Audio-Driver
makecab /F build_cab.ddf
```

**Output:** `disk1\VirtualAudioDriver.cab`

### 4.3 Deploy to Desktop App

```powershell
# Copy CAB to desktop app resources
Move-Item "D:\Datics\Virtual-Audio-Driver\disk1\VirtualAudioDriver.cab" `
    "D:\Datics\virtual-mic-isl\resources\VirtualAudioDriver.cab" -Force

# Update build/driver folder
Copy-Item "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf" `
    "D:\Datics\virtual-mic-isl\build\driver\" -Force
Copy-Item "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.sys" `
    "D:\Datics\virtual-mic-isl\build\driver\" -Force
Copy-Item "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.cat" `
    "D:\Datics\virtual-mic-isl\build\driver\" -Force

# Cleanup
Remove-Item "D:\Datics\Virtual-Audio-Driver\disk1" -Recurse -Force
Remove-Item "D:\Datics\Virtual-Audio-Driver\build_cab.ddf" -Force
```

---

## Step 5: Create CAB for Microsoft Partner Center (Optional)

For WHQL/Attestation signing, Microsoft requires the PDB file.

### 5.1 Create Partner Center DDF

```
.OPTION EXPLICIT
.Set CompressionType=MSZIP
.Set Cabinet=on
.Set Compress=on
.Set CabinetNameTemplate=VirtualAudioDriver_PartnerCenter.cab
.Set DestinationDir=VirtualAudioDriver
D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf
D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.sys
D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.pdb
```

### 5.2 Build and Sign Partner Center CAB

```cmd
makecab /F partner_center.ddf
```

```powershell
# Sign the CAB itself
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" sign `
    /tr http://timestamp.digicert.com `
    /td SHA256 `
    /fd SHA256 `
    /sha1 a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b `
    "disk1\VirtualAudioDriver_PartnerCenter.cab"
```

---

## Step 6: Microsoft Partner Center Attestation Signing

Attestation signing gets your driver signed by Microsoft, making it fully trusted on all Windows machines without test mode or security warnings.

### 6.1 Prerequisites

- Microsoft Partner Center account registered for Hardware Developer Program
- EV code signing certificate (DigiCert)
- Driver CAB signed with your EV certificate (from Step 5)

### 6.2 Submit to Partner Center

1. Go to [Partner Center Hardware Dashboard](https://partner.microsoft.com/dashboard/hardware/Search)
2. Sign in with your credentials
3. Click **Submit new hardware**
4. Enter product name: `CallJoyna Virtual Audio Driver`
5. Upload the signed CAB file: `VirtualAudioDriver_PartnerCenter.cab`

### 6.3 Configure Signing Options

**Leave UNCHECKED:**
- ❌ "Perform test-signing" checkbox

**SELECT these x64 Windows versions:**
- ✅ Windows 10 Client version 1607 x64 (RS1)
- ✅ Windows 10 Client version 2004 x64 (Vb)
- ✅ Windows - Client, version 21H2 x64 (Co)
- ✅ Windows 11 Client, version 22H2 x64 (Ni)
- ✅ Windows 11 Client, version 24H2 x64 (Ge)
- ✅ Windows 11 Client, version 25H2 x64 (Ge)
- ✅ Windows 11 Client, version 26H1 x64

**Do NOT select:**
- ❌ Any ARM64 versions (driver is x64 only)
- ❌ Any 32-bit versions

> **Note:** The UI says "Leave all checkboxes blank for Attestation Signing" but this only refers to test-signing. You MUST select at least one OS version.

### 6.4 Submit and Wait

1. Click **Submit**
2. Wait for processing (typically 5-30 minutes)
3. Monitor progress through: Package Acceptance → Preparation → Scanning → Validation → Catalog creation → Sign → Finalize

### 6.5 Download Signed Driver

After signing completes:
1. Download the signed package (e.g., `Signed_1152921505700887839.zip`)
2. Extract to get the Microsoft-signed files:
   ```
   drivers/
   └── VirtualAudioDriver/
       ├── VirtualAudioDriver.inf
       ├── virtualaudiodriver.sys
       └── virtualaudiodriver.cat  ← Microsoft signed!
   ```

### 6.6 Verify Microsoft Signature

```powershell
# Check the catalog file - should show "Microsoft Windows Hardware Compatibility Publisher"
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" verify /pa /v `
    "C:\Users\Datics\Downloads\Signed_XXXXX\drivers\VirtualAudioDriver\virtualaudiodriver.cat"
```

Expected signer chain:
```
Microsoft Root Certificate Authority 2010
└── Microsoft Windows Third Party Component CA 2014
    └── Microsoft Windows Hardware Compatibility Publisher
```

### 6.7 Deploy Microsoft-Signed Driver to Desktop App

```powershell
$signedDir = "C:\Users\Datics\Downloads\Signed_XXXXX\drivers\VirtualAudioDriver"
$driverDir = "D:\Datics\Virtual-Audio-Driver"
$desktopApp = "D:\Datics\virtual-mic-isl"

# Create DDF for new CAB
$ddf = @"
.OPTION EXPLICIT
.Set CabinetFileCountThreshold=0
.Set FolderFileCountThreshold=0
.Set FolderSizeThreshold=0
.Set MaxCabinetSize=0
.Set MaxDiskFileCount=0
.Set MaxDiskSize=0
.Set CompressionType=MSZIP
.Set Cabinet=on
.Set Compress=on
.Set CabinetNameTemplate=VirtualAudioDriver.cab
.Set DestinationDir=VirtualAudioDriver
$signedDir\VirtualAudioDriver.inf
$signedDir\virtualaudiodriver.sys
$signedDir\virtualaudiodriver.cat
"@
$ddf | Out-File "$driverDir\ms_signed.ddf" -Encoding ASCII

# Build CAB
Push-Location $driverDir
makecab /F ms_signed.ddf
Pop-Location

# Deploy to desktop app
Move-Item "$driverDir\disk1\VirtualAudioDriver.cab" "$desktopApp\resources\VirtualAudioDriver.cab" -Force
Copy-Item "$signedDir\VirtualAudioDriver.inf" "$desktopApp\build\driver\" -Force
Copy-Item "$signedDir\virtualaudiodriver.sys" "$desktopApp\build\driver\" -Force
Copy-Item "$signedDir\virtualaudiodriver.cat" "$desktopApp\build\driver\" -Force

# Cleanup
Remove-Item "$driverDir\disk1" -Recurse -Force
Remove-Item "$driverDir\ms_signed.ddf" -Force

Write-Host "Microsoft-signed driver deployed!" -ForegroundColor Green
```

### 6.8 Attestation vs WHQL Comparison

| Feature | Attestation Signing | WHQL Certification |
|---------|--------------------|--------------------|
| **Testing Required** | Self-tested | HLK lab testing |
| **Processing Time** | Minutes | Days/Weeks |
| **Windows Update** | No | Yes |
| **Trust Level** | Full | Full |
| **Cost** | Free (with EV cert) | Free (with EV cert) |
| **Best For** | Direct distribution | OEM/Retail distribution |

---

## Quick Reference Script

Save as `build-sign-package.ps1`:

```powershell
# CallJoyna Driver Build, Sign, and Package Script
param(
    [switch]$SkipBuild,
    [switch]$PartnerCenter
)

$driverDir = "D:\Datics\Virtual-Audio-Driver"
$desktopApp = "D:\Datics\virtual-mic-isl"
$releaseDir = "$driverDir\x64\Release"
$signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
$inf2cat = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\inf2cat.exe"
$thumbprint = "a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b"

# Step 1: Build
if (-not $SkipBuild) {
    Write-Host "Building driver..." -ForegroundColor Cyan
    Push-Location $driverDir
    & cmd /c "`"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat`" && msbuild VirtualAudioDriver.sln /p:Configuration=Release /p:Platform=x64 /t:Build /v:m"
    Pop-Location
}

# Step 2: Generate catalog
Write-Host "Generating catalog..." -ForegroundColor Cyan
& $inf2cat /driver:$releaseDir /os:10_X64 /uselocaltime

# Step 3: Sign
Write-Host "Syncing certificate..." -ForegroundColor Cyan
smctl windows certsync --keypair-alias key_1435973180

Write-Host "Signing files..." -ForegroundColor Cyan
& $signtool sign /tr http://timestamp.digicert.com /td SHA256 /fd SHA256 /sha1 $thumbprint "$releaseDir\virtualaudiodriver.sys"
& $signtool sign /tr http://timestamp.digicert.com /td SHA256 /fd SHA256 /sha1 $thumbprint "$releaseDir\virtualaudiodriver.cat"

# Step 4: Verify
Write-Host "Verifying signatures..." -ForegroundColor Cyan
& $signtool verify /pa "$releaseDir\virtualaudiodriver.sys"
& $signtool verify /pa "$releaseDir\virtualaudiodriver.cat"

# Step 5: Create CAB
Write-Host "Creating CAB..." -ForegroundColor Cyan
$ddf = @"
.OPTION EXPLICIT
.Set CompressionType=MSZIP
.Set Cabinet=on
.Set Compress=on
.Set CabinetNameTemplate=VirtualAudioDriver.cab
.Set DestinationDir=VirtualAudioDriver
$releaseDir\VirtualAudioDriver.inf
$releaseDir\virtualaudiodriver.sys
$releaseDir\virtualaudiodriver.cat
"@
$ddf | Out-File "$driverDir\build.ddf" -Encoding ASCII
Push-Location $driverDir
makecab /F build.ddf
Pop-Location

# Step 6: Deploy
Write-Host "Deploying to desktop app..." -ForegroundColor Cyan
Move-Item "$driverDir\disk1\VirtualAudioDriver.cab" "$desktopApp\resources\VirtualAudioDriver.cab" -Force
Copy-Item "$releaseDir\VirtualAudioDriver.inf" "$desktopApp\build\driver\" -Force
Copy-Item "$releaseDir\virtualaudiodriver.sys" "$desktopApp\build\driver\" -Force
Copy-Item "$releaseDir\virtualaudiodriver.cat" "$desktopApp\build\driver\" -Force

# Cleanup
Remove-Item "$driverDir\disk1" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$driverDir\build.ddf" -Force -ErrorAction SilentlyContinue

Write-Host "Done!" -ForegroundColor Green
```

---

## Driver Information

| Property | Value |
|----------|-------|
| **Provider** | CallJoyna |
| **Signer** | Insurance Sales Lab (ZipCeleb LLC) |
| **Certificate** | DigiCert EV Code Signing |
| **Thumbprint** | a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b |
| **Hardware ID** | ROOT\VirtualAudioDriver |
| **Devices** | CallJoyna Speaker, CallJoyna Mic |

---

## Troubleshooting

### Build Fails: "MSBuild not found"
Ensure Visual Studio Build Tools are installed and use VsDevCmd.bat to set up environment.

### Signing Fails: "No certificate found"
Run `smctl windows certsync --keypair-alias key_1435973180` to sync the DigiCert certificate.

### inf2cat Fails: "No catalog generated"
Ensure the INF file has correct DriverVer date format: `MM/DD/YYYY,X.X.X.X`

### Driver Shows "Unknown" Signer
The catalog file may not match the driver files. Regenerate catalog and re-sign both files.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0.16 | 04/16/2026 | Renamed to CallJoyna |
| 1.0.0.17 | 04/21/2026 | Added 5-second startup delay for mic engagement |
| 1.0.0.17 | 04/21/2026 | Microsoft attestation signed via Partner Center |
