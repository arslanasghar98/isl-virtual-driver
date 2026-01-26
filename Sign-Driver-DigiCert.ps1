#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Signs the Virtual Audio Driver using DigiCert KeyLocker

.DESCRIPTION
    This script signs the driver files (.sys and .cat) using DigiCert KeyLocker
    with your EV code signing certificate.

.NOTES
    Prerequisites:
    1. DigiCert KeyLocker Tools installed (SMCTL + KSP)
    2. API credentials configured in DigiCert ONE
    3. Certificate synced to Windows store
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [Parameter()]
    [ValidateSet("x64", "ARM64")]
    [string]$Platform = "x64"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DigiCert KeyLocker Driver Signing"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# CONFIGURATION - UPDATE THESE VALUES
# ============================================================================
$KeypairAlias = "key_1435973180"  # DigiCert KeyLocker keypair alias

# Certificate paths
$CertificateFile = "E:\Downloads\Insurance Sales Lab (ZipCeleb LLC).pem"
$IntermediateCert = "E:\Downloads\DigiCert Trusted G4 Code Signing RSA4096 SHA384 2021 CA1.pem"
$RootCert = "E:\Downloads\DigiCert Trusted Root G4.pem"

# Timestamp server
$TimestampServer = "http://timestamp.digicert.com"

# ============================================================================
# PATHS
# ============================================================================
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$driverPath = Join-Path $scriptDir "$Platform\$Configuration"
$sysFile = Join-Path $driverPath "virtualaudiodriver.sys"
$infFile = Join-Path $driverPath "VirtualAudioDriver.inf"
$catFile = Join-Path $driverPath "VirtualAudioDriver.cat"

Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Platform: $Platform" -ForegroundColor Yellow
Write-Host "Driver Path: $driverPath" -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# Step 1: Verify DigiCert Tools
# ============================================================================
Write-Host "[1/7] Checking DigiCert KeyLocker Tools..." -ForegroundColor Yellow

$smctl = Get-Command smctl -ErrorAction SilentlyContinue
if (-not $smctl) {
    $smctlPath = "C:\Program Files\DigiCert\DigiCert KeyLocker Tools\smctl.exe"
    if (Test-Path $smctlPath) {
        $env:PATH += ";C:\Program Files\DigiCert\DigiCert KeyLocker Tools"
    } else {
        throw "SMCTL not found. Please install DigiCert KeyLocker Tools from DigiCert ONE portal."
    }
}
Write-Host "      SMCTL found" -ForegroundColor Green

# ============================================================================
# Step 2: Locate Windows SDK Tools
# ============================================================================
Write-Host "[2/7] Locating Windows SDK tools..." -ForegroundColor Yellow

$signtool = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" `
    -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*\x64\*" } |
    Sort-Object { $_.Directory.Name } -Descending |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $signtool) {
    throw "signtool.exe not found. Please install Windows SDK."
}
Write-Host "      SignTool: $signtool" -ForegroundColor Green

$inf2cat = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" `
    -Recurse -Filter inf2cat.exe -ErrorAction SilentlyContinue |
    Sort-Object { $_.Directory.Name } -Descending |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $inf2cat) {
    throw "inf2cat.exe not found. Please install WDK."
}
Write-Host "      Inf2Cat: $inf2cat" -ForegroundColor Green

# ============================================================================
# Step 3: Verify Driver Files
# ============================================================================
Write-Host "[3/7] Verifying driver files..." -ForegroundColor Yellow

if (-not (Test-Path $sysFile)) {
    throw "Driver file not found: $sysFile`nRun build.bat first!"
}
if (-not (Test-Path $infFile)) {
    throw "INF file not found: $infFile"
}
Write-Host "      Driver files verified" -ForegroundColor Green

# ============================================================================
# Step 4: Check DigiCert Credentials
# ============================================================================
Write-Host "[4/7] Checking DigiCert credentials..." -ForegroundColor Yellow

$healthCheck = & smctl healthcheck 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "DigiCert credentials not configured!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run these commands first:" -ForegroundColor Yellow
    Write-Host "  smctl credentials save <API_TOKEN> <CLIENT_CERT_PASSWORD>" -ForegroundColor White
    Write-Host ""
    Write-Host "Get your API token from: DigiCert ONE -> Account -> API Tokens" -ForegroundColor Gray
    throw "DigiCert credentials not configured"
}
Write-Host "      Credentials verified" -ForegroundColor Green

