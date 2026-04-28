#Requires -RunAsAdministrator
$ErrorActionPreference = "Continue"
$log = "D:\Datics\Virtual-Audio-Driver\icon_test_log.txt"
"== icon test: $(Get-Date) ==" | Out-File $log -Encoding UTF8

function L($m) { $m | Tee-Object -FilePath $log -Append }

$iconValue = "C:\Windows\System32\drivers\CallJoyna.ico"
L "Setting IconPath to: $iconValue (absolute, REG_SZ)"
L "Icon file exists: $(Test-Path $iconValue)"

$root = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio"
$nameProp = "{a45c254e-df1c-4efd-8020-67d146a850e0},2"
$iconProp = "{f1ab780d-2010-4ed3-a3a6-8b87f0f0c476},0"

foreach ($cat in @("Render","Capture")) {
    $eps = Get-ChildItem "$root\$cat" -ErrorAction SilentlyContinue
    foreach ($ep in $eps) {
        $propPath = "$($ep.PSPath)\Properties"
        $name = (Get-ItemProperty $propPath -Name $nameProp -ErrorAction SilentlyContinue).$nameProp
        if ($name -like "*CallJoyna*") {
            L "  Updating $cat / $name (id=$($ep.PSChildName))"
            $regKey = $propPath -replace "Microsoft.PowerShell.Core\\Registry::","" -replace "^HKEY_LOCAL_MACHINE","HKLM:"
            try {
                Set-ItemProperty -Path $propPath -Name $iconProp -Value $iconValue -Type String -Force
                $confirm = (Get-ItemProperty $propPath -Name $iconProp -ErrorAction SilentlyContinue).$iconProp
                L "    OK: now reads = $confirm"
            } catch {
                L "    FAIL: $_"
            }
        }
    }
}

L "--- Restart audio service ---"
Stop-Service AudioEndpointBuilder -Force -ErrorAction SilentlyContinue
Start-Sleep 2
Start-Service AudioEndpointBuilder -ErrorAction SilentlyContinue
Start-Sleep 2

L "--- Flush icon cache ---"
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep 1
Start-Process explorer.exe

L "== done: $(Get-Date) =="
Write-Host ""
Write-Host "Done. Check Device Manager > Audio inputs and outputs." -ForegroundColor Green
Write-Host "If icon now shows, the fix is to use absolute path in INF." -ForegroundColor Cyan
Write-Host "Press any key..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
