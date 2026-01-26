# Fix-Toolset-Targets-Correct-v2.ps1
# Corrected fix for WDK Toolset.targets - removes duplicate Microsoft.Cpp.targets import

#Requires -RunAsAdministrator

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Corrected WDK Toolset.targets Fix for VS2022 BuildTools" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Issue: Microsoft.Cpp.targets is being imported twice" -ForegroundColor Yellow
Write-Host "       - Once by the project file (line 98)" -ForegroundColor Yellow
Write-Host "       - Once by Toolset.targets (line 4)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Solution: Remove the import from Toolset.targets since" -ForegroundColor Yellow
Write-Host "          the project file already handles it." -ForegroundColor Yellow
Write-Host ""

$toolsetDirX64 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0"
$toolsetDirARM64 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\ARM64\PlatformToolsets\WindowsKernelModeDriver10.0"

# Corrected Toolset.targets - ONLY imports WDK targets, not Microsoft.Cpp.targets
$targetsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <!-- Import WDK common driver build targets -->
  <!-- Note: Microsoft.Cpp.targets is already imported by the project file, so we only import WDK-specific targets here -->
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
Write-Host "You can now run build.bat to compile the driver." -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Cyan
