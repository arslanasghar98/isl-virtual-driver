# Build Instructions for ISL Audio Driver

## Quick Start

1. Install prerequisites (see below)
2. Open Command Prompt in repository folder
3. Run: `build.bat`
4. Find output in: `x64\Release\package\`

## Prerequisites

### 1. Visual Studio 2019 or 2022

**Required Components:**
- Desktop development with C++
- Windows 10/11 SDK (latest version)
- MSVC C++ compiler

**Download:**
- VS 2022 Community (Free): https://visualstudio.microsoft.com/downloads/
- VS 2019: https://visualstudio.microsoft.com/vs/older-downloads/

### 2. Windows Driver Kit (WDK)

The WDK must match your Visual Studio version:

**For Visual Studio 2022:**
- WDK for Windows 11, version 22H2: https://go.microsoft.com/fwlink/?linkid=2196230

**For Visual Studio 2019:**
- WDK for Windows 10, version 2004: https://go.microsoft.com/fwlink/?linkid=2128854

**Installation Steps:**
1. Download the WDK installer
2. Run the installer
3. Follow the wizard to install
4. Restart Visual Studio if it's open

### 3. Verify Installation

Open **Developer Command Prompt for VS** and run:
```bash
msbuild -version
```

You should see MSBuild version information.

## Building the Driver

### Method 1: Using build.bat (Recommended)

Open Command Prompt in the repository root:

```bash
# Default: Release build for x64
build.bat

# Debug build for x64
build.bat debug x64

# Release build for ARM64
build.bat release arm64

# Build everything (all configs + platforms)
build.bat all
```

### Method 2: Using Visual Studio

1. Open `VirtualAudioDriver.sln` in Visual Studio
2. Select configuration (Debug/Release) and platform (x64/ARM64) from toolbar
3. Press **F7** or go to **Build → Build Solution**

### Method 3: Using Developer Command Prompt

```bash
# For x64 Release
msbuild VirtualAudioDriver.sln /p:Configuration=Release /p:Platform=x64

# For ARM64 Release
msbuild VirtualAudioDriver.sln /p:Configuration=Release /p:Platform=ARM64
```

## Build Configurations

### Release vs Debug

- **Release**: Optimized build for production use (recommended)
- **Debug**: Includes debugging symbols, no optimization (for development)

### x64 vs ARM64

- **x64**: For Intel/AMD processors (most common)
- **ARM64**: For ARM processors (newer Windows devices)

**Recommendation:** Build both for maximum compatibility

## Build Output Location

After building, files are located in:

```
x64/Release/package/
├── VirtualAudioDriver.sys      # Driver binary
├── VirtualAudioDriver.inf      # Installation information
└── virtualaudiodriver.cat      # Catalog file (signature)
```

Or for ARM64:
```
ARM64/Release/package/
├── VirtualAudioDriver.sys
├── VirtualAudioDriver.inf
└── virtualaudiodriver.cat
```

## What Gets Built

### VirtualAudioDriver.sys
The kernel-mode driver binary that creates the virtual audio devices.

### VirtualAudioDriver.inf
Windows installation file containing:
- Device names (ISL Speaker, ISL Mic)
- Hardware IDs
- Registry settings
- Installation instructions

### virtualaudiodriver.cat
Catalog file for driver signing (initially unsigned).

## Testing the Driver (Development)

### Enable Test Signing Mode

For unsigned drivers during development:

```bash
# Open Command Prompt as Administrator
bcdedit /set testsigning on

# Reboot required
shutdown /r /t 0
```

**Warning:** This reduces system security. Only use for development.

### Install the Driver

```bash
# Navigate to build output directory
cd x64\Release\package

# Install driver
pnputil /add-driver VirtualAudioDriver.inf /install
```

### Verify Installation

1. Open **Device Manager** (devmgmt.msc)
2. Look for "Sound, video and game controllers"
3. You should see the driver listed
4. Check **Settings → Sound** for:
   - Output device: **ISL Speaker**
   - Input device: **ISL Mic**

### Uninstall Driver

```bash
# List installed drivers
pnputil /enum-drivers

