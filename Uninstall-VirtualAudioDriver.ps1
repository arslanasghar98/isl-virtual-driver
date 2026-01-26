#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Uninstallation script for Virtual Audio Driver

.DESCRIPTION
    This script uninstalls the Virtual Audio Driver (ISL Speaker/Mic) completely.
    It requires administrator privileges.

.EXAMPLE
    .\Uninstall-VirtualAudioDriver.ps1
#>

[CmdletBinding()]
param()

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Virtual Audio Driver Uninstallation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find and remove devices
Write-Host "[1/3] Removing virtual audio devices..." -ForegroundColor Yellow
$audioDevices = Get-PnpDevice -Class "MEDIA" | Where-Object { $_.FriendlyName -like "*ISL*" }
if ($audioDevices) {
    foreach ($device in $audioDevices) {
        Write-Host "      Removing device: $($device.FriendlyName)" -ForegroundColor Yellow
        try {
            $device | Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue
            Remove-PnpDevice -InstanceId $device.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "      Device removed successfully" -ForegroundColor Green
        } catch {
            Write-Host "      Warning: Could not remove device automatically" -ForegroundColor Yellow
            Write-Host "      You may need to remove it manually from Device Manager" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "      No virtual audio devices found" -ForegroundColor Green
}

# Find the driver in driver store
Write-Host "[2/3] Finding driver in driver store..." -ForegroundColor Yellow
$driverInfo = pnputil /enum-drivers | Select-String -Pattern "virtualaudiodriver" -Context 0,10

if ($driverInfo) {
    # Extract the OEM*.inf filename
    $publishedName = ($driverInfo | Select-String -Pattern "Published Name.*oem\d+\.inf").Matches.Value
    if ($publishedName -match "oem\d+\.inf") {
        $oeminf = $matches[0]
        Write-Host "      Found driver: $oeminf" -ForegroundColor Green

        # Uninstall the driver
        Write-Host "[3/3] Removing driver from driver store..." -ForegroundColor Yellow
        $uninstallResult = pnputil /delete-driver $oeminf /uninstall /force 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "      Driver removed successfully" -ForegroundColor Green
        } else {
            Write-Host "      Error removing driver" -ForegroundColor Red
            Write-Host $uninstallResult -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "      Warning: Could not parse driver published name" -ForegroundColor Yellow
    }
} else {
    Write-Host "      Driver not found in driver store" -ForegroundColor Yellow
    Write-Host "[3/3] Nothing to remove" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Uninstallation Completed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The Virtual Audio Driver has been removed from your system." -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
