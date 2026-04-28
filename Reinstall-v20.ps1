#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"
$log = "D:\Datics\Virtual-Audio-Driver\reinstall_v20_log.txt"
"== reinstall v21: $(Get-Date) ==" | Out-File $log -Encoding UTF8
function L($m) { $m | Tee-Object -FilePath $log -Append }

$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe"
$inf = "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf"

L "--- 1. remove existing CallJoyna devices ---"
& $devcon remove "ROOT\VirtualAudioDriver" 2>&1 | Out-String | L
$devs = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*CallJoyna*" }
foreach ($d in $devs) { L "  pnputil /remove-device $($d.InstanceId)"; pnputil /remove-device "$($d.InstanceId)" 2>&1 | Out-String | L }

L "--- 2. delete oem packages ---"
$drv = pnputil /enum-drivers
$lines = $drv -split "`n"
$oems = @()
for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "virtualaudiodriver\.inf" -or $lines[$i] -match "CallJoyna") {
        for ($j=$i; $j -ge 0; $j--) {
            if ($lines[$j] -match "Published Name:\s+(oem\d+\.inf)") { $oems += $Matches[1]; break }
        }
    }
}
$oems = $oems | Select-Object -Unique
L "  oem to remove: $($oems -join ',')"
foreach ($o in $oems) { pnputil /delete-driver $o /uninstall /force 2>&1 | Out-String | L }

L "--- 3. flush icon cache + bounce explorer ---"
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep 1
Start-Process explorer.exe

L "--- 4. devcon install new driver ---"
& $devcon install $inf "ROOT\VirtualAudioDriver" 2>&1 | Out-String | L
L "  exit=$LASTEXITCODE"

L "--- 5. bounce audio stack ---"
Stop-Service AudioEndpointBuilder -Force -ErrorAction SilentlyContinue
Stop-Service Audiosrv -Force -ErrorAction SilentlyContinue
Start-Sleep 2
Start-Service Audiosrv -ErrorAction SilentlyContinue
Start-Service AudioEndpointBuilder -ErrorAction SilentlyContinue
Start-Sleep 3

L "--- 6. verify ---"
pnputil /enum-drivers | Select-String "CallJoyna" -Context 1,5 | Out-String | L
Get-PnpDevice | Where-Object { $_.FriendlyName -like "*CallJoyna*" } | Format-Table -AutoSize FriendlyName, Status, Class | Out-String | L

L "--- 7. inspect IconPath in registry ---"
$root = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio"
foreach ($cat in @("Render","Capture")) {
    $eps = Get-ChildItem "$root\$cat" -ErrorAction SilentlyContinue
    foreach ($ep in $eps) {
        $name = (Get-ItemProperty "$($ep.PSPath)\Properties" -Name "{a45c254e-df1c-4efd-8020-67d146a850e0},2" -ErrorAction SilentlyContinue)."{a45c254e-df1c-4efd-8020-67d146a850e0},2"
        if ($name -like "*CallJoyna*") {
            $epIcon = (Get-ItemProperty "$($ep.PSPath)\Properties" -Name "{f1ab780d-2010-4ed3-a3a6-8b87f0f0c476},0" -ErrorAction SilentlyContinue)."{f1ab780d-2010-4ed3-a3a6-8b87f0f0c476},0"
            $clsIcon = (Get-ItemProperty "$($ep.PSPath)\Properties" -Name "{259abffc-50a7-47ce-af08-68c9a7d73366},12" -ErrorAction SilentlyContinue)."{259abffc-50a7-47ce-af08-68c9a7d73366},12"
            L "  $cat / $name"
            L "    PKEY_AudioEndpoint_IconPath  = $epIcon"
            L "    DEVPKEY_DeviceClass_IconPath = $clsIcon"
        }
    }
}

L "== done: $(Get-Date) =="
Write-Host ""
Write-Host "Done. Check Device Manager and mmsys.cpl for the new icon." -ForegroundColor Green
Write-Host "Press any key..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
