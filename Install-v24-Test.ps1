#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"
$log = "D:\Datics\Virtual-Audio-Driver\install_v24_log.txt"
"== install v24 (test-mode, isolation test) : $(Get-Date) ==" | Out-File $log -Encoding UTF8
function L($m) { $m | Tee-Object -FilePath $log -Append }

$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe"
# Point at v24 INF in the desktop app's build/driver/ folder (MS-signed v24, FormFactor=0x0B)
$inf = "D:\Datics\virtual-mic-isl\build\driver\VirtualAudioDriver.inf"

L "INF source: $inf"
L "Verifying it's actually v24 with FormFactor present..."
$formCheck = Select-String $inf -Pattern "DriverVer|FormFactor%" -SimpleMatch:$false
foreach ($m in $formCheck) { L "  L$($m.LineNumber): $($m.Line)" }

L ""
L "--- 1. remove all existing CallJoyna devices ---"
& $devcon remove "ROOT\VirtualAudioDriver" 2>&1 | Out-String | L
$devs = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like '*CallJoyna*' -or $_.HardwareId -match 'VirtualAudioDriver' }
foreach ($d in $devs) {
    L "  pnputil /remove-device $($d.InstanceId)"
    pnputil /remove-device "$($d.InstanceId)" /force 2>&1 | Out-String | L
}

L "--- 2. delete every CallJoyna oem*.inf (forced, including v25 if present) ---"
$oems = New-Object System.Collections.Generic.HashSet[string]
$raw = & pnputil /enum-drivers 2>&1 | Out-String
$blocks = $raw -split "(?ms)(?=^Published Name:\s+)"
foreach ($b in $blocks) {
    if ($b -match 'CallJoyna|virtualaudiodriver\.inf') {
        if ($b -match 'Published Name:\s+(oem\d+\.inf)') { [void]$oems.Add($Matches[1].ToLower()) }
    }
}
Get-ChildItem 'C:\Windows\INF\oem*.inf' -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $c = Get-Content $_.FullName -Raw -ErrorAction Stop
        if ($c -match 'VirtualAudioDriver|CallJoyna') { [void]$oems.Add($_.Name.ToLower()) }
    } catch {}
}
L "  packages to remove: $($oems -join ', ')"
foreach ($o in $oems) {
    pnputil /delete-driver $o /uninstall /force 2>&1 | Out-String | L
}

L "--- 3. bounce AudioEndpointBuilder (clear AEB cache) ---"
Stop-Service AudioEndpointBuilder -Force -ErrorAction SilentlyContinue
Start-Sleep 2
Start-Service AudioEndpointBuilder
Start-Service Audiosrv -ErrorAction SilentlyContinue
Start-Sleep 3

L "--- 4. devcon install v24 (FormFactor=0x0B INF) ---"
& $devcon install $inf "ROOT\VirtualAudioDriver" 2>&1 | Out-String | L
L "  exit=$LASTEXITCODE"
Start-Sleep 3

L "--- 5. bounce AEB again so endpoints re-enumerate ---"
Stop-Service AudioEndpointBuilder -Force -ErrorAction SilentlyContinue
Start-Sleep 2
Start-Service AudioEndpointBuilder
Start-Service Audiosrv -ErrorAction SilentlyContinue
Start-Sleep 5

L "--- 6. verify state ---"
L "Drivers in store:"
pnputil /enum-drivers | Select-String "CallJoyna" -Context 1,5 | Out-String | L
L "PnP devices:"
Get-PnpDevice | Where-Object { $_.FriendlyName -like '*CallJoyna*' } | Format-Table -AutoSize FriendlyName, Status, Class, InstanceId | Out-String | L

L "== done: $(Get-Date) =="
Write-Host ""
Write-Host "Done. Log: $log" -ForegroundColor Green
Write-Host "Press any key..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
