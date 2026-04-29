#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"
$log = "D:\Datics\Virtual-Audio-Driver\clean_reinstall_log.txt"
"== clean reinstall: $(Get-Date) ==" | Out-File $log -Encoding UTF8
function L($m) { $m | Tee-Object -FilePath $log -Append }

$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe"
$inf = "E:\Downloads\Signed_1152921505700928743\drivers\VirtualAudioDriver\VirtualAudioDriver.inf"

L "--- 1. remove ALL CallJoyna devices ---"
& $devcon remove "ROOT\VirtualAudioDriver" 2>&1 | Tee-Object -FilePath $log -Append
$devs = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*CallJoyna*" -or $_.InstanceId -match "VirtualAudioDriver" }
foreach ($d in $devs) {
    L "  removing $($d.InstanceId)"
    pnputil /remove-device "$($d.InstanceId)" 2>&1 | Tee-Object -FilePath $log -Append
}

L "--- 2. delete ALL oem*.inf for CallJoyna (both v16 and v22 leftovers) ---"
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
L "  removing oem packages: $($oems -join ', ')"
foreach ($o in $oems) { pnputil /delete-driver $o /uninstall /force 2>&1 | Tee-Object -FilePath $log -Append }

L "--- 3. bounce audio stack to clear AEB cache ---"
Stop-Service AudioEndpointBuilder -Force -ErrorAction SilentlyContinue
Start-Sleep 2
Start-Service AudioEndpointBuilder
Start-Service Audiosrv -ErrorAction SilentlyContinue
Start-Sleep 3

L "--- 4. devcon install fresh v22 ---"
& $devcon install $inf "ROOT\VirtualAudioDriver" 2>&1 | Tee-Object -FilePath $log -Append
L "  exit=$LASTEXITCODE"
Start-Sleep 3

L "--- 5. bounce audio stack again so AEB picks up new endpoints ---"
Stop-Service AudioEndpointBuilder -Force -ErrorAction SilentlyContinue
Start-Sleep 2
Start-Service AudioEndpointBuilder
Start-Service Audiosrv -ErrorAction SilentlyContinue
Start-Sleep 5

L "--- 6. verify ---"
L "Drivers in store:"
pnputil /enum-drivers | Select-String "CallJoyna" -Context 0,5 | Out-String | Tee-Object -FilePath $log -Append
L ""
L "PnP devices:"
Get-PnpDevice | Where-Object { $_.FriendlyName -like "*CallJoyna*" -or $_.InstanceId -match "VirtualAudioDriver" } | Format-Table -AutoSize FriendlyName, Status, Class, InstanceId | Out-String | Tee-Object -FilePath $log -Append
L ""
L "Children of ROOT\MEDIA device:"
$mediaDev = Get-PnpDevice | Where-Object { $_.InstanceId -like "ROOT\MEDIA\*" -and $_.FriendlyName -like "*CallJoyna*" } | Select-Object -First 1
if ($mediaDev) {
    pnputil /enum-devices /instanceid "$($mediaDev.InstanceId)" /relations 2>&1 | Tee-Object -FilePath $log -Append
}
L ""
L "MMDevices CallJoyna entries:"
foreach ($cat in @("Render","Capture")) {
    $eps = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\$cat" -ErrorAction SilentlyContinue
    foreach ($ep in $eps) {
        $name = (Get-ItemProperty "$($ep.PSPath)\Properties" -Name "{a45c254e-df1c-4efd-8020-67d146a850e0},2" -ErrorAction SilentlyContinue)."{a45c254e-df1c-4efd-8020-67d146a850e0},2"
        if ($name -like "*CallJoyna*") {
            $state = (Get-ItemProperty $ep.PSPath -Name DeviceState -ErrorAction SilentlyContinue).DeviceState
            L "  $cat / $name -> DeviceState=$state"
        }
    }
}

L ""
L "== done: $(Get-Date) =="
Write-Host ""
Write-Host "Done. Log at: $log" -ForegroundColor Green
Write-Host "Press any key..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
