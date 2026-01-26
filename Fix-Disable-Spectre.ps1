# Fix-Disable-Spectre.ps1
# Disable Spectre mitigation to allow building without Spectre-mitigated libraries

#Requires -RunAsAdministrator

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Disabling Spectre Mitigation for Build" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Spectre mitigation requires additional libraries that" -ForegroundColor Yellow
Write-Host "aren't installed. Disabling it for now." -ForegroundColor Yellow
Write-Host ""
Write-Host "Note: For production builds, you should install the" -ForegroundColor Yellow
Write-Host "Spectre-mitigated libraries via Visual Studio Installer." -ForegroundColor Yellow
Write-Host ""

$toolsetDirX64 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0"
$toolsetDirARM64 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\ARM64\PlatformToolsets\WindowsKernelModeDriver10.0"

# Updated Toolset.props without Spectre mitigation and without duplicate OS.Props import
$propsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <IsKernelModeToolset>true</IsKernelModeToolset>
    <!-- Disable Spectre mitigation to avoid requiring Spectre-mitigated libraries -->
    <SpectreMitigation></SpectreMitigation>
    <DebuggerFlavor Condition="'$(DebuggerFlavor)'==''">DbgengKernelDebugger</DebuggerFlavor>

    <!-- Set WDK paths -->
    <WDKContentRoot Condition="'$(WDKContentRoot)' == ''">$(Registry:HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Kits\Installed Roots@KitsRoot10)</WDKContentRoot>
    <WDKContentRoot Condition="'$(WDKContentRoot)' == ''">$(Registry:HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows Kits\Installed Roots@KitsRoot10)</WDKContentRoot>
    <WDKContentRoot Condition="'$(WDKContentRoot)' == ''">C:\Program Files (x86)\Windows Kits\10\</WDKContentRoot>

    <!-- Check for Trailing Slash -->
    <WDKContentRoot Condition="'$(WDKContentRoot)'!='' AND !HasTrailingSlash('$(WDKContentRoot)')">$(WDKContentRoot)\</WDKContentRoot>

    <!-- Set WindowsSdkDir (same as WDK for Windows 10) -->
    <WindowsSdkDir Condition="'$(WindowsSdkDir)' == ''">$(WDKContentRoot)</WindowsSdkDir>
  </PropertyGroup>

  <!-- Import WindowsDriver.Default.props - this sets MatchingWdkPresent and other validation properties -->
  <Import Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Default.props')"
          Project="$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Default.props"/>

  <!-- Import WindowsDriver.Shared.Props - this sets MatchingSdkPresent and imports OS.Props -->
  <Import Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Shared.Props')"
          Project="$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Shared.Props"/>

  <!-- Note: WindowsDriver.OS.Props is already imported by Shared.Props, so we don't import it again -->

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
Set-Content -Path "$toolsetDirX64\Toolset.props" -Value $propsContent -Encoding UTF8
Write-Host "      x64 Toolset.props updated successfully" -ForegroundColor Green

# Update ARM64 toolset
Write-Host "[2/2] Updating ARM64 Toolset.props..." -ForegroundColor Yellow
if (!(Test-Path $toolsetDirARM64)) {
    New-Item -ItemType Directory -Force -Path $toolsetDirARM64 | Out-Null
}
Set-Content -Path "$toolsetDirARM64\Toolset.props" -Value $propsContent -Encoding UTF8
Write-Host "      ARM64 Toolset.props updated successfully" -ForegroundColor Green

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "Fix completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Changes made:" -ForegroundColor Green
Write-Host "  - Disabled Spectre mitigation (SpectreMitigation=empty)" -ForegroundColor Green
Write-Host "  - Removed duplicate WindowsDriver.OS.Props import" -ForegroundColor Green
Write-Host ""
Write-Host "You can now run build.bat to compile the driver." -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Cyan
