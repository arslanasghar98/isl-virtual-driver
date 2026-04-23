# Reinstall Microsoft-Signed CallJoyna Driver
# Run this script as Administrator

$ErrorActionPreference = "Continue"
$devcon = "D:\Datics\virtual-mic-isl\resources\devcon.exe"
$signedDriver = "D:\Datics\virtual-mic-isl\build\driver"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Reinstalling Microsoft-Signed Driver" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Step 1: Stop audio service
Write-Host "`n[1/6] Stopping audio service..." -ForegroundColor Yellow
net stop audiosrv 2>$null

# Step 2: Remove existing device
Write-Host "`n[2/6] Removing existing device..." -ForegroundColor Yellow
& $devcon remove "ROOT\VirtualAudioDriver"

# Step 3: Find and delete old driver from store
Write-Host "`n[3/6] Cleaning driver store..." -ForegroundColor Yellow
$drivers = pnputil /enum-drivers | Out-String
$lines = $drivers -split "`n"
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "virtualaudiodriver\.inf") {
        # Find the oem*.inf name from previous lines
        for ($j = $i - 1; $j -ge 0; $j--) {
            if ($lines[$j] -match "(oem\d+\.inf)") {
                $oemInf = $matches[1]
                Write-Host "  Deleting $oemInf..." -ForegroundColor Gray
                pnputil /delete-driver $oemInf /force
                break
            }
        }
    }
}

# Step 4: Restart audio service
Write-Host "`n[4/6] Starting audio service..." -ForegroundColor Yellow
net start audiosrv

# Step 5: Install Microsoft-signed driver
Write-Host "`n[5/6] Installing Microsoft-signed driver..." -ForegroundColor Yellow
& $devcon install "$signedDriver\VirtualAudioDriver.inf" "ROOT\VirtualAudioDriver"

# Step 6: Restart audio service again
Write-Host "`n[6/6] Restarting audio service..." -ForegroundColor Yellow
net stop audiosrv 2>$null
net start audiosrv

# Verify
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Verifying installation..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check device status
Write-Host "`nDevice status:" -ForegroundColor Yellow
& $devcon status "ROOT\VirtualAudioDriver"

# Check driver signature
Write-Host "`nDriver signature:" -ForegroundColor Yellow
$signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
& $signtool verify /pa "$signedDriver\virtualaudiodriver.cat"

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Done! Check Device Manager for status." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
