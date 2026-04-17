# CallJoyna Audio Driver - Installation & Uninstallation Guide

## Overview

The CallJoyna Audio Driver provides virtual audio devices for routing audio in the CallJoyna application:
- **CallJoyna Speaker** - Virtual playback device (receives processed audio)
- **CallJoyna Mic** - Virtual recording device (used by meeting apps as microphone)

---

## Prerequisites

- Windows 10/11 (x64)
- Administrator privileges
- Windows Driver Kit (WDK) tools installed
- DigiCert KeyLocker credentials (for signing)

---

## Building the Driver

### Step 1: Build the Driver

```batch
cd D:\Datics\Virtual-Audio-Driver
build.bat release x64
```

This compiles the driver and outputs files to `x64\Release\`:
- `virtualaudiodriver.sys` - The driver binary
- `VirtualAudioDriver.inf` - Installation information file

### Step 2: Copy INF File (if needed)

```batch
copy DriverPackage\VirtualAudioDriver.inf x64\Release\
```

---

## Signing the Driver

### Step 1: Sync DigiCert Certificate

```powershell
smctl windows certsync --keypair-alias key_1435973180
```

### Step 2: Create Catalog File

```powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\inf2cat.exe" /driver:"D:\Datics\Virtual-Audio-Driver\x64\Release" /os:10_X64 /uselocaltime
```

### Step 3: Sign the Driver Files

```powershell
# Sign .sys file
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" sign /tr http://timestamp.digicert.com /td SHA256 /fd SHA256 /sha1 a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.sys"

# Sign .cat file
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" sign /tr http://timestamp.digicert.com /td SHA256 /fd SHA256 /sha1 a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.cat"
```

### Step 4: Verify Signatures

```powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" verify /pa "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.sys"

& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe" verify /pa "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.cat"
```

Expected output: `Successfully verified`

---

## Installation

### Method 1: Using DevCon (Recommended)

Run as Administrator:

```powershell
# Install the driver
& "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe" install "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf" "ROOT\VirtualAudioDriver"

# Restart audio service
net stop audiosrv
net start audiosrv
```

### Method 2: Using PnPUtil

Run as Administrator:

```powershell
# Add driver to store and install
pnputil /add-driver "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf" /install

# Restart audio service
net stop audiosrv
net start audiosrv
```

### Verification

```powershell
# Check device is installed
Get-PnpDevice -Class MEDIA | Where-Object { $_.FriendlyName -like "*CallJoyna*" }

# Check driver in store
pnputil /enum-drivers | Select-String "CallJoyna" -Context 3,5
```

Expected output:
```
FriendlyName    Status
------------    ------
CallJoyna Audio OK
```

---

## Uninstallation

### Method 1: Complete Uninstall (Recommended)

Run as Administrator:

```powershell
# Step 1: Stop audio service
net stop audiosrv

# Step 2: Find the OEM driver number
pnputil /enum-drivers | Select-String "CallJoyna" -Context 3,0

# Step 3: Remove the device
& "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe" remove "ROOT\VirtualAudioDriver"

# Step 4: Delete driver from store (replace oemXX with actual number from Step 2)
pnputil /delete-driver oemXX.inf /uninstall /force

# Step 5: Restart audio service
net start audiosrv
```

### Method 2: Quick Uninstall

```powershell
# Find and remove in one step
$driver = pnputil /enum-drivers | Select-String "virtualaudiodriver" -Context 2,0
# Extract oem number and delete
pnputil /delete-driver oem42.inf /uninstall /force
```

### Verification

```powershell
# Confirm device is removed
Get-PnpDevice -Class MEDIA | Where-Object { $_.FriendlyName -like "*CallJoyna*" }

# Confirm driver is removed from store
pnputil /enum-drivers | Select-String "CallJoyna"
```

Expected: No output (device and driver removed)

---

## Troubleshooting

### Device Shows "Error" Status

```powershell
# Remove the problematic device
devcon remove "@ROOT\MEDIA\000X"  # Replace X with device number

# Reinstall
devcon install "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf" "ROOT\VirtualAudioDriver"

# Restart audio
net stop audiosrv && net start audiosrv
```

### Multiple Devices Created

```powershell
# Remove all CallJoyna devices
for ($i = 1; $i -le 10; $i++) {
    devcon remove "@ROOT\MEDIA\000$i" 2>$null
}

# Remove from store
pnputil /enum-drivers | Select-String "virtualaudiodriver" -Context 2,0
# Delete each oem*.inf found

# Fresh install
devcon install "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf" "ROOT\VirtualAudioDriver"
```

### Driver Not Loading (Signature Issues)

1. Verify signature:
```powershell
signtool verify /pa "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.sys"
```

2. If failed, re-sign following the Signing section above

3. Check if Secure Boot is causing issues (should not with valid EV signature)

### Audio Service Won't Start

```powershell
# Check dependencies
sc query audiosrv
sc query AudioEndpointBuilder

# Start in order
net start AudioEndpointBuilder
net start audiosrv
```

---

## Quick Reference Commands

| Action | Command |
|--------|---------|
| Build driver | `build.bat release x64` |
| Sign driver | `.\Sign-Driver-DigiCert.ps1 -Configuration Release -Platform x64` |
| Install driver | `devcon install "...\VirtualAudioDriver.inf" ROOT\VirtualAudioDriver` |
| Uninstall driver | `pnputil /delete-driver oemXX.inf /uninstall /force` |
| List MEDIA devices | `Get-PnpDevice -Class MEDIA` |
| List driver packages | `pnputil /enum-drivers` |
| Restart audio | `net stop audiosrv && net start audiosrv` |

---

## File Locations

| File | Path |
|------|------|
| Source INX | `Source\Main\VirtualAudioDriver.inx` |
| Built SYS | `x64\Release\virtualaudiodriver.sys` |
| Built CAT | `x64\Release\virtualaudiodriver.cat` |
| INF File | `x64\Release\VirtualAudioDriver.inf` |
| Sign Script | `Sign-Driver-DigiCert.ps1` |
| Install Script | `install-calljoyna.ps1` |

---

## Driver Information

| Property | Value |
|----------|-------|
| Provider | CallJoyna |
| Manufacturer | CallJoyna |
| Signer | Insurance Sales Lab (ZipCeleb LLC) |
| Hardware ID | ROOT\VirtualAudioDriver |
| Class | MEDIA |
| Devices Created | CallJoyna Speaker, CallJoyna Mic |
