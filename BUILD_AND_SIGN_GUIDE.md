# CallJoyna Audio Driver - Build and Sign Guide

This document describes how to compile, sign, and package the CallJoyna Audio Driver.

> **INF authoring lessons learned (must-read for INF edits):**
> - **Custom endpoint icon (Device Manager + Sound panel):** use `HKR,EP\0,%DEVPKEY_DeviceClass_IconPath%,0x00020000,"%%SystemRoot%%\System32\drivers\CallJoyna.ico"` on each topology endpoint AddReg. `DEVPKEY_DeviceClass_IconPath = "{259ABFFC-50A7-47CE-AF08-68C9A7D73366},12"`. `PKEY_AudioEndpoint_IconPath` (`{F1AB780D-...},0`) covers the modern Sound settings icon. **`DEVPKEY_DrvPkg_Icon` cannot be used via INF `AddProperty` — InfVerif rejects it (error 1081).** Flag `0x00020000` (REG_EXPAND_SZ) is required so `%SystemRoot%` resolves; `0x00000000` leaves the literal string in the registry and Windows fails silently.
> - **OS decoration:** `[VIRTUALAUDIODRIVER.NTamd64.10.0...22000]` is **Win11 only** (build 22000+) and Code 28 on Win10. Use `NTamd64.10.0...17763` to cover Win10 1809+ and all Win11 (and update both the `[Manufacturer]` line and the model section).
> - **DriverVer:** bump on every change. PnP refuses equal-version reinstalls.
> - **Validate before building:** `InfVerif.exe /v VirtualAudioDriver.inf` catches GUID typos, AddProperty issues, and section-ordering errors before you spend time on `inf2cat`/sign.

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

## Step 5: Create CAB for Microsoft Partner Center

### 5.1 Required CAB contents

