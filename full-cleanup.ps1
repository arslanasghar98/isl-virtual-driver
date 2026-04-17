# Full Cleanup and Install CallJoyna Audio Driver
$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Full Cleanup CallJoyna Audio Driver" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Stop audio service first
Write-Host "`n[1/5] Stopping audio service..." -ForegroundColor Yellow
net stop audiosrv 2>$null

# Remove ALL ROOT\MEDIA devices except VB-Audio (0000)
Write-Host "`n[2/5] Removing all CallJoyna devices..." -ForegroundColor Yellow
$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe"

for ($i = 1; $i -le 10; $i++) {
    $instanceId = "ROOT\MEDIA\000$i"
    $device = Get-PnpDevice -InstanceId $instanceId -ErrorAction SilentlyContinue
    if ($device -and $device.FriendlyName -ne "VB-Audio Virtual Cable") {
        Write-Host "      Removing $instanceId ($($device.FriendlyName))..."
        & $devcon remove "@$instanceId" 2>$null
        pnputil /remove-device "$instanceId" 2>$null
    }
}

# Also remove by hardware ID
& $devcon remove "ROOT\VirtualAudioDriver" 2>$null

# Remove from driver store
Write-Host "`n[3/5] Cleaning driver store..." -ForegroundColor Yellow
$driverList = pnputil /enum-drivers
$lines = $driverList -split "`n"
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "virtualaudiodriver\.inf") {
        # Find the oem number from previous lines
        for ($j = $i - 1; $j -ge 0; $j--) {
            if ($lines[$j] -match "(oem\d+\.inf)") {
                $oemInf = $Matches[1]
                Write-Host "      Removing $oemInf from store..."
                pnputil /delete-driver $oemInf /force 2>$null
                break
            }
        }
    }
}

# Now install fresh
Write-Host "`n[4/5] Installing driver..." -ForegroundColor Yellow
$result = & $devcon install "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf" "ROOT\VirtualAudioDriver" 2>&1
Write-Host $result

# Start audio service
Write-Host "`n[5/5] Starting audio service..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
net start audiosrv

# Verify
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Final Status:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Get-PnpDevice -Class MEDIA | Where-Object { $_.FriendlyName -like "*CallJoyna*" -or $_.InstanceId -like "ROOT\MEDIA*" } | Format-Table FriendlyName, InstanceId, Status -AutoSize

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
