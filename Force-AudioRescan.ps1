#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"
$log = "D:\Datics\Virtual-Audio-Driver\rescan_log.txt"
"== rescan: $(Get-Date) ==" | Out-File $log -Encoding UTF8
function L($m) { $m | Tee-Object -FilePath $log -Append }

L "--- Step 1: disable + enable CallJoyna Audio device (forces driver to re-expose topology) ---"
$dev = Get-PnpDevice | Where-Object { $_.InstanceId -like "ROOT\MEDIA\*" -and $_.FriendlyName -like "*CallJoyna*" }
if ($dev) {
    L "Found: $($dev.FriendlyName)  $($dev.InstanceId)"
    Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false
    Start-Sleep 2
    Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false
    Start-Sleep 3
} else {
    L "No CallJoyna ROOT\MEDIA device found — cannot proceed"
    Write-Host "Press any key..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return
}

L ""
L "--- Step 2: bounce AudioEndpointBuilder (forces full endpoint re-scan) ---"
Stop-Service AudioEndpointBuilder -Force
Start-Sleep 2
Start-Service AudioEndpointBuilder
Start-Sleep 1
Start-Service Audiosrv -ErrorAction SilentlyContinue
Start-Sleep 3

L ""
L "--- Step 3: verify endpoints ---"
$pnp = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*CallJoyna*" } | Format-Table -AutoSize FriendlyName, Status, Class | Out-String
L "PnP devices:`n$pnp"

L "MMDevices CallJoyna entries:"
foreach ($cat in @("Render","Capture")) {
    $eps = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\$cat" -ErrorAction SilentlyContinue
    foreach ($ep in $eps) {
        $name = (Get-ItemProperty "$($ep.PSPath)\Properties" -Name "{a45c254e-df1c-4efd-8020-67d146a850e0},2" -ErrorAction SilentlyContinue)."{a45c254e-df1c-4efd-8020-67d146a850e0},2"
        if ($name -like "*CallJoyna*") {
            $state = (Get-ItemProperty $ep.PSPath -Name DeviceState -ErrorAction SilentlyContinue).DeviceState
            L "  $cat / $name -> DeviceState=$state (1=Active, 2=Disabled, 4=NotPresent, 8=Unplugged)"
        }
    }
}

L ""
L "== done: $(Get-Date) =="
Write-Host ""
Write-Host "Now check Sound settings and Device Manager > Audio inputs and outputs." -ForegroundColor Green
Write-Host "Press any key..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