Per [Microsoft's attestation signing docs](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/code-signing-attestation), a Partner Center CAB **must contain** all of the following inside a single subfolder (no files at the CAB root):

| File | Required? | Notes |
|---|---|---|
| `*.inf` | Yes | The driver INF the dashboard uses for signing |
| `*.sys` | Yes | The driver binary, signed with your EV cert |
| `*.cat` | **Yes** | Catalog signed with your EV cert. Microsoft regenerates and re-signs it during processing — yours is for company verification only. **Omitting this causes "Unable to extract and upload PackageInfo.xml."** |
| `*.pdb` | Yes | Symbol file required by Microsoft's automated crash analysis |
| Files referenced by INF (e.g. `*.ico`) | Yes | Anything declared in `[SourceDisksFiles]` must be in the CAB |

> **Don't include unreferenced files.** Partner Center now warns about (and may eventually reject) files in the CAB that aren't either `.pdb` or referenced by the INF. The yellow "Driver signing changes coming" banner refers to this enforcement.

### 5.2 `partner_center.ddf` (canonical version)

```ddf
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
.Set CabinetNameTemplate=VirtualAudioDriver_PartnerCenter.cab
.Set DestinationDir=VirtualAudioDriver
D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf
D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.sys
D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.cat
D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.pdb
D:\Datics\Virtual-Audio-Driver\x64\Release\CallJoyna.ico
```

The `*Threshold` and `Max*` settings disable splitting so the whole submission is one CAB.

### 5.3 Build sequence — order matters

The `.cat` file contains the Authenticode hash of the *unsigned* `.sys`. You must regenerate the catalog whenever the INF or any file referenced by the INF changes, and re-sign both `.sys` and `.cat` afterwards.

```cmd
:: 1. Build (Step 1) — produces unsigned .sys
:: 2. Stage the source-of-truth INF + ICO into x64\Release (msbuild does NOT copy these — Rebuild deletes them):
copy /Y DriverPackage\VirtualAudioDriver.inf x64\Release\
copy /Y DriverPackage\CallJoyna.ico        x64\Release\
```

```powershell
# 3. Generate catalog (Step 2)
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\inf2cat.exe" `
    /driver:"D:\Datics\Virtual-Audio-Driver\x64\Release" /os:10_X64 /uselocaltime

# 4. Sign .sys and .cat with EV cert (Step 3)
.\sign_and_verify.bat

# 5. Build CAB
Set-Location "D:\Datics\Virtual-Audio-Driver"
if (Test-Path ".\disk1") { Remove-Item .\disk1 -Recurse -Force }
makecab /F .\partner_center.ddf

# 6. Sign the CAB itself
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" sign `
    /tr http://timestamp.digicert.com /td SHA256 /fd SHA256 `
    /sha1 a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b `
    .\disk1\VirtualAudioDriver_PartnerCenter.cab

# 7. Verify CAB signature
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" verify /pa /v `
    .\disk1\VirtualAudioDriver_PartnerCenter.cab
# Expect: "Successfully verified"

# 8. Copy to project root for upload convenience
Copy-Item .\disk1\VirtualAudioDriver_PartnerCenter.cab .\VirtualAudioDriver_PartnerCenter.cab -Force
```

### 5.4 Pre-upload audit checklist

Before clicking *Submit new hardware*, run this audit and confirm every line:

```powershell
$cab = ".\VirtualAudioDriver_PartnerCenter.cab"
$tmp = ".\cab_audit"; Remove-Item $tmp -Recurse -Force -EA SilentlyContinue; New-Item -ItemType Directory $tmp | Out-Null
expand.exe -F:* $cab $tmp | Out-Null

# 1. All five files present
Get-ChildItem "$tmp\VirtualAudioDriver" | Format-Table Name, Length

# 2. INF version + OS decoration match what you intend
Select-String "$tmp\VirtualAudioDriver\VirtualAudioDriver.inf" -Pattern "DriverVer|NTamd64"

# 3. .sys signature chain ends at your EV identity
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" verify /pa /v "$tmp\VirtualAudioDriver\virtualaudiodriver.sys"

# 4. .cat signature chain ends at your EV identity
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" verify /pa /v "$tmp\VirtualAudioDriver\virtualaudiodriver.cat"

# 5. CAB itself signature
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" verify /pa /v $cab

Remove-Item $tmp -Recurse -Force
```

### 5.5 Common errors and fixes

| Error in Partner Center UI | Cause | Fix |
|---|---|---|
| `Unable to extract and upload PackageInfo.xml.` | Missing `.cat`, files at CAB root, or unsupported compression | Use the DDF in 5.2 verbatim; verify with audit in 5.4 |
| `There are files at the root of the cabinet.` | DDF has no `.Set DestinationDir=...` | Keep `DestinationDir=VirtualAudioDriver` line |
| `No .inf files found in driver directory/directories: XYZ.` | INF in wrong subfolder, or INF parse error | Run `InfVerif.exe /v <inf>` locally first |
| `File is using Zip64(4gb+file Size)` | CAB built as zip64 instead of MSZIP | Confirm `CompressionType=MSZIP` in DDF |
| Submission stays in *Package Acceptance* with red X | Same as PackageInfo.xml error above (most common) | See first row |

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

**SELECT all x64 Windows versions covered by your INF's `NTamd64.10.0...<build>` decoration.** With the canonical `NTamd64.10.0...17763` (Win10 1809+) decoration, that is:

- ✅ Windows 10 Client version 1809 Client x64 (RS5)
- ✅ Windows 10 19H1 Client x64
- ✅ Windows 10 Client version 2004 x64 (Vb)
- ✅ Windows - Client, version 21H2 x64 (Co)
- ✅ Windows 11 Client, version 22H2 x64 (Ni)
- ✅ Windows 11 Client, version 24H2 x64 (Ge)
- ✅ Windows 11 Client, version 25H2 x64 (Ge)
- ✅ Windows 11 Client, version 26H1 x64

**Do NOT select:**
- ❌ Any pre-RS5 entries (RS1/RS2/RS3/RS4/TH2) — these are below build 17763 and the INF won't match
- ❌ Any ARM64 versions (driver is x64 only)
- ❌ Any 32-bit versions

> **OS decoration vs OS targets must agree.** If the INF says `NTamd64.10.0...17763` and you tick Windows 10 1607 (build 14393), Microsoft signs for an OS the driver refuses to install on. To support older Win10 builds, lower the decoration in the INF first (e.g. `NTamd64.10.0...14393` for RS1+), then re-cab and re-submit.

> **Note:** The UI says "Leave all checkboxes blank for Attestation Signing" but this only refers to test-signing. You MUST select at least one OS version.

### 6.4 Submit and Wait

1. Click **Submit**
2. Wait for processing (typically 5-30 minutes)
3. Monitor progress through: Package Acceptance → Preparation → Scanning → Validation → Catalog creation → Sign → Finalize

> **Updating an existing attestation-signed driver:** the [Driver Update Acceptable (DUA) flow is *not* available for attestation submissions](https://learn.microsoft.com/en-us/windows-hardware/drivers/dashboard/hardware-submission-update). To ship a new version, click **Submit new hardware** again — it creates a sibling submission under a new Private Product ID. Both submissions stay visible in the Drivers list; ship only the latest. Always bump `DriverVer` in the INF before each new submission, otherwise PnP rejects the install with "best driver already installed."

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
