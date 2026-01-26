# WDK Build Integration Fix

## Problem
The Windows Driver Kit (WDK) is installed, but it's not integrated with Visual Studio 2022 BuildTools. The `WindowsKernelModeDriver10.0` platform toolset cannot be found.

## Root Cause
- WDK Visual Studio integration requires either:
  - Full Visual Studio (not BuildTools) to install VSIX extensions, OR
  - Manual registration of the platform toolset files (requires admin rights)
- You have VS2022 BuildTools which doesn't support VSIX extensions
- The platform toolset files need to be in: `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0\`

## Solutions

### Option 1: Install WDK Integration (RECOMMENDED - Requires Admin)
Run these commands in an **Administrator** PowerShell:

```powershell
# Create the platform toolset directory
$toolsetDir = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0"
New-Item -ItemType Directory -Force -Path $toolsetDir

# Create the platform toolset props file
$propsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <WDKContentRoot Condition="'$(WDKContentRoot)' == ''">C:\Program Files (x86)\Windows Kits\10\</WDKContentRoot>
    <WDKBuildFolder Condition="'$(WDKBuildFolder)' == ''">10.0.26100.0</WDKBuildFolder>
    <IsKernelModeToolset>true</IsKernelModeToolset>
  </PropertyGroup>
  <Import Project="$(WDKContentRoot)build\$(WDKBuildFolder)\$(Platform)\ImportAfter\WDK.$(Platform).WindowsKernelModeDriver.Platform.props" Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\$(Platform)\ImportAfter\WDK.$(Platform).WindowsKernelModeDriver.Platform.props')" />
</Project>
'@

Set-Content -Path "$toolsetDir\Toolset.props" -Value $propsContent

# Create the platform toolset targets file
$targetsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Import Project="$(WDKContentRoot)build\$(WDKBuildFolder)\$(Platform)\ImportAfter\WDK.$(Platform).WindowsDriverCommonToolset.Platform.Targets" Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\$(Platform)\ImportAfter\WDK.$(Platform).WindowsDriverCommonToolset.Platform.Targets')" />
</Project>
'@

Set-Content -Path "$toolsetDir\Toolset.targets" -Value $targetsContent

Write-Host "WDK platform toolset registered successfully!" -ForegroundColor Green
```

After running this, you should be able to build with: `.\build.bat`

### Option 2: Install Full Visual Studio 2022
1. Install Visual Studio 2022 Community/Professional (not just BuildTools)
2. Install the WDK VSIX extension:
   ```powershell
   & "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\VSIXInstaller.exe" "C:\Program Files (x86)\Windows Kits\10\Vsix\VS2022\10.0.22621.0\WDK.vsix"
   ```

### Option 3: Use Enterprise WDK (Standalone)
Download and use the Enterprise WDK which doesn't require Visual Studio integration.

## Current Status
The following files have been created to help with WDK configuration:
- `Directory.Build.props` - Sets WDK paths and properties
- `Directory.Build.targets` - Imports WDK build targets

However, these files alone cannot register the platform toolset with MSBuild without admin rights.

## Next Steps
1. Choose one of the solutions above
2. Run the required commands with administrator privileges
3. Run `.\build.bat` to build the driver

## Verification
After applying a solution, verify the toolset is registered:
```powershell
Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0\Toolset.props"
```

This should return `True` if the registration was successful.
