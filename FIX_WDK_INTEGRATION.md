# Fix WDK Integration with Visual Studio Build Tools

## Problem
WDK is installed but Visual Studio Build Tools can't find it:
```
error MSB8020: The build tools for WindowsKernelModeDriver10.0 cannot be found
```

## Quick Fix Option 1: Re-run WDK Installer with VS Integration

1. **Download WDK installer again** (if you don't have it):
   - https://go.microsoft.com/fwlink/?linkid=2196230

2. **Run the installer**
   - It will detect existing installation
   - Make sure to check: **"Install Windows Driver Kit Visual Studio extension"**
   - Click Install/Modify

3. **Restart** your computer

4. **Try building again**:
   ```bash
   build.bat
   ```

## Quick Fix Option 2: Use Developer Command Prompt

Instead of regular Command Prompt, use the Developer Command Prompt:

1. **Search** for "Developer Command Prompt for VS 2022"
2. **Run as Administrator**
3. **Navigate** to your project:
   ```cmd
   cd D:\Datics\Virtual-Audio-Driver
   ```
4. **Run build**:
   ```cmd
   build.bat
   ```

## Quick Fix Option 3: Set Environment Variable

Run this before building:

```cmd
set WDKContentRoot=C:\Program Files (x86)\Windows Kits\10\
build.bat
```

## Quick Fix Option 4: Install via Visual Studio Installer

1. **Open Visual Studio Installer**
   - Search for "Visual Studio Installer" in Start Menu

2. **Click "Modify"** on Build Tools 2022

3. **Go to "Individual components" tab**

4. **Search for and select**:
   - ✅ Windows Driver Kit
   - ✅ MSVC v143 - VS 2022 C++ x64/x86 Spectre-mitigated libs (Latest)

5. **Click "Modify"** to install

6. **Try building again**

## Verify WDK Installation

Run this to check:
```cmd
dir "C:\Program Files (x86)\Windows Kits\10\build\10.0.26100.0"
```

You should see WindowsDriver.Common.props and other files.
