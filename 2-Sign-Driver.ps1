#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Creates and signs a kernel-mode driver catalog using a self-signed certificate
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kernel Driver Signing"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Paths
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$driverPath = Join-Path $scriptDir "x64\Debug"
$sysFile    = Join-Path $driverPath "virtualaudiodriver.sys"
$infFile    = Join-Path $driverPath "VirtualAudioDriver.inf"
$catFile    = Join-Path $driverPath "VirtualAudioDriver.cat"

# --------------------------------------------------------------------
# Locate signtool
# --------------------------------------------------------------------
Write-Host "[1/6] Locating signtool..." -ForegroundColor Yellow
$signtool = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" `
    -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*\x64\*" } |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $signtool) {
    throw "signtool.exe not found"
}
Write-Host "      Found: $signtool" -ForegroundColor Green

# --------------------------------------------------------------------
# Locate inf2cat
# --------------------------------------------------------------------
Write-Host "[2/6] Locating inf2cat..." -ForegroundColor Yellow
$inf2cat = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" `
    -Recurse -Filter inf2cat.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $inf2cat) {
    throw "inf2cat.exe not found"
}
Write-Host "      Found: $inf2cat" -ForegroundColor Green

# --------------------------------------------------------------------
# Verify driver files
# --------------------------------------------------------------------
Write-Host "[3/6] Verifying driver files..." -ForegroundColor Yellow
foreach ($file in @($sysFile, $infFile)) {
    if (-not (Test-Path $file)) {
        throw "Missing file: $file"
    }
}
Write-Host "      Files verified" -ForegroundColor Green

# --------------------------------------------------------------------
# Find certificate
# --------------------------------------------------------------------
Write-Host "[4/6] Finding signing certificate..." -ForegroundColor Yellow
$cert = Get-ChildItem Cert:\LocalMachine\My |
    Where-Object { $_.Subject -eq "CN=VirtualAudioDriver Self-Signed Certificate" }

if (-not $cert) {
    throw "Signing certificate not found"
}

Write-Host "      Using cert: $($cert.Thumbprint)" -ForegroundColor Green

# --------------------------------------------------------------------
# Create catalog
# --------------------------------------------------------------------
Write-Host "[5/6] Creating catalog..." -ForegroundColor Yellow
if (Test-Path $catFile) {
    Remove-Item $catFile -Force
}

& $inf2cat `
    /driver:"$driverPath" `
    /os:10_X64 `
    /uselocaltime

if (-not (Test-Path $catFile)) {
    throw "Catalog file was not created"
}

Write-Host "      Catalog created" -ForegroundColor Green

# --------------------------------------------------------------------
# SIGN CATALOG  (CRITICAL: /sm flag)
# --------------------------------------------------------------------
Write-Host "[6/6] Signing catalog..." -ForegroundColor Yellow
& $signtool sign `
    /sm `
    /sha1 $cert.Thumbprint `
    /fd SHA256 `
    /v `
    "$catFile"

if ($LASTEXITCODE -ne 0) {
    throw "Catalog signing failed"
}

Write-Host "      Catalog signed successfully" -ForegroundColor Green

# --------------------------------------------------------------------
# OPTIONAL: Sign SYS
# --------------------------------------------------------------------
Write-Host ""
Write-Host "Signing SYS (optional)..." -ForegroundColor Yellow
& $signtool sign `
    /sm `
    /sha1 $cert.Thumbprint `
    /fd SHA256 `
    /v `
    "$sysFile"

# --------------------------------------------------------------------
# Verify kernel signature
# --------------------------------------------------------------------
Write-Host ""
Write-Host "Verifying kernel signature..." -ForegroundColor Yellow
& $signtool verify /kp /v "$catFile"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DRIVER SIGNING COMPLETE"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT:"
Write-Host "  Self-signed drivers REQUIRE test mode:" -ForegroundColor Yellow
Write-Host "  bcdedit /set testsigning on"
Write-Host ""
Pause
