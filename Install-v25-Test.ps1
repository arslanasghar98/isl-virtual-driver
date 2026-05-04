#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"
$log = "D:\Datics\Virtual-Audio-Driver\install_v25_log.txt"
"== install v25 (test-mode) : $(Get-Date) ==" | Out-File $log -Encoding UTF8
function L($m) { $m | Tee-Object -FilePath $log -Append }

$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\10.0.26100.0\x64\devcon.exe"
$inf = "D:\Datics\Virtual-Audio-Driver\x64\Release\VirtualAudioDriver.inf"

L "--- 1. remove all existing CallJoyna devices ---"
& $devcon remove "ROOT\VirtualAudioDriver" 2>&1 | Out-String | L
$devs = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like '*CallJoyna*' -or $_.HardwareId -match 'VirtualAudioDriver' }
foreach ($d in $devs) {
    L "  pnputil /remove-device $($d.InstanceId)"
    pnputil /remove-device "$($d.InstanceId)" /force 2>&1 | Out-String | L
}

L "--- 2. delete every CallJoyna oem*.inf ---"
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

L "--- 4. devcon install v25 ---"
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
L "MMDevices CallJoyna:"
foreach ($cat in 'Render','Capture') {
    Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\$cat" -ErrorAction SilentlyContinue | ForEach-Object {
        $name = (Get-ItemProperty "$($_.PSPath)\Properties" -Name "{a45c254e-df1c-4efd-8020-67d146a850e0},2" -ErrorAction SilentlyContinue)."{a45c254e-df1c-4efd-8020-67d146a850e0},2"
        if ($name -like '*CallJoyna*') {
            $state = (Get-ItemProperty $_.PSPath -Name DeviceState -ErrorAction SilentlyContinue).DeviceState
            $stateName = switch ($state) {1{'Active'} 2{'Disabled'} 4{'NotPresent'} 8{'Unplugged'} default {"Unknown($state)"}}
            $iconPath = (Get-ItemProperty "$($_.PSPath)\Properties" -Name "{f1ab780d-2010-4ed3-a3a6-8b87f0f0c476},0" -ErrorAction SilentlyContinue)."{f1ab780d-2010-4ed3-a3a6-8b87f0f0c476},0"
            $clsIcon  = (Get-ItemProperty "$($_.PSPath)\Properties" -Name "{259abffc-50a7-47ce-af08-68c9a7d73366},12" -ErrorAction SilentlyContinue)."{259abffc-50a7-47ce-af08-68c9a7d73366},12"
            L "  $cat / $name : $stateName"
            L "    PKEY_AudioEndpoint_IconPath  = $iconPath"
            L "    DEVPKEY_DeviceClass_IconPath = $clsIcon"
        }
    }
}

L "== done: $(Get-Date) =="
Write-Host ""
Write-Host "Done. Log: $log" -ForegroundColor Green
Write-Host "Press any key..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
