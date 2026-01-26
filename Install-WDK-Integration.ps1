# Install-WDK-Integration.ps1
# Run this script as Administrator to register WDK with Visual Studio 2022 BuildTools

#Requires -RunAsAdministrator

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "WDK Platform Toolset Registration for VS2022 BuildTools" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

# Check if WDK is installed
$wdkPath = "C:\Program Files (x86)\Windows Kits\10"
if (-not (Test-Path $wdkPath)) {
    Write-Host "ERROR: Windows Driver Kit not found at $wdkPath" -ForegroundColor Red
    exit 1
}

Write-Host "[1/4] WDK installation found" -ForegroundColor Green

# Check if VS2022 BuildTools is installed
$vsPath = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
if (-not (Test-Path $vsPath)) {
    Write-Host "ERROR: Visual Studio 2022 BuildTools not found at $vsPath" -ForegroundColor Red
    exit 1
}

Write-Host "[2/4] VS2022 BuildTools installation found" -ForegroundColor Green

# Create platform toolset directory for x64
$toolsetDirX64 = "$vsPath\MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0"
Write-Host "[3/4] Creating platform toolset directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $toolsetDirX64 | Out-Null

# Create Toolset.props file
$propsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <WDKContentRoot Condition="'$(WDKContentRoot)' == ''">C:\Program Files (x86)\Windows Kits\10\</WDKContentRoot>
    <WDKBuildFolder Condition="'$(WDKBuildFolder)' == ''">10.0.26100.0</WDKBuildFolder>
    <IsKernelModeToolset>true</IsKernelModeToolset>
  </PropertyGroup>

  <!-- Import WDK common properties -->
  <Import Project="$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Common.props"
          Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Common.props')" />
</Project>
'@

Set-Content -Path "$toolsetDirX64\Toolset.props" -Value $propsContent -Encoding UTF8
Write-Host "    Created Toolset.props" -ForegroundColor Gray

# Create Toolset.targets file
$targetsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <!-- Import WDK common targets that define the Build target and other driver-specific targets -->
  <Import Project="$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Common.targets"
          Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Common.targets')" />
</Project>
'@

Set-Content -Path "$toolsetDirX64\Toolset.targets" -Value $targetsContent -Encoding UTF8
Write-Host "    Created Toolset.targets" -ForegroundColor Gray

# Also create for ARM64 if needed
$toolsetDirARM64 = "$vsPath\MSBuild\Microsoft\VC\v170\Platforms\ARM64\PlatformToolsets\WindowsKernelModeDriver10.0"
New-Item -ItemType Directory -Force -Path $toolsetDirARM64 | Out-Null
Set-Content -Path "$toolsetDirARM64\Toolset.props" -Value $propsContent -Encoding UTF8
Set-Content -Path "$toolsetDirARM64\Toolset.targets" -Value $targetsContent -Encoding UTF8
Write-Host "    Created ARM64 platform toolset files" -ForegroundColor Gray

Write-Host "[4/4] Platform toolset registered successfully!" -ForegroundColor Green

# Verification
Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Verification" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan

if (Test-Path "$toolsetDirX64\Toolset.props") {
    Write-Host "[OK] x64 Toolset.props created" -ForegroundColor Green
} else {
    Write-Host "[FAIL] x64 Toolset.props not found" -ForegroundColor Red
}

if (Test-Path "$toolsetDirX64\Toolset.targets") {
    Write-Host "[OK] x64 Toolset.targets created" -ForegroundColor Green
} else {
    Write-Host "[FAIL] x64 Toolset.targets not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "You can now run build.bat to compile the driver." -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Cyan
