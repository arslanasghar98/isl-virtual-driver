<#
.SYNOPSIS
    Collect CallJoyna driver install diagnostics into a single zip.

.DESCRIPTION
    Run elevated. Dumps 11 sections of system + audio + driver state, zips
    them to Desktop. Email the zip back to claudeservice@datics.ai.

    Pure built-in cmdlets only. No external modules required.
#>

#Requires -Version 5.0

# Self-elevate
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevating..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File",$PSCommandPath)
    return
}

$ErrorActionPreference = 'Continue'
$stamp = Get-Date -Format "yyyyMMdd-HHmm"
$work  = Join-Path $env:TEMP "CallJoynaDiag-$stamp"
$zip   = Join-Path ([Environment]::GetFolderPath("Desktop")) "CallJoyna-Diag-$env:COMPUTERNAME-$stamp.zip"
New-Item -ItemType Directory -Path $work -Force | Out-Null

function Section {
    param([string]$Name, [scriptblock]$Body)
    $file = Join-Path $work $Name
    Write-Host "[*] $Name" -ForegroundColor Cyan
    try {
        & $Body *>&1 | Out-File -FilePath $file -Encoding UTF8 -Width 500
    } catch {
        "ERROR in $Name : $_" | Out-File -FilePath $file -Encoding UTF8
    }
}

# ------------------------------------------------------------------ 00 sysinfo
Section "00_sysinfo.txt" {
    "=== Date ==="
    Get-Date
    "Timezone: $((Get-TimeZone).DisplayName)"
    ""
    "=== Computer ==="
    Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, WindowsBuildLabEx, OsBuildNumber, OsHardwareAbstractionLayer, CsManufacturer, CsModel, CsSystemType, OsArchitecture, BiosFirmwareType, CsTotalPhysicalMemory | Format-List
    "OS: $([Environment]::OSVersion.VersionString)"
    "64-bit OS: $([Environment]::Is64BitOperatingSystem)"
    "PowerShell: $($PSVersionTable.PSVersion)"
    ""
    "=== CPU ==="
    Get-CimInstance Win32_Processor | Select-Object Name, Architecture, NumberOfCores, NumberOfLogicalProcessors | Format-List
}

# -------------------------------------------------------- 01 security state
Section "01_security_state.txt" {
    "=== Secure Boot ==="
    try { "SecureBoot: $(Confirm-SecureBootUEFI -ErrorAction Stop)" } catch { "SecureBoot: not applicable / legacy BIOS ($_)" }
    ""
    "=== bcdedit /enum {current} ==="
    & bcdedit /enum '{current}' 2>&1
    ""
    "=== DeviceGuard / HVCI / VBS ==="
    Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction SilentlyContinue | Select-Object * | Format-List
    ""
    "=== Test-mode / Integrity ==="
    & bcdedit /enum 2>&1 | Select-String -Pattern "testsigning|nointegritychecks|integrityservices|loadoptions|hypervisorlaunchtype" -CaseSensitive:$false
}

