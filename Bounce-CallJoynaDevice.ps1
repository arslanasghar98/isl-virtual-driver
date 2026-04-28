#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"
$log = "D:\Datics\Virtual-Audio-Driver\bounce_log.txt"
"== bounce: $(Get-Date) ==" | Out-File $log -Encoding UTF8

function L($m) { $m | Tee-Object -FilePath $log -Append }

$dev = Get-PnpDevice | Where-Object { $_.InstanceId -like "ROOT\MEDIA\*" -and $_.FriendlyName -like "*CallJoyna*" }
if (-not $dev) {
    L "No CallJoyna ROOT\MEDIA device found"
} else {
    L "Found device: $($dev.FriendlyName) -- $($dev.InstanceId)"
    L "Disabling..."
    Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false 2>&1 | Out-String | L
    Start-Sleep 2
    L "Enabling..."
    Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false 2>&1 | Out-String | L
    Start-Sleep 3
}

L "--- Restart audio stack (force) ---"
$svcs = @("AudioEndpointBuilder","Audiosrv")
foreach ($s in $svcs) {
    L "stopping $s ..."
    Stop-Service -Name $s -Force -ErrorAction SilentlyContinue 2>&1 | Out-String | L
}
Start-Sleep 2
foreach ($s in @("Audiosrv","AudioEndpointBuilder")) {
    L "starting $s ..."
    Start-Service -Name $s -ErrorAction SilentlyContinue 2>&1 | Out-String | L
}
Start-Sleep 3

L "--- final state ---"
Get-PnpDevice | Where-Object { $_.FriendlyName -like "*CallJoyna*" } | Format-Table -AutoSize FriendlyName, Status, Class | Out-String | L

L "== done: $(Get-Date) =="
Write-Host ""
Write-Host "Done. Press any key..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
