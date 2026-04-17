#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Install CallJoyna Audio Driver

.DESCRIPTION
    Signs and installs the CallJoyna Audio Driver.
    Creates virtual audio devices: CallJoyna Speaker and CallJoyna Mic.

.PARAMETER SkipSigning
    Skip the signing step (use if driver is already signed)

.EXAMPLE
    .\Install-CallJoynaDriver.ps1

.EXAMPLE
    .\Install-CallJoynaDriver.ps1 -SkipSigning
#>

param(
    [switch]$SkipSigning
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$driverPath = Join-Path $scriptDir "x64\Release"
$infFile = Join-Path $driverPath "VirtualAudioDriver.inf"
$sysFile = Join-Path $driverPath "virtualaudiodriver.sys"
$catFile = Join-Path $driverPath "virtualaudiodriver.cat"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CallJoyna Audio Driver Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verify files exist
if (-not (Test-Path $sysFile)) {
    throw "Driver file not found: $sysFile`nRun build.bat first!"
}
if (-not (Test-Path $infFile)) {
    throw "INF file not found: $infFile"
}

# Signing
if (-not $SkipSigning) {
    Write-Host "[1/5] Syncing DigiCert certificate..." -ForegroundColor Yellow
    smctl windows certsync --keypair-alias key_1435973180

    Write-Host "[2/5] Creating catalog file..." -ForegroundColor Yellow
    $inf2cat = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\inf2cat.exe"
    & $inf2cat /driver:"$driverPath" /os:10_X64 /uselocaltime

    Write-Host "[3/5] Signing driver files..." -ForegroundColor Yellow
    $signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
    $thumbprint = "a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b"

    & $signtool sign /tr http://timestamp.digicert.com /td SHA256 /fd SHA256 /sha1 $thumbprint $sysFile
    & $signtool sign /tr http://timestamp.digicert.com /td SHA256 /fd SHA256 /sha1 $thumbprint $catFile

    Write-Host "      Signatures verified" -ForegroundColor Green
} else {
    Write-Host "[1-3/5] Skipping signing (already signed)" -ForegroundColor Yellow
}

# Remove existing device if any
Write-Host "[4/5] Installing driver..." -ForegroundColor Yellow
$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe"

# Remove old devices
& $devcon remove "ROOT\VirtualAudioDriver" 2>$null

# Install
$result = & $devcon install $infFile "ROOT\VirtualAudioDriver" 2>&1
Write-Host $result

# Restart audio service
Write-Host "[5/5] Restarting audio service..." -ForegroundColor Yellow
net stop audiosrv 2>$null
Start-Sleep -Seconds 2
net start audiosrv

# Verify
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$device = Get-PnpDevice -Class MEDIA | Where-Object { $_.FriendlyName -like "*CallJoyna*" }
if ($device) {
    Write-Host "Installed devices:" -ForegroundColor Yellow
    $device | Format-Table FriendlyName, Status -AutoSize

    $driver = pnputil /enum-drivers | Select-String "CallJoyna" -Context 1,3
    Write-Host "Driver info:" -ForegroundColor Yellow
    Write-Host $driver
} else {
    Write-Host "WARNING: Device not found after installation" -ForegroundColor Red
}

Write-Host ""
Write-Host "Open Windows Sound Settings to verify:" -ForegroundColor Cyan
Write-Host "  - Recording: CallJoyna Mic" -ForegroundColor White
Write-Host "  - Playback: CallJoyna Speaker" -ForegroundColor White
