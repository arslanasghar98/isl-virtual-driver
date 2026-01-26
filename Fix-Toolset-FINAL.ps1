# Fix-Toolset-FINAL.ps1
# FINAL CORRECT fix for WDK Toolset.targets - imports v143 toolset for Build target

#Requires -RunAsAdministrator

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "FINAL WDK Toolset.targets Fix for VS2022 BuildTools" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Solution: Import v143 Toolset.targets (which provides" -ForegroundColor Yellow
Write-Host "          the Build target), then add WDK targets on top." -ForegroundColor Yellow
Write-Host ""

$toolsetDirX64 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0"
$toolsetDirARM64 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\ARM64\PlatformToolsets\WindowsKernelModeDriver10.0"

# CORRECT Toolset.targets - imports v143 base toolset, then adds WDK targets
$targetsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <V142TargetsFile>$(VCTargetsPath)\Platforms\$(Platform)\PlatformToolsets\v142\Toolset.targets</V142TargetsFile>
    <V143TargetsFile>$(VCTargetsPath)\Platforms\$(Platform)\PlatformToolsets\v143\Toolset.targets</V143TargetsFile>
  </PropertyGroup>

  <!-- Import base v143 (or v142) toolset targets to get the Build target and standard C++ build system -->
  <Import Condition="Exists('$(V143TargetsFile)')" Project="$(V143TargetsFile)" />
  <Import Condition="!Exists('$(V143TargetsFile)')" Project="$(V142TargetsFile)" />

  <!-- Import WDK common driver build targets for driver-specific build steps -->
  <Import Project="$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Common.targets"
          Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Common.targets')" />
</Project>
'@

# Update x64 toolset
Write-Host "[1/2] Updating x64 Toolset.targets..." -ForegroundColor Yellow
if (Test-Path "$toolsetDirX64\Toolset.targets") {
    Set-Content -Path "$toolsetDirX64\Toolset.targets" -Value $targetsContent -Encoding UTF8
    Write-Host "      x64 Toolset.targets updated successfully" -ForegroundColor Green
} else {
    Write-Host "      ERROR: x64 Toolset.targets not found!" -ForegroundColor Red
    exit 1
}

# Update ARM64 toolset
Write-Host "[2/2] Updating ARM64 Toolset.targets..." -ForegroundColor Yellow
if (Test-Path "$toolsetDirARM64\Toolset.targets") {
    Set-Content -Path "$toolsetDirARM64\Toolset.targets" -Value $targetsContent -Encoding UTF8
    Write-Host "      ARM64 Toolset.targets updated successfully" -ForegroundColor Green
} else {
    Write-Host "      WARNING: ARM64 Toolset.targets not found, creating it..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $toolsetDirARM64 | Out-Null

    # Also need to create Toolset.props for ARM64
    $propsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <WDKContentRoot Condition="'$(WDKContentRoot)' == ''">C:\Program Files (x86)\Windows Kits\10\</WDKContentRoot>
    <WDKBuildFolder Condition="'$(WDKBuildFolder)' == ''">10.0.26100.0</WDKBuildFolder>
    <IsKernelModeToolset>true</IsKernelModeToolset>
  </PropertyGroup>

  <!-- Import the WDK's own platform integration file which sets up all WDK properties -->
  <Import Project="$(WDKContentRoot)build\$(WDKBuildFolder)\$(Platform)\ImportAfter\WDK.$(Platform).WindowsKernelModeDriver.Platform.props"
          Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\$(Platform)\ImportAfter\WDK.$(Platform).WindowsKernelModeDriver.Platform.props')" />
</Project>
'@
    Set-Content -Path "$toolsetDirARM64\Toolset.props" -Value $propsContent -Encoding UTF8
    Set-Content -Path "$toolsetDirARM64\Toolset.targets" -Value $targetsContent -Encoding UTF8
    Write-Host "      ARM64 toolset created and configured" -ForegroundColor Green
}

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Fix completed successfully!" -ForegroundColor Green
Write-Host "The WindowsKernelModeDriver10.0 toolset now properly" -ForegroundColor Green
Write-Host "inherits from v143 and adds WDK-specific build steps." -ForegroundColor Green
Write-Host ""
Write-Host "You can now run build.bat to compile the driver." -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Cyan
