#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"
$log = "D:\Datics\Virtual-Audio-Driver\cleanup_all_log.txt"
"== full CallJoyna cleanup: $(Get-Date) ==" | Out-File $log -Encoding UTF8
function L($m) { $m | Tee-Object -FilePath $log -Append }

$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe"

L "--- 1. remove all CallJoyna devices (PnP) ---"
& $devcon remove "ROOT\VirtualAudioDriver" 2>&1 | Out-String | L
$devs = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {
    $_.FriendlyName -like '*CallJoyna*' -or $_.HardwareId -match 'VirtualAudioDriver'
}
foreach ($d in $devs) {
    L "  pnputil /remove-device $($d.InstanceId) ($($d.FriendlyName))"
    pnputil /remove-device "$($d.InstanceId)" /force 2>&1 | Out-String | L
}

L "--- 2. find every CallJoyna oem*.inf ---"
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

L "--- 3. delete every package ---"
foreach ($o in $oems) {
    L "  pnputil /delete-driver $o /uninstall /force"
    pnputil /delete-driver $o /uninstall /force 2>&1 | Out-String | L
    if ($LASTEXITCODE -ne 0) {
        L "    retry without /uninstall"
        pnputil /delete-driver $o /force 2>&1 | Out-String | L
    }
}

L "--- 4. bounce AudioEndpointBuilder (clears AEB cache) ---"
Stop-Service AudioEndpointBuilder -Force -ErrorAction SilentlyContinue
Start-Sleep 2
Start-Service AudioEndpointBuilder
Start-Service Audiosrv -ErrorAction SilentlyContinue
Start-Sleep 2

L "--- 5. final state ---"
L "Drivers in store:"
$post = pnputil /enum-drivers 2>&1 | Out-String
$matchPost = ($post -split "(?ms)(?=^Published Name:\s+)") | Where-Object { $_ -match 'CallJoyna|virtualaudiodriver\.inf' }
if ($matchPost) {
    L "  STILL PRESENT (manual cleanup may be needed):"
    foreach ($m in $matchPost) { L "  $(($m -split "`n" | Select-Object -First 6) -join "`n  ")" }
} else {
    L "  CLEAN: no CallJoyna packages remain"
}
L "PnP devices:"
$postDevs = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like '*CallJoyna*' }
if ($postDevs) {
    L "  STILL PRESENT:"
    $postDevs | Format-Table -AutoSize FriendlyName, Status, InstanceId | Out-String | L
} else {
    L "  CLEAN: no CallJoyna devices"
}

L "== done: $(Get-Date) =="
Write-Host ""
Write-Host "Done. Log: $log" -ForegroundColor Green
Write-Host "Press any key..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
