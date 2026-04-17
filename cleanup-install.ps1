# Clean Install CallJoyna Audio Driver
$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Clean Install CallJoyna Audio Driver" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Remove all existing CallJoyna/VirtualAudioDriver devices
Write-Host "`n[1/4] Removing all existing devices..." -ForegroundColor Yellow
devcon remove "ROOT\MEDIA\0001" 2>$null
devcon remove "ROOT\MEDIA\0002" 2>$null
devcon remove "ROOT\VirtualAudioDriver" 2>$null

# Remove from driver store
Write-Host "`n[2/4] Cleaning driver store..." -ForegroundColor Yellow
$drivers = pnputil /enum-drivers | Select-String "virtualaudiodriver" -Context 2,0
if ($drivers) {
    $oemInf = $drivers.Context.PreContext | Select-String "oem\d+\.inf" -AllMatches | ForEach-Object { $_.Matches.Value }
    foreach ($inf in $oemInf) {
        Write-Host "      Removing $inf..."
        pnputil /delete-driver $inf /force 2>$null
    }
}

# Install fresh
Write-Host "`n[3/4] Installing driver..." -ForegroundColor Yellow
$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe"
& $devcon install "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf" "ROOT\VirtualAudioDriver"

# Restart audio
Write-Host "`n[4/4] Restarting audio service..." -ForegroundColor Yellow
net stop audiosrv 2>$null
Start-Sleep -Seconds 2
net start audiosrv

# Verify
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Installed devices:" -ForegroundColor Green
Get-PnpDevice -Class MEDIA | Where-Object { $_.FriendlyName -like "*CallJoyna*" } | Format-Table FriendlyName, Status -AutoSize

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
