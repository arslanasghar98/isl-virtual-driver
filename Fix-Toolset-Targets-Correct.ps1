# Fix WDK Toolset.targets - Import WindowsDriver.Common.targets
# Run this script as Administrator

$toolsetDir = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0"
$targetsFile = Join-Path $toolsetDir "Toolset.targets"

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Fixing WDK Toolset.targets to import WindowsDriver.Common.targets..." -ForegroundColor Cyan

# Create the corrected targets file content
$targetsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <!-- Import WDK common driver build targets -->
  <Import Project="$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Common.targets"
          Condition="Exists('$(WDKContentRoot)build\$(WDKBuildFolder)\WindowsDriver.Common.targets')" />
</Project>
'@

# Write the file
try {
    Set-Content -Path $targetsFile -Value $targetsContent -Force
    Write-Host "SUCCESS: Toolset.targets has been updated!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The file now imports WindowsDriver.Common.targets which provides the Build target." -ForegroundColor Green
    Write-Host "You can now run build.bat to build your driver." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to update Toolset.targets" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    pause
    exit 1
}

pause