# ------------------------------------------------------- 02 PnP devices
Section "02_pnp_devices.txt" {
    "=== CallJoyna devices (FriendlyName match) ==="
    $callJoyna = Get-PnpDevice -FriendlyName "*CallJoyna*" -ErrorAction SilentlyContinue
    if ($callJoyna) {
        $callJoyna | Format-List FriendlyName, InstanceId, Status, Class, Problem, ProblemDescription, ConfigManagerErrorCode, Manufacturer
    } else {
        "(no devices match *CallJoyna*)"
    }
    ""
    "=== ROOT\MEDIA devices (any) ==="
    Get-PnpDevice -InstanceId 'ROOT\MEDIA\*' -ErrorAction SilentlyContinue | Format-List FriendlyName, InstanceId, Status, Problem, ProblemDescription
    ""
    "=== HardwareId match for VirtualAudioDriver ==="
    Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.HardwareId -match 'VirtualAudioDriver' } | Format-List FriendlyName, InstanceId, Status, Problem, HardwareId
    ""
    "=== Per-device DEVPKEY props (driver version, INF, problem) ==="
    foreach ($d in $callJoyna) {
        "--- $($d.FriendlyName)  $($d.InstanceId) ---"
        Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName DEVPKEY_Device_DriverVersion, DEVPKEY_Device_DriverDate, DEVPKEY_Device_DriverInfPath, DEVPKEY_Device_Class, DEVPKEY_Device_DevNodeStatus, DEVPKEY_Device_ProblemCode, DEVPKEY_Device_DriverProvider -ErrorAction SilentlyContinue | Format-List KeyName, Type, Data
        ""
    }
    "=== Children of CallJoyna parent (pnputil /enum-devices /relations) ==="
    foreach ($d in ($callJoyna | Where-Object { $_.InstanceId -like 'ROOT\MEDIA\*' })) {
        "--- $($d.InstanceId) ---"
        & pnputil /enum-devices /instanceid $d.InstanceId /relations 2>&1
        ""
    }
    "=== All MEDIA-class devices ==="
    Get-PnpDevice -Class MEDIA -ErrorAction SilentlyContinue | Format-Table -AutoSize FriendlyName, Status, InstanceId
    ""
    "=== All AudioEndpoint-class devices ==="
    Get-PnpDevice -Class AudioEndpoint -ErrorAction SilentlyContinue | Format-Table -AutoSize FriendlyName, Status, InstanceId
}

# ------------------------------------------------------ 03 driver store
Section "03_driver_store.txt" {
    "=== pnputil /enum-drivers (CallJoyna only) ==="
    $all = & pnputil /enum-drivers 2>&1 | Out-String
    $blocks = $all -split "(?ms)(?=^Published Name:)"
    $blocks | Where-Object { $_ -match 'CallJoyna|virtualaudiodriver\.inf' }
    ""
    "=== INF copies in C:\Windows\INF\ that mention CallJoyna ==="
    $hits = Get-ChildItem 'C:\Windows\INF\oem*.inf' -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $c = Get-Content $_.FullName -Raw -ErrorAction Stop
            if ($c -match 'VirtualAudioDriver|CallJoyna') {
                [pscustomobject]@{ Path=$_.FullName; Size=$_.Length; Modified=$_.LastWriteTime; FullContent=$c }
            }
        } catch {}
    }
    foreach ($h in $hits) {
        "--- $($h.Path)  Size=$($h.Size)  Modified=$($h.Modified) ---"
        $h.FullContent
        "================================================================"
        ""
    }
    ""
    "=== DriverStore FileRepository entries ==="
    $repo = Get-ChildItem 'C:\Windows\System32\DriverStore\FileRepository\virtualaudiodriver.inf_*' -Directory -ErrorAction SilentlyContinue
    foreach ($r in $repo) {
        "--- $($r.FullName) ---"
        Get-ChildItem $r.FullName | Format-Table -AutoSize Name, Length, LastWriteTime
        foreach ($f in (Get-ChildItem $r.FullName -Filter "*.sys"), (Get-ChildItem $r.FullName -Filter "*.cat")) {
            try {
                $h = Get-FileHash $f.FullName -Algorithm SHA256 -ErrorAction Stop
                "$($f.Name) SHA256: $($h.Hash)"
                $sig = Get-AuthenticodeSignature $f.FullName -ErrorAction SilentlyContinue
                "$($f.Name) SignerSubject: $($sig.SignerCertificate.Subject)"
                "$($f.Name) SignatureStatus: $($sig.Status)"
            } catch {}
        }
        ""
    }
}

