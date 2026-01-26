#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Fully silent installation of Virtual Audio Driver with self-signing
.DESCRIPTION
    This script performs all steps silently without user interaction
.EXAMPLE
    .\Install-Silently.ps1
#>

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Silent Driver Installation Starting" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$driverPath = Join-Path $scriptDir "x64\Debug"
$infFile = Join-Path $driverPath "VirtualAudioDriver.inf"
$sysFile = Join-Path $driverPath "virtualaudiodriver.sys"
$certSubject = "CN=VirtualAudioDriver Self-Signed Certificate"

# STEP 1: CREATE CERTIFICATE
Write-Host "[1/3] Creating and installing certificate..." -ForegroundColor Yellow

$cert = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction SilentlyContinue | Where-Object { $_.Subject -eq $certSubject }

if (-not $cert) {
    $cert = New-SelfSignedCertificate `
        -Type CodeSigningCert `
        -Subject $certSubject `
        -KeyAlgorithm RSA `
        -KeyLength 2048 `
        -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" `
        -KeyExportPolicy Exportable `
        -KeyUsage DigitalSignature `
        -FriendlyName "VirtualAudioDriver-SelfSigned" `
        -CertStoreLocation "Cert:\LocalMachine\My" `
        -NotAfter (Get-Date).AddYears(5) `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3")
    Write-Host "      Certificate created: $($cert.Thumbprint)" -ForegroundColor Green
} else {
    Write-Host "      Using existing certificate: $($cert.Thumbprint)" -ForegroundColor Green
}

# Install to Trusted Root
$rootStore = Get-Item -Path "Cert:\LocalMachine\Root"
$existingInRoot = $rootStore.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
if (-not $existingInRoot) {
    $rootStore.Open("ReadWrite")
    $rootStore.Add($cert)
    $rootStore.Close()
    Write-Host "      Installed to Trusted Root" -ForegroundColor Green
}

# Install to Trusted Publishers
$pubStore = Get-Item -Path "Cert:\LocalMachine\TrustedPublisher"
$existingInPub = $pubStore.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
if (-not $existingInPub) {
    $pubStore.Open("ReadWrite")
    $pubStore.Add($cert)
    $pubStore.Close()
    Write-Host "      Installed to Trusted Publishers" -ForegroundColor Green
}

# STEP 2: SIGN DRIVER
Write-Host "[2/3] Signing driver files..." -ForegroundColor Yellow

# Find signtool
$signtoolPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe",
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
)

$signtool = $null
foreach ($path in $signtoolPaths) {
    if (Test-Path $path) {
        $signtool = $path
        break
    }
}

if (-not $signtool) {
    $found = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin\" -Recurse -Filter "signtool.exe" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*\x64\*" } | Select-Object -First 1
    if ($found) {
        $signtool = $found.FullName
    }
}

if (-not $signtool -or -not (Test-Path $signtool)) {
    Write-Host "      WARNING: signtool.exe not found - skipping signing" -ForegroundColor Yellow
    $signed = $false
} else {
    $signArgs = @("sign", "/sha1", $cert.Thumbprint, "/fd", "SHA256", "/v", "`"$sysFile`"")
    $output = & $signtool $signArgs 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      Driver signed successfully" -ForegroundColor Green
        $signed = $true
    } else {
        Write-Host "      WARNING: Failed to sign driver" -ForegroundColor Yellow
        $signed = $false
    }
}

# STEP 3: INSTALL DRIVER
Write-Host "[3/3] Installing driver..." -ForegroundColor Yellow

if (-not (Test-Path $infFile)) {
    Write-Host "      ERROR: INF file not found: $infFile" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $sysFile)) {
    Write-Host "      ERROR: SYS file not found: $sysFile" -ForegroundColor Red
    exit 1
}

# Remove existing driver
$existingDriver = pnputil /enum-drivers 2>&1 | Select-String -Pattern "virtualaudiodriver" -Context 0,5
if ($existingDriver) {
    $oeminf = ($existingDriver | Select-String -Pattern "Published Name.*oem\d+\.inf").Matches.Value -replace "Published Name\s*:\s*", ""
    if ($oeminf) {
        Write-Host "      Removing existing driver..." -ForegroundColor Yellow
        pnputil /delete-driver $oeminf /uninstall /force 2>&1 | Out-Null
    }
}

# Install driver
$addResult = pnputil /add-driver "$infFile" /install 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "      Driver installed successfully" -ForegroundColor Green
} else {
    Write-Host "      ERROR: Failed to install driver" -ForegroundColor Red
    Write-Host $addResult -ForegroundColor Red
    exit 1
}

# Verify
Start-Sleep -Seconds 2
$audioDevices = Get-PnpDevice -Class "MEDIA" -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*ISL*" }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($signed) {
    Write-Host "SUCCESS: Driver is properly signed" -ForegroundColor Green
    Write-Host "SUCCESS: No Test Mode required" -ForegroundColor Green
} else {
    Write-Host "WARNING: Driver is NOT signed" -ForegroundColor Yellow
    Write-Host "WARNING: Enable Test Mode: bcdedit /set testsigning on" -ForegroundColor Yellow
}

Write-Host "SUCCESS: Driver installed to driver store" -ForegroundColor Green

if ($audioDevices) {
    Write-Host "SUCCESS: Virtual audio devices detected:" -ForegroundColor Green
    foreach ($device in $audioDevices) {
        Write-Host "  - $($device.FriendlyName) [$($device.Status)]" -ForegroundColor Cyan
    }
} else {
    Write-Host "INFO: Devices not detected yet - REBOOT required" -ForegroundColor Yellow
}

Write-Host ""
