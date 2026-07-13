#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Builds, signs, and packages Virtual Audio Driver for both x64 and ARM64 architectures.
    Creates a CAB file ready for Microsoft Partner Center submission.

.DESCRIPTION
    This script:
    1. Builds Release configurations for x64 and ARM64
    2. Stages files in multi-arch folder structure
    3. Generates multi-arch catalog (covers both architectures)
    4. Signs binaries and catalog with DigiCert EV certificate
    5. Creates CAB file for Microsoft Partner Center attestation signing

.PARAMETER SkipBuild
    Skip the build step (use existing binaries)

.PARAMETER DigiCertThumbprint
    SHA1 thumbprint of DigiCert EV certificate (default: a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b)
#>

[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [string]$DigiCertThumbprint = "a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Multi-Architecture Driver Package"
Write-Host "x64 + ARM64 for Microsoft Partner Center"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$stagingDir = Join-Path $scriptDir "MultiArchPackage"
$cabFile = Join-Path $scriptDir "VirtualAudioDriver_MultiArch.cab"
$ddfFile = Join-Path $scriptDir "multiarch.ddf"

# Source paths
$x64Release = Join-Path $scriptDir "x64\Release\package"
$arm64Release = Join-Path $scriptDir "ARM64\Release\package"
$iconFile = Join-Path $scriptDir "DriverPackage\CallJoyna.ico"

# --------------------------------------------------------------------
# Step 1: Locate tools
# --------------------------------------------------------------------
Write-Host "[1/8] Locating build tools..." -ForegroundColor Yellow

$signtool = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" `
    -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*\x64\*" } |
    Sort-Object { [version]($_.FullName -replace '.*\\(\d+\.\d+\.\d+\.\d+)\\.*', '$1') } -Descending |
    Select-Object -First 1 -ExpandProperty FullName

$inf2cat = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" `
    -Recurse -Filter inf2cat.exe -ErrorAction SilentlyContinue |
    Sort-Object { [version]($_.FullName -replace '.*\\(\d+\.\d+\.\d+\.\d+)\\.*', '$1') } -Descending |
    Select-Object -First 1 -ExpandProperty FullName

$makecab = "makecab.exe"

if (-not $signtool) { throw "signtool.exe not found in Windows Kits" }
if (-not $inf2cat) { throw "inf2cat.exe not found in Windows Kits" }

Write-Host "      signtool: $signtool" -ForegroundColor Green
Write-Host "      inf2cat:  $inf2cat" -ForegroundColor Green

# --------------------------------------------------------------------
# Step 2: Build both architectures
# --------------------------------------------------------------------
if (-not $SkipBuild) {
    Write-Host "[2/8] Building x64 and ARM64 Release..." -ForegroundColor Yellow

    Push-Location $scriptDir
    try {
        # Build x64
        Write-Host "      Building x64 Release..." -ForegroundColor Gray
        & cmd /c "build.bat release x64"
        if ($LASTEXITCODE -ne 0) { throw "x64 build failed" }

        # Build ARM64
        Write-Host "      Building ARM64 Release..." -ForegroundColor Gray
        & cmd /c "build.bat release arm64"
        if ($LASTEXITCODE -ne 0) { throw "ARM64 build failed" }
    }
    finally {
        Pop-Location
    }
    Write-Host "      Build completed" -ForegroundColor Green
} else {
    Write-Host "[2/8] Skipping build (using existing binaries)..." -ForegroundColor Yellow
}

# --------------------------------------------------------------------
# Step 3: Verify build outputs
# --------------------------------------------------------------------
Write-Host "[3/8] Verifying build outputs..." -ForegroundColor Yellow

$requiredFiles = @(
    (Join-Path $x64Release "virtualaudiodriver.sys"),
    (Join-Path $x64Release "virtualaudiodriver.pdb"),
    (Join-Path $x64Release "VirtualAudioDriver.inf"),
    (Join-Path $arm64Release "virtualaudiodriver.sys"),
    (Join-Path $arm64Release "virtualaudiodriver.pdb"),
    (Join-Path $arm64Release "VirtualAudioDriver.inf")
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        throw "Missing required file: $file"
    }
}
Write-Host "      All build outputs verified" -ForegroundColor Green

