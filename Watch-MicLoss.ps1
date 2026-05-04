<#
.SYNOPSIS
    Continuously watch for CallJoyna Mic disappearing. Auto-capture
    setupapi/events/MMDevices state at the exact moment of loss.

.DESCRIPTION
    Run elevated. Leave it running in a window while you work.

    Polls every 2 seconds. When the CallJoyna Mic transitions from
    present -> missing, immediately captures a focused diagnostic
    snapshot to Desktop\CallJoyna-MicLoss-Watch-<COMPUTER>\<TIMESTAMP>\.
    Continues running so it can catch repeat occurrences.

    Stop with Ctrl+C.
#>

#Requires -Version 5.0

# Self-elevate
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File",$PSCommandPath)
    return
}

$ErrorActionPreference = 'Continue'
$desk = [Environment]::GetFolderPath("Desktop")
$sessionRoot = Join-Path $desk "CallJoyna-MicLoss-Watch-$env:COMPUTERNAME"
New-Item -ItemType Directory -Path $sessionRoot -Force | Out-Null

# Track setupapi.dev.log size so we can extract only the delta when loss happens
$setupApiPath = 'C:\Windows\INF\setupapi.dev.log'
function Get-SetupApiSize { (Get-Item $setupApiPath -ErrorAction SilentlyContinue).Length }
function Get-SetupApiTail {
    param([long]$FromOffset)
    if (-not (Test-Path $setupApiPath)) { return "" }
    $size = Get-SetupApiSize
    if ($size -le $FromOffset) { return "" }
    try {
        $fs = [System.IO.File]::Open($setupApiPath, 'Open', 'Read', 'ReadWrite')
        $null = $fs.Seek($FromOffset, 'Begin')
        $bytes = New-Object byte[] ($size - $FromOffset)
        $null = $fs.Read($bytes, 0, $bytes.Length)
        $fs.Close()
        return [System.Text.Encoding]::UTF8.GetString($bytes)
    } catch { return "" }
}

function Get-MicState {
    $dev = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {
        $_.FriendlyName -like '*CallJoyna Mic*'
    } | Select-Object -First 1
    if ($dev) {
        return [pscustomobject]@{ Present=$true; InstanceId=$dev.InstanceId; Status=$dev.Status }
    } else {
        return [pscustomobject]@{ Present=$false; InstanceId=$null; Status=$null }
    }
}

