<#
.SYNOPSIS
    Capture setupapi + event logs around a reproducible Mic-loss action
    (plug/unplug a device on AtlasOS).

.DESCRIPTION
    Run elevated. The script:
      1. Records a baseline timestamp + current PnP state
      2. Waits for you to perform the trigger action (plug/unplug)
      3. Waits for you to press a key when done
      4. Extracts every setupapi.dev.log block + System event between the
         baseline and now that mentions CallJoyna or capture-flow SWD devices
      5. Identifies the `cmd:` line for any [Delete Device] block that
         removed a CallJoyna Mic -- this names the process responsible
      6. Bundles output into a zip on Desktop

    Intended for the AtlasOS test machine to identify exactly which
    Atlas component / Windows service is deleting the Mic on plug/unplug.
#>

#Requires -Version 5.0

# Self-elevate
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File",$PSCommandPath)
    return
}

$ErrorActionPreference = 'Continue'
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$work  = Join-Path $env:TEMP "MicLoss-$stamp"
$zip   = Join-Path ([Environment]::GetFolderPath("Desktop")) "CallJoyna-MicLoss-$env:COMPUTERNAME-$stamp.zip"
New-Item -ItemType Directory -Path $work -Force | Out-Null

# Hard pin baseline timestamp BEFORE user does anything
$baseline = Get-Date

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host " CallJoyna Mic-Loss Capture (AtlasOS triage)" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Baseline time: $baseline" -ForegroundColor Gray
Write-Host ""

# ---------------------------------------------------- pre-action snapshot
Write-Host "[1/5] Recording pre-action state..." -ForegroundColor Yellow
$preMic = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like '*CallJoyna*' -or $_.HardwareId -match 'VirtualAudioDriver' }
$preMic | Format-Table -AutoSize FriendlyName, Status, Class, InstanceId | Out-File "$work\01_pre_devices.txt" -Encoding UTF8

$preSetupSize = (Get-Item C:\Windows\INF\setupapi.dev.log -ErrorAction SilentlyContinue).Length
"Baseline timestamp: $baseline" | Out-File "$work\00_baseline.txt"
"Pre-action setupapi.dev.log size: $preSetupSize bytes" | Out-File "$work\00_baseline.txt" -Append
"Pre-action CallJoyna device count: $($preMic.Count)" | Out-File "$work\00_baseline.txt" -Append

if ($preMic | Where-Object { $_.FriendlyName -like '*CallJoyna Mic*' }) {
    Write-Host "  CallJoyna Mic IS present right now. Good to proceed." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Red
    Write-Host "  CallJoyna Mic is NOT currently present." -ForegroundColor Red
    Write-Host "  ============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  We cannot capture the deletion event because the Mic is" -ForegroundColor Yellow
    Write-Host "  already gone. Capturing during a no-Mic window produces" -ForegroundColor Yellow
    Write-Host "  empty logs (no setupapi entries, no events)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Please do the following first:" -ForegroundColor Cyan
    Write-Host "    1. Reboot the machine, OR" -ForegroundColor White
    Write-Host "    2. Reinstall the CallJoyna desktop app." -ForegroundColor White
    Write-Host "  Then verify in Sound settings that CallJoyna Mic appears" -ForegroundColor Cyan
    Write-Host "  and is selectable. After that, run this script again." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
    return
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host " NOW PERFORM THE TRIGGER ACTION" -ForegroundColor Yellow
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Plug in / unplug the device that causes the CallJoyna Mic" -ForegroundColor White
Write-Host " to disappear. Wait a few seconds for Windows to settle." -ForegroundColor White
Write-Host ""
Write-Host " When you're done (and the Mic has disappeared from Sound" -ForegroundColor White
Write-Host " settings), press any key to capture the logs." -ForegroundColor White
Write-Host ""
Write-Host " Press any key when ready..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

$captured = Get-Date
Write-Host ""
Write-Host "[2/5] Captured at: $captured" -ForegroundColor Yellow

# ---------------------------------------------------- post-action snapshot
$postMic = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like '*CallJoyna*' -or $_.HardwareId -match 'VirtualAudioDriver' }
$postMic | Format-Table -AutoSize FriendlyName, Status, Class, InstanceId | Out-File "$work\02_post_devices.txt" -Encoding UTF8

