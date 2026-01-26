# Fix-Toolset-Targets.ps1
# Run this script as Administrator to fix the Toolset.targets file

#Requires -RunAsAdministrator

Write-Host "Fixing Toolset.targets file..." -ForegroundColor Yellow

$toolsetDirX64 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0"
$toolsetDirARM64 = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\ARM64\PlatformToolsets\WindowsKernelModeDriver10.0"

# Create corrected Toolset.targets file
$targetsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <!-- Import WDK-specific targets that define the Build target for kernel mode drivers -->
  <!-- Do NOT import Microsoft.Cpp.targets here - it's already imported by the project file -->
  <Import Project="$(WDKContentRoot)build\$(WDKBuildFolder)\$(Platform)\ImportAfter\WDK.$(Platform).WindowsDriverCommonToolset.Platform.Targets" Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\$(Platform)\ImportAfter\WDK.$(Platform).WindowsDriverCommonToolset.Platform.Targets')" />
</Project>
'@

# Update x64 Toolset.targets
if (Test-Path $toolsetDirX64) {
    Set-Content -Path "$toolsetDirX64\Toolset.targets" -Value $targetsContent -Encoding UTF8
    Write-Host "[OK] Updated x64 Toolset.targets" -ForegroundColor Green
} else {
    Write-Host "[ERROR] x64 toolset directory not found: $toolsetDirX64" -ForegroundColor Red
    Write-Host "        Please run Install-WDK-Integration.ps1 first" -ForegroundColor Yellow
}

# Update ARM64 Toolset.targets
if (Test-Path $toolsetDirARM64) {
    Set-Content -Path "$toolsetDirARM64\Toolset.targets" -Value $targetsContent -Encoding UTF8
    Write-Host "[OK] Updated ARM64 Toolset.targets" -ForegroundColor Green
}

Write-Host ""
Write-Host "Fix completed! You can now run build.bat" -ForegroundColor Green