function Capture-Snapshot {
    param([datetime]$LossTime, [long]$BaselineOffset, [datetime]$BaselineTime)

    $stamp = $LossTime.ToString("yyyyMMdd-HHmmss")
    $dir = Join-Path $sessionRoot $stamp
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    # 0. Header
    @"
Loss detected at: $LossTime
Watcher started at: $BaselineTime
Computer: $env:COMPUTERNAME
"@ | Out-File "$dir\00_loss_event.txt" -Encoding UTF8

    # 1. PnP state right now (post-loss)
    "=== Get-PnpDevice -- CallJoyna only ===" | Out-File "$dir\01_post_pnp.txt" -Encoding UTF8
    Get-PnpDevice -ErrorAction SilentlyContinue |
        Where-Object { $_.FriendlyName -like '*CallJoyna*' -or $_.HardwareId -match 'VirtualAudioDriver' } |
        Format-List FriendlyName, InstanceId, Status, Class, Problem, ProblemDescription, ConfigManagerErrorCode |
        Out-File "$dir\01_post_pnp.txt" -Append -Encoding UTF8

    "" | Out-File "$dir\01_post_pnp.txt" -Append
    "=== pnputil /enum-devices /class MEDIA (includes hidden) ===" | Out-File "$dir\01_post_pnp.txt" -Append
    & pnputil /enum-devices /class MEDIA 2>&1 | Out-File "$dir\01_post_pnp.txt" -Append -Encoding UTF8

    "" | Out-File "$dir\01_post_pnp.txt" -Append
    "=== pnputil /enum-devices /class AudioEndpoint (includes hidden) ===" | Out-File "$dir\01_post_pnp.txt" -Append
    & pnputil /enum-devices /class AudioEndpoint 2>&1 |
        Select-String -Pattern 'CallJoyna' -Context 0,8 |
        Out-File "$dir\01_post_pnp.txt" -Append -Encoding UTF8

    # 2. MMDevices state for CallJoyna -- the key file
    "=== MMDevices CallJoyna entries with DeviceState ===" | Out-File "$dir\02_mmdevices.txt" -Encoding UTF8
    foreach ($cat in 'Render','Capture') {
        $eps = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\$cat" -ErrorAction SilentlyContinue
        foreach ($ep in $eps) {
            $name = (Get-ItemProperty "$($ep.PSPath)\Properties" -Name "{a45c254e-df1c-4efd-8020-67d146a850e0},2" -ErrorAction SilentlyContinue)."{a45c254e-df1c-4efd-8020-67d146a850e0},2"
            if ($name -like '*CallJoyna*') {
                $state = (Get-ItemProperty $ep.PSPath -Name DeviceState -ErrorAction SilentlyContinue).DeviceState
                $stateName = switch ($state) {1{'Active'} 2{'Disabled'} 4{'NotPresent'} 8{'Unplugged'} default {"Unknown($state)"}}
                "  $cat / $name" | Out-File "$dir\02_mmdevices.txt" -Append
                "    EndpointId   : $($ep.PSChildName)" | Out-File "$dir\02_mmdevices.txt" -Append
                "    DeviceState  : $stateName ($state)" | Out-File "$dir\02_mmdevices.txt" -Append
                "" | Out-File "$dir\02_mmdevices.txt" -Append
            }
        }
    }

    # 3. setupapi delta since baseline -- byte-level tail capture
    $tail = Get-SetupApiTail -FromOffset $BaselineOffset
    "=== setupapi.dev.log bytes since watcher started (offset $BaselineOffset) ===" | Out-File "$dir\03_setupapi_delta.log" -Encoding UTF8
    "Total new bytes: $($tail.Length)" | Out-File "$dir\03_setupapi_delta.log" -Append
    "" | Out-File "$dir\03_setupapi_delta.log" -Append
    if ($tail) {
        $regex = [regex]'(?ms)>>>\s+\[.*?\n.*?<<<\s+\[.*?\]\s*[^\r\n]*'
        $matches = $regex.Matches($tail)
        "(found $($matches.Count) section blocks in delta)" | Out-File "$dir\03_setupapi_delta.log" -Append
        "" | Out-File "$dir\03_setupapi_delta.log" -Append
        foreach ($m in $matches) {
            $m.Value | Out-File "$dir\03_setupapi_delta.log" -Append -Encoding UTF8
            "------------------------------------------------------------" | Out-File "$dir\03_setupapi_delta.log" -Append
        }
    }

    # 4. Highlight Delete Device blocks for capture-flow
    "=== [Delete Device] blocks targeting capture endpoint (SWD\MMDEVAPI\{0.0.1...}) ===" | Out-File "$dir\04_who_deleted_mic.txt" -Encoding UTF8
    "" | Out-File "$dir\04_who_deleted_mic.txt" -Append
    if ($tail) {
        $regex = [regex]'(?ms)>>>\s+\[Delete Device.*?\n.*?<<<\s+\[.*?\]\s*[^\r\n]*'
        $matches = $regex.Matches($tail)
        $hits = $matches | Where-Object { $_.Value -match 'MMDEVAPI\\\{0\.0\.1' -or $_.Value -match 'CallJoyna' -or $_.Value -match 'ROOT\\MEDIA' }
        if ($hits.Count -eq 0) {
            "(no [Delete Device] blocks found in delta -- the loss happened via a non-PnP path, e.g. AudioEndpointBuilder marking endpoint NotPresent in MMDevices)" | Out-File "$dir\04_who_deleted_mic.txt" -Append
        } else {
            foreach ($h in $hits) {
                $cmd = [regex]::Match($h.Value, '(?m)^\s*cmd:\s*(.+)$')
                $hdr = [regex]::Match($h.Value, '>>>\s+\[(.+?)\]')
                if ($hdr.Success) { ">>> $($hdr.Groups[1].Value)" | Out-File "$dir\04_who_deleted_mic.txt" -Append }
                if ($cmd.Success) { "   COMMAND: $($cmd.Groups[1].Value.Trim())" | Out-File "$dir\04_who_deleted_mic.txt" -Append }
                "   FULL BLOCK:" | Out-File "$dir\04_who_deleted_mic.txt" -Append
                $h.Value | Out-File "$dir\04_who_deleted_mic.txt" -Append
                "------------------------------------------------------------" | Out-File "$dir\04_who_deleted_mic.txt" -Append
            }
        }
    } else {
        "(no setupapi delta at all -- confirms non-PnP removal path)" | Out-File "$dir\04_who_deleted_mic.txt" -Append
    }

    # 5. Recent System events around the loss
    $eventStart = $BaselineTime
    "=== System events from $eventStart onward (audio/PnP related) ===" | Out-File "$dir\05_events.txt" -Encoding UTF8
    Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=$eventStart} -ErrorAction SilentlyContinue |
        Where-Object { $_.ProviderName -match 'Audio|MMDevAPI|Kernel-PnP|UserPnp|Ks|PortCls|Service Control Manager|UMDF|USB|HID' -or $_.Message -match 'CallJoyna|VirtualAudio|MMDEVAPI' } |
        Sort-Object TimeCreated |
        Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, @{N='Msg';E={$_.Message -replace "\s+"," " -replace "(.{500}).+",'$1...'}} |
        Format-List | Out-File "$dir\05_events.txt" -Append -Encoding UTF8

    # 6. Recent USB / device-arrival events to correlate with the trigger action
    "=== Recent USB / device-arrival/removal events (last 2 minutes) ===" | Out-File "$dir\06_usb_events.txt" -Encoding UTF8
    $usbStart = $LossTime.AddMinutes(-2)
    Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=$usbStart} -ErrorAction SilentlyContinue |
        Where-Object { $_.Id -in @(20001,20003,400,410,411,412,219,225) -or $_.ProviderName -match 'USB|HID|Kernel-PnP|UserPnp' } |
        Sort-Object TimeCreated |
        Select-Object TimeCreated, Id, ProviderName, @{N='Msg';E={$_.Message -replace "\s+"," " -replace "(.{300}).+",'$1...'}} |
        Format-List | Out-File "$dir\06_usb_events.txt" -Append -Encoding UTF8
}