# ============================================================================
# Step 5: Sync Certificate to Windows Store
# ============================================================================
Write-Host "[5/7] Syncing certificate to Windows store..." -ForegroundColor Yellow

if ($KeypairAlias -eq "YOUR_KEYPAIR_ALIAS") {
    Write-Host ""
    Write-Host "ERROR: Keypair alias not configured!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please edit this script and set your KeypairAlias value." -ForegroundColor Yellow
    Write-Host "Find it in: DigiCert ONE -> Certificates -> Your cert -> Keypair alias" -ForegroundColor Gray
    Write-Host ""
    throw "Keypair alias not configured"
}

& smctl windows certsync --keypair-alias=$KeypairAlias
if ($LASTEXITCODE -ne 0) {
    throw "Failed to sync certificate to Windows store"
}
Write-Host "      Certificate synced" -ForegroundColor Green

# Get the certificate thumbprint from the synced certificate
$cert = Get-ChildItem Cert:\CurrentUser\My |
    Where-Object { $_.Subject -like "*Insurance Sales Lab*" -or $_.Subject -like "*ZipCeleb*" } |
    Select-Object -First 1

if (-not $cert) {
    # Try LocalMachine store
    $cert = Get-ChildItem Cert:\LocalMachine\My |
        Where-Object { $_.Subject -like "*Insurance Sales Lab*" -or $_.Subject -like "*ZipCeleb*" } |
        Select-Object -First 1
}

if (-not $cert) {
    throw "Could not find synced certificate in Windows store"
}

$thumbprint = $cert.Thumbprint
Write-Host "      Certificate Thumbprint: $thumbprint" -ForegroundColor Green

# ============================================================================
# Step 6: Create Catalog File
# ============================================================================
Write-Host "[6/7] Creating catalog file..." -ForegroundColor Yellow

if (Test-Path $catFile) {
    Remove-Item $catFile -Force
}

$osParam = if ($Platform -eq "ARM64") { "10_ARM64" } else { "10_X64" }

& $inf2cat /driver:"$driverPath" /os:$osParam /uselocaltime 2>&1

if (-not (Test-Path $catFile)) {
    Write-Host "      Warning: Catalog file was not created by inf2cat" -ForegroundColor Yellow
    Write-Host "      Attempting to sign SYS file directly..." -ForegroundColor Yellow
}
else {
    Write-Host "      Catalog created" -ForegroundColor Green
}

# ============================================================================
# Step 7: Sign Driver Files
# ============================================================================
Write-Host "[7/7] Signing driver files..." -ForegroundColor Yellow

# Sign the SYS file
Write-Host "      Signing SYS file..." -ForegroundColor Gray
& $signtool sign `
    /sha1 $thumbprint `
    /tr $TimestampServer `
    /td SHA256 `
    /fd SHA256 `
    /v `
    "$sysFile"

if ($LASTEXITCODE -ne 0) {
    throw "Failed to sign SYS file"
}
Write-Host "      SYS file signed" -ForegroundColor Green

# Sign the CAT file if it exists
if (Test-Path $catFile) {
    Write-Host "      Signing CAT file..." -ForegroundColor Gray
    & $signtool sign `
        /sha1 $thumbprint `
        /tr $TimestampServer `
        /td SHA256 `
        /fd SHA256 `
        /v `
        "$catFile"

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to sign CAT file"
    }
    Write-Host "      CAT file signed" -ForegroundColor Green
}

# ============================================================================
# Verify Signatures
# ============================================================================
Write-Host ""
Write-Host "Verifying signatures..." -ForegroundColor Yellow

Write-Host "      SYS file:" -ForegroundColor Gray
& $signtool verify /pa /v "$sysFile"

if (Test-Path $catFile) {
    Write-Host ""
    Write-Host "      CAT file:" -ForegroundColor Gray
    & $signtool verify /pa /v "$catFile"
}

# ============================================================================
# Done
# ============================================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DRIVER SIGNING COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Signed files:" -ForegroundColor Yellow
Write-Host "  $sysFile" -ForegroundColor White
if (Test-Path $catFile) {
    Write-Host "  $catFile" -ForegroundColor White
}
Write-Host ""
Write-Host "Your driver is now signed with a trusted DigiCert certificate." -ForegroundColor Green
Write-Host "No test mode required for installation!" -ForegroundColor Green
Write-Host ""