# Find the OEM number for VirtualAudioDriver.inf
# Then uninstall (replace oemXX.inf with actual number)
pnputil /delete-driver oemXX.inf /uninstall /force
```

## Production Build Process

### 1. Build the Driver

```bash
build.bat release x64
build.bat release arm64
```

### 2. Sign the Driver

**Requirements:**
- Code signing certificate (EV certificate required for kernel drivers)
- SignTool from Windows SDK

**Signing Command:**
```bash
# Sign the .sys file
signtool sign /v /ac "C:\path\to\cross-cert.cer" ^
  /s "My" /n "Your Company Name" ^
  /t http://timestamp.digicert.com ^
  x64\Release\package\VirtualAudioDriver.sys

# Sign the .cat file
signtool sign /v /ac "C:\path\to\cross-cert.cer" ^
  /s "My" /n "Your Company Name" ^
  /t http://timestamp.digicert.com ^
  x64\Release\package\virtualaudiodriver.cat
```

### 3. Verify Signature

```bash
signtool verify /v /pa x64\Release\package\VirtualAudioDriver.sys
```

### 4. Package for Distribution

Copy the signed files for your Electron app:

```
your-electron-app/resources/drivers/
├── x64/
│   ├── VirtualAudioDriver.sys
│   ├── VirtualAudioDriver.inf
│   └── virtualaudiodriver.cat
└── ARM64/
    ├── VirtualAudioDriver.sys
    ├── VirtualAudioDriver.inf
    └── virtualaudiodriver.cat
```

## Troubleshooting

### "MSBuild not found"

**Solution:**
- Install Visual Studio with C++ workload
- Or add MSBuild to PATH manually

### "WDK headers not found"

**Solution:**
- Install WDK matching your Visual Studio version
- Restart Visual Studio after installation

### "ARM64 build fails with API validation errors"

**Solution:**
The build script automatically disables validation for ARM64. This is normal and expected.

### "Driver fails to load"

**Possible causes:**
1. Driver not signed (enable test signing for development)
2. Incompatible Windows version (requires Windows 10 1903+)
3. Missing dependencies

**Check Event Viewer:**
- Windows Logs → System
- Look for errors from "Service Control Manager"

### Build is very slow

**Solution:**
- Build only what you need (e.g., `build.bat release x64`)
- Close other applications
- Use SSD if possible
- Disable antivirus scanning of build directory temporarily

## Clean Build

If you encounter issues, try a clean build:

```bash
# Delete build artifacts
rmdir /s /q x64
rmdir /s /q ARM64
rmdir /s /q .vs

# Rebuild
build.bat
```

Or in Visual Studio:
- **Build → Clean Solution**
- **Build → Rebuild Solution**

## Build for CI/CD

For automated builds (GitHub Actions, Azure Pipelines, etc.):

```yaml
- name: Build Driver
  run: |
    call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat"
    build.bat release x64
  shell: cmd
```

See `.github/workflows/VAD-compile.yml` for full example.

## Next Steps

After building:
1. ✅ Test the driver on your development machine
2. ✅ Sign the driver with your code signing certificate
3. ✅ Integrate with your Electron app (see SILENT_INSTALLATION_GUIDE.md)
4. ✅ Test installation on clean Windows machines
5. ✅ Create installer package with driver files included

## Support

For build issues:
1. Check this guide's troubleshooting section
2. Verify all prerequisites are installed
3. Check Windows Event Viewer for driver errors
4. Review build output for error messages

## Additional Resources

- [Windows Driver Kit Documentation](https://docs.microsoft.com/en-us/windows-hardware/drivers/gettingstarted/)
- [Driver Signing Requirements](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/driver-signing)
- [MSBuild Reference](https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild)