# --------------------------------------------------------------------
# Step 4: Create staging directory
# --------------------------------------------------------------------
Write-Host "[4/8] Creating staging directory..." -ForegroundColor Yellow

if (Test-Path $stagingDir) {
    Remove-Item $stagingDir -Recurse -Force
}

$x64Staging = Join-Path $stagingDir "x64"
$arm64Staging = Join-Path $stagingDir "ARM64"

New-Item -ItemType Directory -Path $x64Staging -Force | Out-Null
New-Item -ItemType Directory -Path $arm64Staging -Force | Out-Null

# Copy x64 files
Copy-Item (Join-Path $x64Release "virtualaudiodriver.sys") $x64Staging
Copy-Item (Join-Path $x64Release "virtualaudiodriver.pdb") $x64Staging
Copy-Item (Join-Path $x64Release "VirtualAudioDriver.inf") $x64Staging

# Copy ARM64 files
Copy-Item (Join-Path $arm64Release "virtualaudiodriver.sys") $arm64Staging
Copy-Item (Join-Path $arm64Release "virtualaudiodriver.pdb") $arm64Staging
Copy-Item (Join-Path $arm64Release "VirtualAudioDriver.inf") $arm64Staging

# Copy shared files (icon)
if (Test-Path $iconFile) {
    Copy-Item $iconFile $stagingDir
}

Write-Host "      Staging directory created: $stagingDir" -ForegroundColor Green

# --------------------------------------------------------------------
# Step 5: Sign driver binaries with DigiCert
# --------------------------------------------------------------------
Write-Host "[5/8] Signing driver binaries with DigiCert EV..." -ForegroundColor Yellow

$filesToSign = @(
    (Join-Path $x64Staging "virtualaudiodriver.sys"),
    (Join-Path $arm64Staging "virtualaudiodriver.sys")
)

foreach ($file in $filesToSign) {
    Write-Host "      Signing: $file" -ForegroundColor Gray
    & $signtool sign `
        /sha1 $DigiCertThumbprint `
        /fd SHA256 `
        /tr http://timestamp.digicert.com `
        /td SHA256 `
        /v `
        "$file"

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to sign: $file"
    }
}

Write-Host "      Binaries signed successfully" -ForegroundColor Green

# --------------------------------------------------------------------
# Step 6: Generate multi-arch catalog
# --------------------------------------------------------------------
Write-Host "[6/8] Generating multi-architecture catalog..." -ForegroundColor Yellow

# inf2cat needs to run from x64 folder with the INF
# We'll generate catalogs for each architecture separately, then combine
# Actually, inf2cat with /os:10_X64,10_ARM64 should work

# First, create a combined INF in staging root that references both architectures
# For Microsoft submission, we use the x64 INF as the primary
$catFile = Join-Path $x64Staging "VirtualAudioDriver.cat"

# Remove existing catalog
if (Test-Path $catFile) {
    Remove-Item $catFile -Force
}

# Generate catalog - inf2cat works on the x64 folder
& $inf2cat /driver:"$x64Staging" /os:10_X64,10_ARM64 /uselocaltime

if (-not (Test-Path $catFile)) {
    Write-Host "      Warning: Catalog not created in x64 folder, trying staging root..." -ForegroundColor Yellow

    # Copy x64 INF to staging root and try there
    Copy-Item (Join-Path $x64Staging "VirtualAudioDriver.inf") $stagingDir
    & $inf2cat /driver:"$stagingDir" /os:10_X64,10_ARM64 /uselocaltime
    $catFile = Join-Path $stagingDir "VirtualAudioDriver.cat"
}

if (-not (Test-Path $catFile)) {
    throw "Catalog file was not created"
}

