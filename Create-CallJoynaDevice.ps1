#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"
$log = "D:\Datics\Virtual-Audio-Driver\device_create_log.txt"
"== devcon install: $(Get-Date) ==" | Out-File $log -Encoding UTF8

$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe"
$inf = "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf"

if (-not (Test-Path $devcon)) {
    "ERROR: devcon not found at $devcon" | Tee-Object -FilePath $log -Append
} else {
    "devcon: $devcon" | Tee-Object -FilePath $log -Append
}
"INF: $inf  exists=$(Test-Path $inf)" | Tee-Object -FilePath $log -Append

"--- removing existing ROOT\VirtualAudioDriver (if any) ---" | Tee-Object -FilePath $log -Append
& $devcon remove "ROOT\VirtualAudioDriver" 2>&1 | Tee-Object -FilePath $log -Append

"--- devcon install ---" | Tee-Object -FilePath $log -Append
& $devcon install $inf "ROOT\VirtualAudioDriver" 2>&1 | Tee-Object -FilePath $log -Append
$rc = $LASTEXITCODE
"devcon install exit code: $rc" | Tee-Object -FilePath $log -Append

"--- restart audio service ---" | Tee-Object -FilePath $log -Append
net stop audiosrv 2>&1 | Tee-Object -FilePath $log -Append
Start-Sleep 2
net start audiosrv 2>&1 | Tee-Object -FilePath $log -Append

"--- verify ---" | Tee-Object -FilePath $log -Append
Get-PnpDevice | Where-Object { $_.FriendlyName -like "*CallJoyna*" } | Format-Table -AutoSize FriendlyName, Status, Class, InstanceId | Out-String | Tee-Object -FilePath $log -Append

"== done: $(Get-Date) ==" | Tee-Object -FilePath $log -Append
Write-Host ""
Write-Host "Done. Log at $log" -ForegroundColor Green
Write-Host "Press any key..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
