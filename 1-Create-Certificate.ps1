#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Creates and installs a self-signed kernel-mode driver signing certificate
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kernel Driver Certificate Installation"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$certSubject = "CN=VirtualAudioDriver Self-Signed Certificate"
$certName    = "VirtualAudioDriver Kernel Test Certificate"
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$pfxPath     = Join-Path $scriptDir "VirtualAudioDriver.pfx"
$cerPath     = Join-Path $scriptDir "VirtualAudioDriver.cer"
$password    = ConvertTo-SecureString "test" -AsPlainText -Force

# Cleanup old certs
Write-Host "[1/6] Removing old certificates..." -ForegroundColor Yellow
Get-ChildItem Cert:\LocalMachine\My |
    Where-Object { $_.Subject -eq $certSubject } |
    Remove-Item -Force

# Create cert (with BOTH EKUs)
Write-Host "[2/6] Creating certificate..." -ForegroundColor Yellow
$cert = New-SelfSignedCertificate `
    -Subject $certSubject `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -KeySpec Signature `
    -KeyUsage DigitalSignature `
    -KeyExportPolicy Exportable `
    -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -FriendlyName $certName `
    -NotAfter (Get-Date).AddYears(5) `
    -TextExtension @(
        "2.5.29.37={text}1.3.6.1.5.5.7.3.3,1.3.6.1.4.1.311.61.1.1"
    )

Write-Host "      Thumbprint: $($cert.Thumbprint)" -ForegroundColor Green

# Export cert properly
Write-Host "[3/6] Exporting certificate..." -ForegroundColor Yellow
Export-PfxCertificate `
    -Cert $cert `
    -FilePath $pfxPath `
    -Password $password `
    -Force | Out-Null

Export-Certificate `
    -Cert $cert `
    -FilePath $cerPath `
    -Force | Out-Null

# Re-import PFX (CRITICAL STEP)
Write-Host "[4/6] Importing certificate correctly..." -ForegroundColor Yellow
Import-PfxCertificate `
    -FilePath $pfxPath `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $password `
    -Exportable | Out-Null

# Install trust
Write-Host "[5/6] Installing to Trusted Root..." -ForegroundColor Yellow
Import-Certificate `
    -FilePath $cerPath `
    -CertStoreLocation Cert:\LocalMachine\Root | Out-Null

Write-Host "[6/6] Installing to Trusted Publishers..." -ForegroundColor Yellow
Import-Certificate `
    -FilePath $cerPath `
    -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CERTIFICATE FULLY INSTALLED & TRUSTED"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "NEXT:"
Write-Host "  Enable test mode (required):" -ForegroundColor Yellow
Write-Host "  bcdedit /set testsigning on"
Write-Host ""
Pause
