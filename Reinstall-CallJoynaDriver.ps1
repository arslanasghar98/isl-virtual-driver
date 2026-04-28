#Requires -RunAsAdministrator
<#
.SYNOPSIS
    One-shot reinstall flow: uninstall old CallJoyna driver, flush icon cache, install fresh signed driver, verify.
#>

$ErrorActionPreference = "Continue"
$log = "D:\Datics\Virtual-Audio-Driver\reinstall_log.txt"
"== Reinstall started: $(Get-Date) ==" | Out-File $log

function Log {
    param([string]$msg)
    $line = "[$(Get-Date -Format HH:mm:ss)] $msg"
    Write-Host $line
    Add-Content -Path $log -Value $line
}

Log "Phase 1: Uninstall existing CallJoyna driver"

$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe"

net stop audiosrv 2>&1 | Out-Null

if (Test-Path $devcon) {
    & $devcon remove "ROOT\VirtualAudioDriver" 2>&1 | ForEach-Object { Log "  devcon: $_" }
}

$devices = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*CallJoyna*" }
foreach ($d in $devices) {
    Log "  Removing device $($d.InstanceId)"
    pnputil /remove-device "$($d.InstanceId)" 2>&1 | Out-Null
}

$drvList = pnputil /enum-drivers
$lines = $drvList -split "`n"
$oems = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "virtualaudiodriver\.inf" -or $lines[$i] -match "CallJoyna") {
        for ($j = $i; $j -ge 0; $j--) {
            if ($lines[$j] -match "Published Name:\s+(oem\d+\.inf)") {
                $oems += $Matches[1]
                break
            }
        }
    }
}
$oems = $oems | Select-Object -Unique
Log "  OEM packages to remove: $($oems -join ', ')"
foreach ($oem in $oems) {
    Log "  pnputil /delete-driver $oem /uninstall /force"
    pnputil /delete-driver $oem /uninstall /force 2>&1 | ForEach-Object { Log "    $_" }
}

Log "Phase 2: Flush icon cache"
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db" -ErrorAction SilentlyContinue | ForEach-Object {
    Log "  removing $($_.Name)"
    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
}
Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
ie4uinit.exe -show 2>&1 | Out-Null

Log "Phase 3: Install new driver"
$newInf = "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf"
Log "  pnputil /add-driver $newInf /install"
pnputil /add-driver $newInf /install 2>&1 | ForEach-Object { Log "    $_" }

Log "Phase 4: Verify"
Start-Sleep -Seconds 3
$installed = pnputil /enum-drivers | Out-String
$callJoynaSection = ($installed -split "Published Name:") | Where-Object { $_ -match "CallJoyna|virtualaudiodriver" }
foreach ($s in $callJoynaSection) {
    Log ("  driver entry: " + ($s -split "`n" | Select-Object -First 6 | Out-String).Trim())
}

$pnp = Get-PnpDevice -FriendlyName "*CallJoyna*" | Format-Table -AutoSize FriendlyName, Status, Class | Out-String
Log "  PnP devices:`n$pnp"

Log "== Reinstall complete: $(Get-Date) =="
Write-Host ""
Write-Host "Done. Log saved to: $log" -ForegroundColor Green
Write-Host "Press any key to close..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