$postMicMissing = -not ($postMic | Where-Object { $_.FriendlyName -like '*CallJoyna Mic*' })
"Post-action timestamp: $captured" | Out-File "$work\00_baseline.txt" -Append
"Post-action CallJoyna device count: $($postMic.Count)" | Out-File "$work\00_baseline.txt" -Append
"Post-action CallJoyna Mic MISSING: $postMicMissing" | Out-File "$work\00_baseline.txt" -Append

if ($postMicMissing) {
    Write-Host "  Confirmed: CallJoyna Mic is now MISSING. Capturing logs..." -ForegroundColor Green
} else {
    Write-Host "  CallJoyna Mic is still present -- the trigger may not have fired. Capturing anyway." -ForegroundColor Yellow
}

# ---------------------------------------------------- setupapi delta
Write-Host ""
Write-Host "[3/5] Extracting setupapi.dev.log entries since baseline..." -ForegroundColor Yellow

$logs = @('C:\Windows\INF\setupapi.dev.log')
$logs += Get-ChildItem 'C:\Windows\INF\setupapi.dev.log.*.old' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName

$deleteBlocks = @()
foreach ($lp in $logs) {
    if (-not (Test-Path $lp)) { continue }
    "########### $lp ###########" | Out-File "$work\03_setupapi_delta.log" -Append -Encoding UTF8
    $content = Get-Content $lp -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    # Extract >>> ... <<< blocks
    $regex = [regex]'(?ms)>>>\s+\[.*?\n.*?<<<\s+\[.*?\]\s*[^\r\n]*'
    $matches = $regex.Matches($content)

    foreach ($m in $matches) {
        $block = $m.Value
        # Only keep blocks newer than baseline
        if ($block -match 'Section start (\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})') {
            try {
                $blockTime = [DateTime]::ParseExact($Matches[1], 'yyyy/MM/dd HH:mm:ss', $null)
                if ($blockTime -lt $baseline) { continue }
            } catch { }
        }
        # Keep blocks that mention CallJoyna, VirtualAudioDriver, or capture SWD devices
        if ($block -match 'CallJoyna|VirtualAudioDriver|MicArray|MMDEVAPI\\\{0\.0\.1' -or
            $block -match 'ROOT\\MEDIA' -or
            $block -match '\[Delete Device') {
            $block | Out-File "$work\03_setupapi_delta.log" -Append -Encoding UTF8
            "------------------------------------------------------------" | Out-File "$work\03_setupapi_delta.log" -Append -Encoding UTF8

            if ($block -match '\[Delete Device') {
                $deleteBlocks += $block
            }
        }
    }
}

# ---------------------------------------------------- highlight: who deleted the Mic
Write-Host "[4/5] Identifying the process that deleted the Mic..." -ForegroundColor Yellow

"=== Delete-Device blocks captured (most relevant) ===" | Out-File "$work\04_who_deleted_mic.txt" -Encoding UTF8
"" | Out-File "$work\04_who_deleted_mic.txt" -Append
if ($deleteBlocks.Count -eq 0) {
    "(no [Delete Device] blocks recorded since baseline -- try a slower trigger action and re-run)" | Out-File "$work\04_who_deleted_mic.txt" -Append
    Write-Host "  No [Delete Device] blocks captured. Mic deletion may have happened earlier or via a path other than setupapi." -ForegroundColor Yellow
} else {
    foreach ($b in $deleteBlocks) {
        # Extract the cmd: line -- names the process responsible
        $cmdMatch = [regex]::Match($b, '(?m)^\s*cmd:\s*(.+)$')
        $headerMatch = [regex]::Match($b, '>>>\s+\[(.+?)\]')
        if ($headerMatch.Success) { ">>> $($headerMatch.Groups[1].Value)" | Out-File "$work\04_who_deleted_mic.txt" -Append }
        if ($cmdMatch.Success)    { "   COMMAND: $($cmdMatch.Groups[1].Value.Trim())" | Out-File "$work\04_who_deleted_mic.txt" -Append }
        "   FULL BLOCK:" | Out-File "$work\04_who_deleted_mic.txt" -Append
        $b | Out-File "$work\04_who_deleted_mic.txt" -Append
        "------------------------------------------------------------" | Out-File "$work\04_who_deleted_mic.txt" -Append
    }
    Write-Host "  Captured $($deleteBlocks.Count) [Delete Device] block(s). See 04_who_deleted_mic.txt." -ForegroundColor Green
}