# ----------------------------------------------------- 04 MMDevices reg
Section "04_mmdevices.reg.txt" {
    $tmp1 = Join-Path $env:TEMP "_mmdev_render.reg"
    $tmp2 = Join-Path $env:TEMP "_mmdev_capture.reg"
    & reg export 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'  $tmp1 /y 2>&1 | Out-Null
    & reg export 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture' $tmp2 /y 2>&1 | Out-Null
    "=== Render endpoints with CallJoyna (filtered) ==="
    if (Test-Path $tmp1) { Get-Content $tmp1 | Select-String -Pattern 'CallJoyna|VirtualAudioDriver' -Context 0,5 }
    ""
    "=== Capture endpoints with CallJoyna (filtered) ==="
    if (Test-Path $tmp2) { Get-Content $tmp2 | Select-String -Pattern 'CallJoyna|VirtualAudioDriver' -Context 0,5 }
    ""
    "=== Live MMDevices CallJoyna entries ==="
    foreach ($cat in 'Render','Capture') {
        $eps = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\$cat" -ErrorAction SilentlyContinue
        foreach ($ep in $eps) {
            $name = (Get-ItemProperty "$($ep.PSPath)\Properties" -Name '{a45c254e-df1c-4efd-8020-67d146a850e0},2' -ErrorAction SilentlyContinue).'{a45c254e-df1c-4efd-8020-67d146a850e0},2'
            if ($name -like '*CallJoyna*') {
                $state = (Get-ItemProperty $ep.PSPath -Name DeviceState -ErrorAction SilentlyContinue).DeviceState
                "  $cat / $name  -> EndpointId=$($ep.PSChildName)  DeviceState=$state"
            }
        }
    }
    Remove-Item $tmp1,$tmp2 -ErrorAction SilentlyContinue
}

# --------------------------------------------- 05 setupapi.dev.log slice
Section "05_setupapi_calljoyna.log" {
    $logs = @('C:\Windows\INF\setupapi.dev.log')
    $logs += Get-ChildItem 'C:\Windows\INF\setupapi.dev.log.*.old' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    foreach ($lp in $logs) {
        if (-not (Test-Path $lp)) { continue }
        "########### $lp ###########"
        $content = Get-Content $lp -Raw -ErrorAction SilentlyContinue
        if (-not $content) { "(empty)"; continue }
        # Extract >>> ... <<< blocks that mention CallJoyna or VirtualAudioDriver
        $regex = [regex]'(?ms)>>>\s+\[.*?\n.*?<<<\s+\[.*?\]\s*[^\r\n]*'
        $matches = $regex.Matches($content)
        $hits = $matches | Where-Object { $_.Value -match 'CallJoyna|VirtualAudioDriver|MicArray|TopologyMic' }
        $hits = $hits | Select-Object -Last 50
        "(found $($hits.Count) matching install blocks)"
        ""
        foreach ($m in $hits) {
            $m.Value
            "------------------------------------------------------------"
        }
        ""
        "=== Tail (last 200 lines) of $lp ==="
        Get-Content $lp -Tail 200
        ""
    }
}

# --------------------------------------------- 06 events
Section "06_events.txt" {
    $since = (Get-Date).AddDays(-2)
    "=== System events (last 2 days, audio/PnP related) ==="
    Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=$since} -ErrorAction SilentlyContinue |
        Where-Object { $_.ProviderName -match 'Audio|MMDevAPI|Kernel-PnP|UserPnp|Ks|PortCls|Service Control Manager' -or $_.Message -match 'CallJoyna|VirtualAudio' } |
        Select-Object -First 100 TimeCreated, Id, LevelDisplayName, ProviderName, @{N='Msg';E={$_.Message -replace "\s+"," " -replace "(.{300}).+",'$1...'}} |
        Format-List
    ""
    "=== Application events (MsiInstaller / installer logs) ==="
    Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=$since} -ErrorAction SilentlyContinue |
        Where-Object { $_.ProviderName -match 'MsiInstaller|CallJoyna' -or $_.Message -match 'CallJoyna|VirtualAudio' } |
        Select-Object -First 50 TimeCreated, Id, LevelDisplayName, ProviderName, @{N='Msg';E={$_.Message -replace "\s+"," " -replace "(.{300}).+",'$1...'}} |
        Format-List
}

# --------------------------------------------- 07 services
Section "07_services.txt" {
    "=== Audio services ==="
    Get-Service AudioEndpointBuilder, Audiosrv -ErrorAction SilentlyContinue | Format-List Name, Status, StartType, DependentServices, ServicesDependedOn
    ""
    "=== sc queryex AudioEndpointBuilder ==="
    & sc.exe queryex AudioEndpointBuilder 2>&1
    ""
    "=== sc queryex Audiosrv ==="
    & sc.exe queryex Audiosrv 2>&1
}

