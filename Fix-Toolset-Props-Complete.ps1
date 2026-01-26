# Fix-Toolset-Props-Complete.ps1
# Complete fix for WDK Toolset.props - includes WindowsDriver.Default.props import

#Requires -RunAsAdministrator

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Complete WDK Toolset.props Fix for VS2022 BuildTools" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Adding missing WindowsDriver.Default.props import" -ForegroundColor Yellow
Write-Host "This is required for WDK validation to work." -ForegroundColor Yellow
Write-Host ""

$toolsetDirX64 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0"
$toolsetDirARM64 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\ARM64\PlatformToolsets\WindowsKernelModeDriver10.0"

# Complete Toolset.props - based on official WDK structure
$propsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <IsKernelModeToolset>true</IsKernelModeToolset>
    <Driver_SpectreMitigation Condition="'$(Driver_SpectreMitigation)' == ''">Spectre</Driver_SpectreMitigation>
    <SpectreMitigation>$(Driver_SpectreMitigation)</SpectreMitigation>
    <DebuggerFlavor Condition="'$(DebuggerFlavor)'==''">DbgengKernelDebugger</DebuggerFlavor>

    <!-- Set WDK paths -->
    <WDKContentRoot Condition="'$(WDKContentRoot)' == ''">$(Registry:HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Kits\Installed Roots@KitsRoot10)</WDKContentRoot>
    <WDKContentRoot Condition="'$(WDKContentRoot)' == ''">$(Registry:HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows Kits\Installed Roots@KitsRoot10)</WDKContentRoot>
    <WDKContentRoot Condition="'$(WDKContentRoot)' == ''">C:\Program Files (x86)\Windows Kits\10\</WDKContentRoot>

    <!-- Check for Trailing Slash -->
    <WDKContentRoot Condition="'$(WDKContentRoot)'!='' AND !HasTrailingSlash('$(WDKContentRoot)')">$(WDKContentRoot)\</WDKContentRoot>
  </PropertyGroup>

  <!-- Import WindowsDriver.Default.props - this sets MatchingWdkPresent and other validation properties -->
  <Import Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Default.props')"
          Project="$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Default.props"/>

  <!-- Import platform-specific WDK props -->
  <Import Project="$(WDKContentRoot)build\$(WDKBuildFolder)\$(Platform)\WindowsKernelModeDriver\*.props" />

  <!-- Import base v143 (or v142) toolset props to inherit standard C++ properties -->
  <PropertyGroup>
    <V142PropsFile>$(VCTargetsPath)\Platforms\$(Platform)\PlatformToolsets\v142\Toolset.props</V142PropsFile>
    <V143PropsFile>$(VCTargetsPath)\Platforms\$(Platform)\PlatformToolsets\v143\Toolset.props</V143PropsFile>
  </PropertyGroup>

  <Import Condition="Exists('$(V143PropsFile)')" Project="$(V143PropsFile)" />
  <Import Condition="!Exists('$(V143PropsFile)')" Project="$(V142PropsFile)" />

</Project>
'@

# Update x64 toolset
Write-Host "[1/2] Updating x64 Toolset.props..." -ForegroundColor Yellow
if (Test-Path "$toolsetDirX64\Toolset.props") {
    Set-Content -Path "$toolsetDirX64\Toolset.props" -Value $propsContent -Encoding UTF8
    Write-Host "      x64 Toolset.props updated successfully" -ForegroundColor Green
} else {
    Write-Host "      ERROR: x64 Toolset.props not found!" -ForegroundColor Red
    exit 1
}

# Update ARM64 toolset
Write-Host "[2/2] Updating ARM64 Toolset.props..." -ForegroundColor Yellow
if (Test-Path "$toolsetDirARM64\Toolset.props") {
    Set-Content -Path "$toolsetDirARM64\Toolset.props" -Value $propsContent -Encoding UTF8
    Write-Host "      ARM64 Toolset.props updated successfully" -ForegroundColor Green
} else {
    Write-Host "      WARNING: ARM64 Toolset.props not found, creating it..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $toolsetDirARM64 | Out-Null
    Set-Content -Path "$toolsetDirARM64\Toolset.props" -Value $propsContent -Encoding UTF8
    Write-Host "      ARM64 Toolset.props created successfully" -ForegroundColor Green
}

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Fix completed successfully!" -ForegroundColor Green
Write-Host "The Toolset.props now properly imports WindowsDriver.Default.props" -ForegroundColor Green
Write-Host "which sets up WDK validation and other required properties." -ForegroundColor Green
Write-Host ""
Write-Host "You can now run build.bat to compile the driver." -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Cyan