# ---------------------------------------------------- system + application events delta
Write-Host "[5/5] Extracting System + Application events since baseline..." -ForegroundColor Yellow

"=== System events since baseline ($baseline) ===" | Out-File "$work\05_events.txt" -Encoding UTF8
Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=$baseline} -ErrorAction SilentlyContinue |
    Sort-Object TimeCreated |
    Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, @{N='Msg';E={$_.Message -replace "\s+"," " -replace "(.{400}).+",'$1...'}} |
    Format-List | Out-File "$work\05_events.txt" -Append -Encoding UTF8

"" | Out-File "$work\05_events.txt" -Append
"=== Application events since baseline ===" | Out-File "$work\05_events.txt" -Append
Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=$baseline} -ErrorAction SilentlyContinue |
    Sort-Object TimeCreated |
    Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, @{N='Msg';E={$_.Message -replace "\s+"," " -replace "(.{400}).+",'$1...'}} |
    Format-List | Out-File "$work\05_events.txt" -Append -Encoding UTF8

# ---------------------------------------------------- AtlasOS markers
"=== Atlas / AME markers (services, scheduled tasks, install dirs) ===" | Out-File "$work\06_atlas_markers.txt" -Encoding UTF8
"" | Out-File "$work\06_atlas_markers.txt" -Append

"--- Services matching atlas/ame/playbook/privacy ---" | Out-File "$work\06_atlas_markers.txt" -Append
Get-Service -Name '*atlas*','*ame*','*playbook*','*privacy*' -ErrorAction SilentlyContinue |
    Format-Table -AutoSize Name, Status, StartType | Out-File "$work\06_atlas_markers.txt" -Append

"--- Scheduled tasks matching atlas/ame/privacy/microphone ---" | Out-File "$work\06_atlas_markers.txt" -Append
Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskName -match 'atlas|ame|playbook|microphone|capture|privacy' -or $_.TaskPath -match 'atlas|ame' } |
    Format-Table -AutoSize TaskName, TaskPath, State | Out-File "$work\06_atlas_markers.txt" -Append

"--- Install dirs ---" | Out-File "$work\06_atlas_markers.txt" -Append
Get-ChildItem 'C:\AtlasOS','C:\Atlas','C:\AME','C:\Program Files\AME','C:\Program Files\AtlasOS','C:\ProgramData\AME' -ErrorAction SilentlyContinue |
    Select-Object FullName, LastWriteTime | Format-Table -AutoSize | Out-File "$work\06_atlas_markers.txt" -Append

"--- Microphone privacy registry state ---" | Out-File "$work\06_atlas_markers.txt" -Append
foreach ($k in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy',
    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\AudioEndpointBuilder',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone'
)) {
    "[$k]" | Out-File "$work\06_atlas_markers.txt" -Append
    if (Test-Path $k) {
        Get-ItemProperty $k -ErrorAction SilentlyContinue | Format-List | Out-File "$work\06_atlas_markers.txt" -Append
    } else {
        "  (key does not exist)" | Out-File "$work\06_atlas_markers.txt" -Append
    }
    "" | Out-File "$work\06_atlas_markers.txt" -Append
}

# ---------------------------------------------------- bundle
Write-Host ""
Write-Host "Zipping..." -ForegroundColor Cyan
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path "$work\*" -DestinationPath $zip -CompressionLevel Optimal
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host " DONE." -ForegroundColor Green
Write-Host " Zip saved to:" -ForegroundColor Green
Write-Host "   $zip" -ForegroundColor White
Write-Host ""
Write-Host " Open file 04_who_deleted_mic.txt inside the zip first --" -ForegroundColor Cyan
Write-Host " it names the exact process that deleted the Mic." -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to close..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
