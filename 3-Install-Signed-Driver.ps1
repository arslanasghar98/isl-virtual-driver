#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs a self-signed kernel-mode driver (Test Mode required)
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Virtual Audio Driver Installation"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------
# Check Test Mode
# ------------------------------------------------------------------
Write-Host "[1/5] Checking Test Mode..." -ForegroundColor Yellow
$testMode = (bcdedit | Select-String "testsigning").ToString()

if ($testMode -notmatch "Yes") {
    Write-Host "ERROR: Test Mode is NOT enabled." -ForegroundColor Red
    Write-Host "Self-signed kernel drivers REQUIRE Test Mode." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Enable it with:" -ForegroundColor Yellow
    Write-Host "  bcdedit /set testsigning on" -ForegroundColor White
    exit 1
}

Write-Host "      Test Mode is enabled" -ForegroundColor Green

# ------------------------------------------------------------------
# Paths
# ------------------------------------------------------------------
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$driverPath = Join-Path $scriptDir "x64\Debug"
$infFile    = Join-Path $driverPath "VirtualAudioDriver.inf"

if (-not (Test-Path $infFile)) {
    throw "INF file not found: $infFile"
}

# ------------------------------------------------------------------
# Remove existing driver
# ------------------------------------------------------------------
Write-Host "[2/5] Removing existing driver (if any)..." -ForegroundColor Yellow
pnputil /enum-drivers |
    Select-String "virtualaudiodriver" -Context 0,5 |
    ForEach-Object {
        if ($_ -match "oem\d+\.inf") {
            $oem = $matches[0]
            pnputil /delete-driver $oem /uninstall /force
        }
    }

# ------------------------------------------------------------------
# Install driver
# ------------------------------------------------------------------
Write-Host "[3/5] Installing driver..." -ForegroundColor Yellow
pnputil /add-driver "$infFile" /install

# ------------------------------------------------------------------
# Verify
# ------------------------------------------------------------------
Write-Host "[4/5] Verifying installation..." -ForegroundColor Yellow
pnputil /enum-drivers | Select-String "virtualaudiodriver" | Out-Host

Write-Host ""
Write-Host "[5/5] Done." -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "INSTALLATION COMPLETE"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "If the device does not appear immediately:" -ForegroundColor Yellow
Write-Host "  → Reboot the system" -ForegroundColor White
Write-Host ""
Pause