# ---------------------------------------------------------------- main loop
Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host " CallJoyna Mic-Loss WATCHER" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host " Polling every 2 seconds. Output dir: $sessionRoot" -ForegroundColor Gray
Write-Host " Stop with Ctrl+C." -ForegroundColor Gray
Write-Host ""

$baselineOffset = Get-SetupApiSize
$baselineTime = Get-Date
Write-Host "[$baselineTime] Watcher started. setupapi baseline offset: $baselineOffset bytes" -ForegroundColor Green

$lastPresent = $null
while ($true) {
    $state = Get-MicState
    $now = Get-Date

    # First-iteration init
    if ($null -eq $lastPresent) {
        $lastPresent = $state.Present
        if ($state.Present) {
            Write-Host "[$now] Mic IS present at start. Watching for loss..." -ForegroundColor Green
        } else {
            Write-Host "[$now] Mic is NOT present at start. Watching for return then loss..." -ForegroundColor Yellow
        }
    }

    # Transition: present -> missing  (THE event we want)
    if ($lastPresent -and -not $state.Present) {
        Write-Host ""
        Write-Host "[$now] !!! LOSS DETECTED !!! capturing..." -ForegroundColor Red
        Capture-Snapshot -LossTime $now -BaselineOffset $baselineOffset -BaselineTime $baselineTime
        $stampDir = $now.ToString("yyyyMMdd-HHmmss")
        Write-Host "[$now] Captured to $sessionRoot\$stampDir\" -ForegroundColor Green
        Write-Host ""
        # Reset baseline so the next loss has a fresh delta window
        $baselineOffset = Get-SetupApiSize
        $baselineTime = $now
    }

    # Transition: missing -> present  (informational; helps confirm reinstall/reboot worked)
    if (-not $lastPresent -and $state.Present) {
        Write-Host "[$now] Mic returned ($($state.InstanceId))" -ForegroundColor Cyan
    }

    $lastPresent = $state.Present
    Start-Sleep -Seconds 2
}