# --------------------------------------------- 08 installer log
Section "08_installer_log.txt" {
    $candidates = @(
        "$env:ProgramFiles\CallJoyna\driver-install.log",
        "${env:ProgramFiles(x86)}\CallJoyna\driver-install.log",
        "$env:LOCALAPPDATA\Programs\CallJoyna\driver-install.log",
        "$env:LOCALAPPDATA\CallJoyna\Logs\driver-install.log"
    )
    "=== Looking for driver-install.log ==="
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            "########### FOUND: $c (size=$((Get-Item $c).Length))  modified=$((Get-Item $c).LastWriteTime) ###########"
            Get-Content $c
            ""
        } else {
            "MISSING: $c"
        }
    }
    "=== Recursive search (best-effort) ==="
    Get-ChildItem -Path $env:ProgramFiles, ${env:ProgramFiles(x86)}, "$env:LOCALAPPDATA\Programs" -Filter 'driver-install.log' -Recurse -ErrorAction SilentlyContinue -Depth 3 |
        Format-Table -AutoSize FullName, Length, LastWriteTime
    Get-ChildItem -Path $env:ProgramFiles, ${env:ProgramFiles(x86)}, "$env:LOCALAPPDATA\Programs" -Filter 'driver-uninstall.log' -Recurse -ErrorAction SilentlyContinue -Depth 3 |
        ForEach-Object {
            "########### $($_.FullName) ###########"
            Get-Content $_.FullName
            ""
        }
}

# --------------------------------------------- 09 payload check
Section "09_payload_check.txt" {
    $candidates = @(
        "$env:ProgramFiles\CallJoyna\driver\files\VirtualAudioDriver",
        "${env:ProgramFiles(x86)}\CallJoyna\driver\files\VirtualAudioDriver",
        "$env:LOCALAPPDATA\Programs\CallJoyna\driver\files\VirtualAudioDriver"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            "########### $c ###########"
            Get-ChildItem $c | Format-Table -AutoSize Name, Length, LastWriteTime
            foreach ($f in (Get-ChildItem $c)) {
                if ($f.Extension -in '.sys','.cat') {
                    try {
                        $h = Get-FileHash $f.FullName -Algorithm SHA256
                        $sig = Get-AuthenticodeSignature $f.FullName
                        "$($f.Name)"
                        "  SHA256: $($h.Hash)"
                        "  SignerSubject: $($sig.SignerCertificate.Subject)"
                        "  SignatureStatus: $($sig.Status)"
                        "  StatusMessage: $($sig.StatusMessage)"
                        ""
                    } catch { "ERROR signing-check $($f.Name): $_" }
                }
            }
        } else {
            "MISSING: $c"
        }
    }
}

# --------------------------------------------- 10 policy
Section "10_policy.txt" {
    "=== Active WDAC / Code Integrity policies ==="
    try {
        Get-CimInstance -Namespace root\Microsoft\Windows\CI -ClassName CIPolicy -ErrorAction Stop |
            Format-List PolicyID, FriendlyName, IsActive, IsEnforced, IsEffective
    } catch {
        "No CIPolicy WMI class or no policies present: $_"
    }
    ""
    "=== AppLocker policy (effective, first 4KB) ==="
    try {
        $xml = Get-AppLockerPolicy -Effective -Xml -ErrorAction Stop
        if ($xml) { $xml.Substring(0, [Math]::Min(4096, $xml.Length)) } else { "(empty)" }
    } catch {
        "AppLocker not available or no policy: $_"
    }
    ""
    "=== Defender status (top-line) ==="
    try { Get-MpComputerStatus | Select-Object AMServiceEnabled, AntispywareEnabled, AntivirusEnabled, RealTimeProtectionEnabled, IsTamperProtected, AMEngineVersion | Format-List } catch { "Get-MpComputerStatus unavailable: $_" }
    ""
    "=== Third-party AV (registry) ==="
    Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue | Format-List displayName, productState, pathToSignedReportingExe
}

# ------------------------------------------------------ Bundle
Write-Host ""
Write-Host "[*] Zipping..." -ForegroundColor Cyan
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path "$work\*" -DestinationPath $zip -CompressionLevel Optimal
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host " DONE." -ForegroundColor Green
Write-Host " Zip saved to:" -ForegroundColor Green
Write-Host "   $zip" -ForegroundColor White
Write-Host ""
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to close..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
