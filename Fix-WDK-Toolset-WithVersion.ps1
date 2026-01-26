# Fix-WDK-Toolset-WithVersion.ps1
# WDK Platform Toolset fix with explicit version setting

#Requires -RunAsAdministrator

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "WDK Platform Toolset Fix with Version" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

$toolsetDirX64 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0"
$toolsetDirARM64 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\ARM64\PlatformToolsets\WindowsKernelModeDriver10.0"

# Create Toolset.props with explicit version setting
$propsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <WDKContentRoot Condition="'$(WDKContentRoot)' == ''">C:\Program Files (x86)\Windows Kits\10\</WDKContentRoot>
    <WDKBuildFolder Condition="'$(WDKBuildFolder)' == ''">10.0.26100.0</WDKBuildFolder>
    <IsKernelModeToolset>true</IsKernelModeToolset>

    <!-- Set version properties before WDK imports them -->
    <WindowsTargetPlatformVersion Condition="'$(WindowsTargetPlatformVersion)' == ''">10.0.26100.0</WindowsTargetPlatformVersion>
    <TargetPlatformVersion Condition="'$(TargetPlatformVersion)' == ''">$(WindowsTargetPlatformVersion)</TargetPlatformVersion>
  </PropertyGroup>

  <!-- Import the WDK's own platform integration file which sets up all WDK properties -->
  <Import Project="$(WDKContentRoot)build\$(WDKBuildFolder)\$(Platform)\ImportAfter\WDK.$(Platform).WindowsKernelModeDriver.Platform.props"
          Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\$(Platform)\ImportAfter\WDK.$(Platform).WindowsKernelModeDriver.Platform.props')" />
</Project>
'@

# Create Toolset.targets - imports BOTH standard C++ targets and WDK targets
$targetsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <!-- Import standard C++ targets to get the Build target and standard build system -->
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />

  <!-- Import WDK common targets for driver-specific build steps -->
  <Import Project="$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Common.targets"
          Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Common.targets')" />
</Project>
'@

# Update x64 toolset
Write-Host "[1/2] Updating x64 platform toolset..." -ForegroundColor Yellow
if (Test-Path $toolsetDirX64) {
    Set-Content -Path "$toolsetDirX64\Toolset.props" -Value $propsContent -Encoding UTF8
    Set-Content -Path "$toolsetDirX64\Toolset.targets" -Value $targetsContent -Encoding UTF8
    Write-Host "      x64 toolset updated successfully" -ForegroundColor Green
} else {
    New-Item -ItemType Directory -Force -Path $toolsetDirX64 | Out-Null
    Set-Content -Path "$toolsetDirX64\Toolset.props" -Value $propsContent -Encoding UTF8
    Set-Content -Path "$toolsetDirX64\Toolset.targets" -Value $targetsContent -Encoding UTF8
    Write-Host "      x64 toolset created and configured" -ForegroundColor Green
}

# Update ARM64 toolset
Write-Host "[2/2] Updating ARM64 platform toolset..." -ForegroundColor Yellow
if (Test-Path $toolsetDirARM64) {
    Set-Content -Path "$toolsetDirARM64\Toolset.props" -Value $propsContent -Encoding UTF8
    Set-Content -Path "$toolsetDirARM64\Toolset.targets" -Value $targetsContent -Encoding UTF8
    Write-Host "      ARM64 toolset updated successfully" -ForegroundColor Green
} else {
    New-Item -ItemType Directory -Force -Path $toolsetDirARM64 | Out-Null
    Set-Content -Path "$toolsetDirARM64\Toolset.props" -Value $propsContent -Encoding UTF8
    Set-Content -Path "$toolsetDirARM64\Toolset.targets" -Value $targetsContent -Encoding UTF8
    Write-Host "      ARM64 toolset created and configured" -ForegroundColor Green
}

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Fix completed successfully!" -ForegroundColor Green
Write-Host "You can now run build.bat to compile the driver." -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Cyan
