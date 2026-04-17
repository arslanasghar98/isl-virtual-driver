# Install CallJoyna Audio Driver
$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installing CallJoyna Audio Driver" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Remove existing device if any
Write-Host "`n[1/4] Removing existing device..." -ForegroundColor Yellow
$existingDevice = Get-PnpDevice -InstanceId "ROOT\MEDIA\0002" -ErrorAction SilentlyContinue
if ($existingDevice) {
    Write-Host "      Found existing device, removing..."
    pnputil /remove-device "ROOT\MEDIA\0002" 2>$null
    devcon remove "ROOT\MEDIA\0002" 2>$null
}

# Also remove ROOT\VirtualAudioDriver if exists
devcon remove "ROOT\VirtualAudioDriver" 2>$null

# Add driver to store
Write-Host "`n[2/4] Adding driver to store..." -ForegroundColor Yellow
$result = pnputil /add-driver "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf" /install
Write-Host $result

# Install using devcon
Write-Host "`n[3/4] Installing driver with devcon..." -ForegroundColor Yellow
$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe"
& $devcon install "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf" "ROOT\VirtualAudioDriver"

# Restart audio service
Write-Host "`n[4/4] Restarting audio service..." -ForegroundColor Yellow
net stop audiosrv 2>$null
Start-Sleep -Seconds 2
net start audiosrv

# Verify
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Verification:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nDriver packages:" -ForegroundColor Yellow
pnputil /enum-drivers | Select-String -Pattern "CallJoyna|virtualaudio" -Context 3,5

Write-Host "`nMEDIA devices:" -ForegroundColor Yellow
Get-PnpDevice -Class MEDIA | Where-Object { $_.InstanceId -like "ROOT*" } | Format-Table FriendlyName, InstanceId, Status -AutoSize

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
