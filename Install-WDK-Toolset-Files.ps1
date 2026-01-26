# Install correct WDK Toolset files from VSIX
# Run this script as Administrator

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Installing correct WDK Toolset files from VSIX..." -ForegroundColor Cyan

# Extract VSIX to temp location
$vsixPath = "C:\Program Files (x86)\Windows Kits\10\Vsix\VS2022\10.0.22621.0\WDK.vsix"
$tempDir = "$env:TEMP\WDK_VSIX_Extract"
$toolsetDir = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0"

# Clean temp dir if it exists
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}

Write-Host "Extracting VSIX package..." -ForegroundColor Yellow
# Rename .vsix to .zip and extract
$zipPath = "$env:TEMP\WDK.zip"
Copy-Item $vsixPath $zipPath -Force
Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
Remove-Item $zipPath -Force

# Copy Toolset.props
$propsSource = "$tempDir\`$MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0\Toolset.props"
$propsDestFile = "$toolsetDir\Toolset.props"

if (Test-Path $propsSource) {
    Copy-Item $propsSource $toolsetDir -Force
    Write-Host "✓ Toolset.props installed" -ForegroundColor Green
} else {
    Write-Host "ERROR: Toolset.props not found in VSIX" -ForegroundColor Red
    exit 1
}

# Copy Toolset.targets
$targetsSource = "$tempDir\`$MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets\WindowsKernelModeDriver10.0\Toolset.targets"
$targetsDestFile = "$toolsetDir\Toolset.targets"

if (Test-Path $targetsSource) {
    Copy-Item $targetsSource $toolsetDir -Force
    Write-Host "✓ Toolset.targets installed" -ForegroundColor Green
} else {
    Write-Host "ERROR: Toolset.targets not found in VSIX" -ForegroundColor Red
    exit 1
}

# Clean up
Remove-Item $tempDir -Recurse -Force

Write-Host ""
Write-Host "SUCCESS! WDK Toolset files have been installed correctly." -ForegroundColor Green
Write-Host "You can now run build.bat to build your driver." -ForegroundColor Green
Write-Host ""

pause
