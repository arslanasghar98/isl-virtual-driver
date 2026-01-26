#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Silent installation script for Virtual Audio Driver

.DESCRIPTION
    This script installs the Virtual Audio Driver (ISL Speaker/Mic) silently.
    It requires administrator privileges to install the driver.

.EXAMPLE
    .\Install-VirtualAudioDriver.ps1
#>

[CmdletBinding()]
param()

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Virtual Audio Driver Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$driverPath = Join-Path $scriptDir "x64\Release"
$infFile = Join-Path $driverPath "VirtualAudioDriver.inf"
$sysFile = Join-Path $driverPath "virtualaudiodriver.sys"

# Verify files exist
Write-Host "[1/5] Verifying driver files..." -ForegroundColor Yellow
if (-not (Test-Path $infFile)) {
    Write-Host "ERROR: INF file not found at: $infFile" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $sysFile)) {
    Write-Host "ERROR: SYS file not found at: $sysFile" -ForegroundColor Red
    exit 1
}
Write-Host "      Driver files verified successfully" -ForegroundColor Green

# Check if driver is already installed
Write-Host "[2/5] Checking for existing driver installation..." -ForegroundColor Yellow
$existingDriver = pnputil /enum-drivers | Select-String -Pattern "virtualaudiodriver" -Context 0,5
if ($existingDriver) {
    Write-Host "      Driver is already installed" -ForegroundColor Yellow
    $oeminf = ($existingDriver | Select-String -Pattern "Published Name.*oem\d+\.inf").Matches.Value -replace "Published Name\s*:\s*", ""

    if ($oeminf) {
        Write-Host "      Uninstalling existing driver ($oeminf)..." -ForegroundColor Yellow
        $uninstallResult = pnputil /delete-driver $oeminf /uninstall /force 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "      Existing driver uninstalled successfully" -ForegroundColor Green
        } else {
            Write-Host "      Warning: Could not uninstall existing driver" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "      No existing driver installation found" -ForegroundColor Green
}

# Install the driver
Write-Host "[3/5] Adding driver to driver store..." -ForegroundColor Yellow
$addResult = pnputil /add-driver "$infFile" /install 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to add driver to driver store" -ForegroundColor Red
    Write-Host $addResult -ForegroundColor Red
    exit 1
}
Write-Host "      Driver added to driver store successfully" -ForegroundColor Green
Write-Host $addResult

# Create the virtual audio device
Write-Host "[4/5] Creating virtual audio device..." -ForegroundColor Yellow
$hwid = "ROOT\VirtualAudioDriver"

# Check if device already exists
$existingDevice = Get-PnpDevice -FriendlyName "*ISL Speaker*" -ErrorAction SilentlyContinue
if ($existingDevice) {
    Write-Host "      Virtual audio device already exists" -ForegroundColor Yellow
} else {
    # Install the device using devcon or pnputil
    # Note: Windows 10/11 doesn't have a built-in command-line tool to create ROOT devices
    # We'll try using the INF file directly
    Write-Host "      Installing device using driver..." -ForegroundColor Yellow

    # Try to force installation
    $installCmd = "pnputil /add-driver `"$infFile`" /install"
    Invoke-Expression $installCmd 2>&1 | Out-Null

    Write-Host "      Note: You may need to manually create the device in Device Manager" -ForegroundColor Yellow
    Write-Host "      or reboot the system for the device to appear automatically." -ForegroundColor Yellow
}

# Verify installation
Write-Host "[5/5] Verifying installation..." -ForegroundColor Yellow
$installedDriver = pnputil /enum-drivers | Select-String -Pattern "virtualaudiodriver" -Context 0,5
if ($installedDriver) {
    Write-Host "      Driver verified in driver store" -ForegroundColor Green
} else {
    Write-Host "WARNING: Driver not found in driver store verification" -ForegroundColor Yellow
}

# Check for audio devices
$audioDevices = Get-PnpDevice -Class "MEDIA" | Where-Object { $_.FriendlyName -like "*ISL*" }
if ($audioDevices) {
    Write-Host "      Virtual audio devices detected:" -ForegroundColor Green
    foreach ($device in $audioDevices) {
        Write-Host "        - $($device.FriendlyName) [$($device.Status)]" -ForegroundColor Cyan
    }
} else {
    Write-Host "      Note: No virtual audio devices detected yet" -ForegroundColor Yellow
    Write-Host "      The device may appear after a system reboot" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Process Completed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT NOTES:" -ForegroundColor Yellow
Write-Host "  1. The driver has been installed to the driver store" -ForegroundColor White
Write-Host "  2. For ROOT-enumerated devices like this virtual audio driver," -ForegroundColor White
Write-Host "     you may need to:" -ForegroundColor White
Write-Host "     - Reboot your computer, OR" -ForegroundColor White
Write-Host "     - Manually add hardware via Device Manager:" -ForegroundColor White
Write-Host "       a. Open Device Manager" -ForegroundColor White
Write-Host "       b. Select 'Action' > 'Add legacy hardware'" -ForegroundColor White
Write-Host "       c. Choose 'Install hardware manually'" -ForegroundColor White
Write-Host "       d. Select 'Sound, video and game controllers'" -ForegroundColor White
Write-Host "       e. Click 'Have Disk' and browse to: $infFile" -ForegroundColor White
Write-Host "       f. Select 'ISL Speaker' and click Next" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
