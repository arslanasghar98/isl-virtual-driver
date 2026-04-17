#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Uninstall CallJoyna Audio Driver

.DESCRIPTION
    Completely removes the CallJoyna Audio Driver and all associated devices.

.PARAMETER KeepDriverPackage
    Keep the driver package in the driver store (only remove device)

.EXAMPLE
    .\Uninstall-CallJoynaDriver.ps1

.EXAMPLE
    .\Uninstall-CallJoynaDriver.ps1 -KeepDriverPackage
#>

param(
    [switch]$KeepDriverPackage
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CallJoyna Audio Driver Uninstaller" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop audio service
Write-Host "[1/4] Stopping audio service..." -ForegroundColor Yellow
net stop audiosrv 2>$null

# Remove devices
Write-Host "[2/4] Removing devices..." -ForegroundColor Yellow
$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe"

# Remove by hardware ID
& $devcon remove "ROOT\VirtualAudioDriver" 2>$null

# Also remove any orphaned ROOT\MEDIA devices with CallJoyna
$devices = Get-PnpDevice -Class MEDIA | Where-Object { $_.FriendlyName -like "*CallJoyna*" }
foreach ($device in $devices) {
    Write-Host "      Removing $($device.InstanceId)..."
    & $devcon remove "@$($device.InstanceId)" 2>$null
    pnputil /remove-device "$($device.InstanceId)" 2>$null
}

# Remove from driver store
if (-not $KeepDriverPackage) {
    Write-Host "[3/4] Removing driver from store..." -ForegroundColor Yellow

    # Find all virtualaudiodriver packages
    $driverList = pnputil /enum-drivers
    $lines = $driverList -split "`n"
    $oemToRemove = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "virtualaudiodriver\.inf" -or $lines[$i] -match "CallJoyna") {
            # Search backwards for oem number
            for ($j = $i; $j -ge 0; $j--) {
                if ($lines[$j] -match "Published Name:\s+(oem\d+\.inf)") {
                    $oemToRemove += $Matches[1]
                    break
                }
            }
        }
    }

    $oemToRemove = $oemToRemove | Select-Object -Unique
    foreach ($oem in $oemToRemove) {
        Write-Host "      Removing $oem from driver store..."
        pnputil /delete-driver $oem /force 2>$null
    }

    if ($oemToRemove.Count -eq 0) {
        Write-Host "      No driver packages found in store" -ForegroundColor Gray
    }
} else {
    Write-Host "[3/4] Keeping driver package in store (as requested)" -ForegroundColor Yellow
}

# Restart audio service
Write-Host "[4/4] Restarting audio service..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
net start audiosrv

# Verify
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Uninstallation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if any CallJoyna devices remain
$remainingDevices = Get-PnpDevice -Class MEDIA | Where-Object { $_.FriendlyName -like "*CallJoyna*" }
if ($remainingDevices) {
    Write-Host "WARNING: Some devices still remain:" -ForegroundColor Red
    $remainingDevices | Format-Table FriendlyName, InstanceId, Status -AutoSize
} else {
    Write-Host "All CallJoyna devices removed successfully" -ForegroundColor Green
}

# Check driver store
$remainingDriver = pnputil /enum-drivers | Select-String "CallJoyna|virtualaudiodriver"
if ($remainingDriver -and -not $KeepDriverPackage) {
    Write-Host "WARNING: Driver package may still be in store" -ForegroundColor Red
} else {
    Write-Host "Driver store cleaned" -ForegroundColor Green
}