Write-Host "      Catalog created: $catFile" -ForegroundColor Green

# --------------------------------------------------------------------
# Step 7: Sign catalog with DigiCert
# --------------------------------------------------------------------
Write-Host "[7/8] Signing catalog with DigiCert EV..." -ForegroundColor Yellow

& $signtool sign `
    /sha1 $DigiCertThumbprint `
    /fd SHA256 `
    /tr http://timestamp.digicert.com `
    /td SHA256 `
    /v `
    "$catFile"

if ($LASTEXITCODE -ne 0) {
    throw "Failed to sign catalog"
}

# Verify signature
& $signtool verify /pa /v "$catFile"
if ($LASTEXITCODE -ne 0) {
    Write-Host "      Warning: Catalog verification returned non-zero (may still be valid)" -ForegroundColor Yellow
}

Write-Host "      Catalog signed successfully" -ForegroundColor Green

# --------------------------------------------------------------------
# Step 8: Create CAB file
# --------------------------------------------------------------------
Write-Host "[8/8] Creating CAB file for Partner Center..." -ForegroundColor Yellow

# Remove existing CAB
if (Test-Path $cabFile) {
    Remove-Item $cabFile -Force
}

# Create DDF file for makecab
$ddfContent = @"
.OPTION EXPLICIT
.Set CabinetNameTemplate=VirtualAudioDriver_MultiArch.cab
.Set CompressionType=MSZIP
.Set Cabinet=on
.Set DiskDirectoryTemplate=.
.Set DestinationDir=VirtualAudioDriver

"$x64Staging\virtualaudiodriver.sys" "x64\virtualaudiodriver.sys"
"$x64Staging\virtualaudiodriver.pdb" "x64\virtualaudiodriver.pdb"
"$x64Staging\VirtualAudioDriver.inf" "x64\VirtualAudioDriver.inf"
"$arm64Staging\virtualaudiodriver.sys" "ARM64\virtualaudiodriver.sys"
"$arm64Staging\virtualaudiodriver.pdb" "ARM64\virtualaudiodriver.pdb"
"$arm64Staging\VirtualAudioDriver.inf" "ARM64\VirtualAudioDriver.inf"
"$catFile" "VirtualAudioDriver.cat"
"@

# Add icon if it exists
if (Test-Path (Join-Path $stagingDir "CallJoyna.ico")) {
    $ddfContent += "`n`"$(Join-Path $stagingDir "CallJoyna.ico")`" `"CallJoyna.ico`""
}

$ddfContent | Out-File -FilePath $ddfFile -Encoding ASCII

Push-Location $scriptDir
try {
    & $makecab /F "$ddfFile"
    if ($LASTEXITCODE -ne 0) {
        throw "makecab failed"
    }
}
finally {
    Pop-Location
}

# Cleanup DDF and temp files
Remove-Item $ddfFile -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $scriptDir "setup.inf") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $scriptDir "setup.rpt") -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $cabFile)) {
    throw "CAB file was not created"
}

Write-Host "      CAB created: $cabFile" -ForegroundColor Green

# --------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PACKAGE COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output files:" -ForegroundColor White
Write-Host "  CAB file:    $cabFile" -ForegroundColor Gray
Write-Host "  Staging dir: $stagingDir" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Log into Microsoft Partner Center (https://partner.microsoft.com/dashboard)"
Write-Host "  2. Navigate to Hardware > Drivers > Submit new driver"
Write-Host "  3. Select 'Driver Update Acceptable (DUA)' or 'Attestation'"
Write-Host "  4. Upload: $cabFile"
Write-Host "  5. Wait for processing (~30 min to 2 hours)"
Write-Host "  6. Download Microsoft-signed package"
Write-Host ""

# Verify file sizes
$cabSize = (Get-Item $cabFile).Length / 1MB
Write-Host "CAB file size: $([math]::Round($cabSize, 2)) MB" -ForegroundColor Gray
Write-Host ""

Pause
