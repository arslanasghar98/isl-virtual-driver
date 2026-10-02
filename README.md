<table>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/ca93d971-67dc-41dd-b945-ab4f372ea72a" /></td>
    <td>Free code signing on Windows provided by <a href="https://signpath.io">SignPath.io</a>, certificate by <a href="https://signpath.org">SignPath Foundation</a></td>
  </tr>
</table>

> [!NOTE]
> Software Developers/Organizations: Looking to implement Virtual speakers/mics into your app? For advanced/custom functionality like named pipes, shared memory buffers (for no-latency audio), direct integration with your existing apps, and more; Contact us for quotes on a custom build! contact@mikethetech.com

# Virtual Audio Driver by MikeTheTech

Welcome to the **Virtual Audio Driver by MikeTheTech**! This project provides two key drivers based on the Windows Driver Kit (WDK):

- **Virtual Audio Driver** – Creates a virtual speaker output device and a virtual microphone input device.

Both features in the driver are suitable for remote desktop sessions, headless configurations, streaming setups, and more. They support Windows 10 and Windows 11, including advanced audio features like Windows Sonic (Spatial Sound), Exclusive Mode, Application Priority, and volume control.

<div align="center">
  <img src="https://github.com/user-attachments/assets/1e833f96-5565-4938-a242-b239074012b0" alt="image">
  <img src="https://github.com/user-attachments/assets/db8c23f3-cf2d-409f-ada8-38d0aa8450a8" width="31%" alt="image">
  <img src="https://github.com/user-attachments/assets/8cf14cc2-4ab0-41ad-a6b2-5a77b004a943" width="31%" alt="image">
  <img src="https://github.com/user-attachments/assets/5f2e23cb-75d3-4557-98ff-7c717f47dcdd" width="31%" alt="image">
</div>

## Overview

A virtual audio driver set consists of:

- **Virtual Audio** ("fake" speaker output)  
  - Essential for headless servers, remote desktop streaming, testing audio in environments without physical speakers, etc.

- **Virtual Microphone** ("fake" mic input)  
  - Ideal for streaming setups, voice chat tests, combining or routing audio internally, or feeding software-generated audio to apps expecting a microphone input.

By installing these drivers, you can process or forward audio without physical hardware present, making them incredibly useful for various development, testing, and media production scenarios.

---

## Key Features

| Feature                                      | Virtual Speaker                                                                                                                                                                          | Virtual Microphone                                                                                                                              |
|----------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| **Emulated Device**                          | Emulates a speaker device recognized by Windows.                                                                                                                                         | Emulates a microphone device recognized by Windows.                                                                                             |
| **Supported Audio Formats**                  | **8-bit, 8000 Hz** (lowest quality) up to **32-bit, 192,000 Hz** (studio quality). This includes various presets such as Telephone Quality (8-bit, 11025 Hz) and DVD/Studio Quality (16/24/32-bit, up to 192 kHz). | **16-bit 44,100 Hz**, **16-bit 48,000 Hz**, **24-bit 96,000 Hz**, **24-bit 192,000 Hz**, **32-bit 48,000 Hz** (for testing or specialized scenarios). |
| **Spatial Sound Support** (Speaker Only)     | Integrates with Windows Sonic, enabling immersive 3D audio features.                                                                                                                      | Integrated with Audio Enhancements such as Voice Focus and Background Noise Reduction.                                                          |
| **Exclusive Mode and App Priority**          | Applications can claim exclusive control of the device.                                                                                                                                  | Same WDK architecture applies, allowing exclusive access in supported workflows.                                                                 |
| **Volume Level Handling**                    | Handles global and per-application volume changes (Windows mixer).                                                                                                                        | Microphone level adjustments accessible via Windows Sound Settings or audio software.                                                            |
| **High Customizability**                     | Built to be extended with future features and audio enhancements.                                                                                                                         | Allows flexible configuration of sampling rates and bit depths for specialized audio requirements.                                               |

---

## Compatibility

- **OS**: Windows 10 (Build 1903 and above) and Windows 11  
- **Architecture**: x64 (tested); ARM64  

---

## Installation

1. **Open Device Manager**
   - Choose **Audio inputs and outputs**, then in the top **Action** menu, choose **Add Legacy Hardware**.
   - Choose **Install the hardware that I manually select from a list (Advanced)**
   - Choose **Sound, video and game controllers**
   - Choose "Have Disk..." and locate the **VirtualAudioDriver.inf**
   - Continue with the installation.

2. **Verify Installation**  
   - Open **Device Manager**.  
   - Check under **Sound, video and game controllers** for “Virtual Audio Driver” (speaker).  
   - Check under **Audio inputs and outputs** for “Virtual Mic Driver” (microphone).

---

## Usage

### Using the Virtual Speaker

1. **Select as Default Device**  
   - Open **Sound Settings** → **Output** → Choose “Virtual Audio Driver” as your default output device.  
   - Or use the **Volume Mixer** to route specific apps to the virtual speaker.

2. **Remote Desktop or Streaming**  
   - When initiating a remote desktop session, the virtual speaker device can appear as a valid playback device.  
   - Streaming or capture apps can detect the virtual speaker for capturing system audio.

3. **Choosing Quality Settings**  
   - In **Sound Settings**, under **Playback Devices**, right-click the “Virtual Audio Driver” and select **Properties** → **Advanced** tab.  
   - Choose from the newly added sample rates and bit depths (ranging from 8-bit, 8000 Hz to 32-bit, 192,000 Hz) to match your desired use case (e.g., “Telephone Quality,” “DVD Quality,” or “Studio Quality”).

4. **Spatial Sound**  
   - In **Sound Settings**, right-click the device, select **Properties** → **Spatial Sound** tab, and enable **Windows Sonic for Headphones** or another supported format.

### Using the Virtual Microphone

1. **Select as Default Recording Device**  
   - Open **Sound Settings** → **Input** → Choose “Virtual Mic Driver” as your default input device.  
   - Alternatively, in the **Volume Mixer** or your specific application’s audio settings, route or select the “Virtual Mic Driver” for input.

2. **Supported Formats**  
   - The Virtual Microphone Driver supports:
     - **16-bit, 44,100 Hz**
     - **16-bit, 48,000 Hz**
     - **24-bit, 96,000 Hz**
     - **24-bit, 192,000 Hz**
     - **32-bit, 48,000 Hz**

3. **Use Cases**  
   - **Voice Chat / Conference Apps**: Emulate or inject audio into Zoom, Teams, Discord, etc.  
   - **Streaming / Broadcasting**: Feed application-generated audio to OBS, XSplit, or other streaming tools.  
   - **Audio Testing**: Confirm that your software or game engine’s microphone-handling logic works without real hardware.

4. **Volume & Level Controls**  
   - Adjust input levels in **Sound Settings** → **Recording** tab.  
   - Per-app mic levels can be configured in certain software or system volume mixers (where supported).

---

## Configuration

- **Exclusive Mode** (Speaker and Mic)  
  By default, shared mode is enabled. For real-time, low-latency usage, open device properties, go to the **Advanced** tab, and uncheck “Allow applications to take exclusive control.”

- **Application Priority**  
  Supported through Windows APIs. To prioritize a specific application for either the speaker or microphone, configure it via Windows advanced sound options or in your audio software.

- **Volume/Level Management**  
  - For the Virtual Speaker, adjust in the main Sound Settings or the Volume Mixer.  
  - For the Virtual Microphone, adjust input levels in the Recording tab of Sound Settings or in your audio software’s device preferences.

---

## Stream Engagement Notification (User-Mode Integration)

The driver publishes **named kernel notification events** so user-mode applications can detect,
without polling, when the virtual microphone or the virtual speaker is actually in use.

### Event Names

| Event (Win32 name)                  | Direction        | Signalled while                                   |
|-------------------------------------|------------------|---------------------------------------------------|
| `Global\CallJoynaMicEngaged`        | capture (mic)    | at least one **CallJoyna Mic** capture stream is in `KSSTATE_RUN` |
| `Global\ISLMicEngaged`              | capture (mic)    | identical to `CallJoynaMicEngaged` (legacy name, kept for compatibility) |
| `Global\CallJoynaSpeakerEngaged`    | render (speaker) | at least one **CallJoyna Speaker** render stream is in `KSSTATE_RUN` |

Kernel object paths are `\BaseNamedObjects\Global\<name>`. All three are manual-reset
notification events created by the driver at adapter start in the **cleared** state.
`ISLMicEngaged` and `CallJoynaMicEngaged` are two distinct named objects that are always
set and cleared together; new code should use the `CallJoyna*` names.

### Semantics (2.0.18+)

The driver keeps one counter per direction (`micEngagedCount`, `speakerEngagedCount`):

1. A wave stream entering `KSSTATE_RUN` from any non-RUN state adds **exactly one** to its
   direction's counter. A RUN -> RUN request does not double count.
2. `RUN -> PAUSE`, `RUN -> STOP`, `RUN -> ACQUIRE`, and stream destruction while running
   each remove that stream's contribution **exactly once** (a per-stream flag guards this).
   `PAUSE -> RUN` adds it back. Consequently `count == number of streams currently running`.
3. The event is **set whenever the counter is >= 1** and **cleared when it reaches 0**.
   There is no startup suppression window any more (versions <= 2.0.17 ignored engagement
   for the first 5 s after driver start while still incrementing the counter, so the event
   and the counter could disagree; that behaviour was removed in 2.0.18).
4. The live counter values are also readable through the telemetry property (see below).

### Usage Example (C#/.NET)

```csharp
using System.Threading;

// Wait for the CallJoyna Mic to become engaged
EventWaitHandle micEvent = new EventWaitHandle(
    false,
    EventResetMode.ManualReset,
    "Global\\CallJoynaMicEngaged"
);

while (true)
{
    micEvent.WaitOne();  // Blocks until mic is engaged
    Console.WriteLine("CallJoyna Mic is now active - start recording!");

    // Wait for mic to disengage
    while (micEvent.WaitOne(100)) { }  // Polling with timeout
    Console.WriteLine("CallJoyna Mic stopped - stop recording!");
}
```

### Usage Example (Node.js with native addon)

```javascript
// Requires a native addon to wait on Windows kernel events
const micEvent = new WaitableEvent('Global\\CallJoynaMicEngaged');
micEvent.on('signaled', () => console.log('Mic engaged!'));
micEvent.on('cleared', () => console.log('Mic disengaged!'));

const spkEvent = new WaitableEvent('Global\\CallJoynaSpeakerEngaged');
spkEvent.on('signaled', () => console.log('Speaker engaged!'));
```

### Advantages Over Polling

| Approach | Latency | CPU Usage |
|----------|---------|-----------|
| Polling (500ms) | ~250ms average | Continuous |
| **Event-Driven (CallJoyna)** | **<1ms** | **Zero when idle** |

---

## Loopback Buffer Reset Semantics (2.0.18+)

Speaker audio reaches the virtual microphone through a kernel-mode ring buffer
(28,672 bytes = 7168 frames of 48 kHz / 16-bit / stereo, ~150 ms) guarded by a spinlock.
Reads are gated by a preroll: silence is produced until 2048 frames (~42 ms) are queued,
and the gate re-arms if the queue drops below 512 frames (~10 ms).

The ring is **zeroed and fully reset** (read/write positions, bytes-available and the
preroll gate) at these points:

| Trigger | Where |
|---------|-------|
| A render (speaker) stream is created / its format is set | `SetLoopbackFormat` (unchanged) |
| A **capture (mic) stream enters `KSSTATE_RUN` from a non-RUN state** | `ResetLoopbackBuffer`, called from the capture `SetState(KSSTATE_RUN)` path (**new in 2.0.18**) |

The second reset guarantees that a new (or resumed) microphone session never starts by
replaying up to ~150 ms of stale speaker audio that was queued while nothing was capturing.
The reset happens before the capture stream's DMA timer is started and takes the same
spinlock as the render-side writer, so it cannot tear a concurrent write.

Note: the reset is per capture stream transition, not per "first" stream. If a second
application starts capturing from CallJoyna Mic while a first one is already running, the
first one will observe one preroll gap (~42 ms of silence) at that moment.

---

## Telemetry Property (`KSPROPSETID_CallJoynaTelemetry`)

Both topology filters (**CallJoyna Speaker** and **CallJoyna Mic**) expose a private,
filter-scoped, GET-only KS property that returns a consistent snapshot of the driver's
internal counters. Definitions live in
[`Source/Inc/calljoyna_telemetry.h`](Source/Inc/calljoyna_telemetry.h), which is
designed to be included from user-mode projects as well (after `<windows.h>` + `<ks.h>`).

| Item | Value |
|------|-------|
| Property set GUID | `{EA30EDA4-0EDC-4C03-B8B4-6455AFE518E1}` (`KSPROPSETID_CallJoynaTelemetry`) |
| Property id | `KSPROPERTY_CALLJOYNA_TELEMETRY = 1` |
| Supported verbs | `KSPROPERTY_TYPE_GET`, `KSPROPERTY_TYPE_BASICSUPPORT` |
| Value | `CALLJOYNA_TELEMETRY`, 32 bytes, 4-byte packed |

```c
typedef struct _CALLJOYNA_TELEMETRY {
    ULONG cbSize;                 // 0  sizeof(CALLJOYNA_TELEMETRY) = 32, filled by the driver
    ULONG micEngagedCount;        // 4  capture streams currently in KSSTATE_RUN
    ULONG speakerEngagedCount;    // 8  render streams currently in KSSTATE_RUN
    ULONG loopbackBytesAvailable; // 12 bytes queued in the speaker->mic ring right now
    ULONG loopbackWriteCount;     // 16 WriteToLoopbackBuffer calls that wrote >= 1 frame
    ULONG loopbackReadCount;      // 20 ReadFromLoopbackBuffer calls
    ULONG loopbackOverruns;       // 24 writes that had to discard the oldest queued audio
    ULONG loopbackUnderruns;      // 28 reads (after preroll) that had to zero-fill
} CALLJOYNA_TELEMETRY;
```

Notes:

- `loopbackWriteCount`, `loopbackReadCount`, `loopbackOverruns`, `loopbackUnderruns` are
  monotonic 32-bit counters that wrap; take deltas between two reads.
- Silence emitted while the preroll gate is waiting for the initial 2048 frames is by design
  and is **not** counted as an underrun; an underrun is a zero-fill after preroll completed
  (low-water trip or short read).
- Reading with `ValueSize == 0` returns `STATUS_BUFFER_OVERFLOW` (`ERROR_MORE_DATA` in
  user mode) with the required size, like every other KS property.

### User-mode sample (C++, `IOCTL_KS_PROPERTY` on the topology filter)

```cpp
// Link with: setupapi.lib ksuser.lib (or use DeviceIoControl directly, as below)
#include <windows.h>
#include <setupapi.h>
#include <ks.h>
#include <ksmedia.h>
#include <devpkey.h>
#include <string>
#include "calljoyna_telemetry.h"   // from Source/Inc

// Opens the KSCATEGORY_TOPOLOGY interface whose friendly name contains `match`
// ("CallJoyna Speaker" or "CallJoyna Mic"). Either filter returns the same data.
static HANDLE OpenCallJoynaTopology(const wchar_t* match)
{
    HDEVINFO set = SetupDiGetClassDevsW(&KSCATEGORY_TOPOLOGY, nullptr, nullptr,
                                        DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
    if (set == INVALID_HANDLE_VALUE) return INVALID_HANDLE_VALUE;

    HANDLE h = INVALID_HANDLE_VALUE;
    SP_DEVICE_INTERFACE_DATA ifd = { sizeof(ifd) };
    for (DWORD i = 0; SetupDiEnumDeviceInterfaces(set, nullptr, &KSCATEGORY_TOPOLOGY, i, &ifd); ++i)
    {
        DWORD cb = 0;
        SetupDiGetDeviceInterfaceDetailW(set, &ifd, nullptr, 0, &cb, nullptr);
        auto* detail = (SP_DEVICE_INTERFACE_DETAIL_DATA_W*)malloc(cb);
        detail->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_W);
        SP_DEVINFO_DATA dev = { sizeof(dev) };
        if (SetupDiGetDeviceInterfaceDetailW(set, &ifd, detail, cb, nullptr, &dev))
        {
            // The interface path looks like \\?\ROOT#MEDIA#0000#{dda54a40-...}\CallJoynaTopologySpeaker
            // Match on the reference string / friendly name; here: the path contains `match`
            // with spaces removed (e.g. L"TopologySpeaker" / L"TopologyMicArray1"), or read
            // DEVPKEY_DeviceInterface_FriendlyName via SetupDiGetDeviceInterfacePropertyW.
            if (wcsstr(detail->DevicePath, match))
            {
                h = CreateFileW(detail->DevicePath, GENERIC_READ | GENERIC_WRITE,
                                FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                                OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_OVERLAPPED, nullptr);
            }
        }
        free(detail);
        if (h != INVALID_HANDLE_VALUE) break;
    }
    SetupDiDestroyDeviceInfoList(set);
    return h;
}

static bool ReadCallJoynaTelemetry(HANDLE filter, CALLJOYNA_TELEMETRY& out)
{
    KSPROPERTY prop = {};
    prop.Set   = KSPROPSETID_CallJoynaTelemetry;
    prop.Id    = KSPROPERTY_CALLJOYNA_TELEMETRY;
    prop.Flags = KSPROPERTY_TYPE_GET;

    OVERLAPPED ov = {};
    ov.hEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    DWORD returned = 0;
    BOOL ok = DeviceIoControl(filter, IOCTL_KS_PROPERTY,
                              &prop, sizeof(prop), &out, sizeof(out), &returned, &ov);
    if (!ok && GetLastError() == ERROR_IO_PENDING)
        ok = GetOverlappedResult(filter, &ov, &returned, TRUE);
    CloseHandle(ov.hEvent);
    return ok && returned >= sizeof(CALLJOYNA_TELEMETRY);
}

int main()
{
    HANDLE h = OpenCallJoynaTopology(L"TopologySpeaker");   // or L"TopologyMicArray1"
    if (h == INVALID_HANDLE_VALUE) return 1;

    CALLJOYNA_TELEMETRY t = {};
    if (ReadCallJoynaTelemetry(h, t))
        printf("mic=%lu spk=%lu avail=%lu w=%lu r=%lu over=%lu under=%lu\n",
               t.micEngagedCount, t.speakerEngagedCount, t.loopbackBytesAvailable,
               t.loopbackWriteCount, t.loopbackReadCount, t.loopbackOverruns, t.loopbackUnderruns);
    CloseHandle(h);
    return 0;
}
```

The same request can be issued through `IKsControl::KsProperty` on the filter (obtain it
via `KsOpenDefaultDevice` / `IKsControl` from `ksproxy`), which is just a wrapper around
`IOCTL_KS_PROPERTY`.

---

## INF: `PKEY_AudioDevice_NeverSetAsDefaultEndpoint` review

Both endpoints set (`VirtualAudioDriver.inx`, `[...AddReg]` sections):

```
HKR,EP\0,%PKEY_AudioDevice_NeverSetAsDefaultEndpoint%,0x00010001,0x00000304
```

The value is a DWORD mask of data-flow flags and device-role flags
(Microsoft docs: *PKEY_AudioDevice_NeverSetAsDefaultEndpoint*). It only takes effect
because `PKEY_AudioEndpoint_Association` is set in the same `EP\0` subkey (it is, to
`KSNODETYPE_ANY`, for both endpoints):

| Flag                      | Value   | Meaning |
|---------------------------|---------|---------|
| `ROLE_MASK_CONSOLE`       | `0x001` | applies to the **eConsole** role |
| `ROLE_MASK_MULTIMEDIA`    | `0x002` | applies to the **eMultimedia** role |
| `ROLE_MASK_COMMUNICATION` | `0x004` | applies to the **eCommunications** role |
| `FLOW_MASK_RENDER`        | `0x100` | applies to the render (speaker) flow |
| `FLOW_MASK_CAPTURE`       | `0x200` | applies to the capture (mic) flow |

The endpoint can never become the default device for the (flow, role) pairs selected by
the mask, neither through Windows' automatic selection nor through the Sound settings UI.

- **`0x304` (current)** = `FLOW_MASK_RENDER | FLOW_MASK_CAPTURE | ROLE_MASK_COMMUNICATION`.
  CallJoyna Speaker / Mic can never be the **default communications** device (so Teams,
  Zoom, etc. never pick them up implicitly), but the user can still make them the default
  **console/multimedia** device, and any app can still select them explicitly.
- **`0x307`** would add `ROLE_MASK_CONSOLE | ROLE_MASK_MULTIMEDIA`: the endpoints could then
  never be default for *any* role and could only be used by explicit per-application
  selection. That would break users who route system audio to "CallJoyna Speaker" via Sound
  settings, so **the value is intentionally left at `0x304`** in 2.0.18; change it only
  together with an app-side decision on default-device handling.

---

## Changelog

### 2.0.18.0 (2026-09-16)

- **Loopback ring reset on mic RUN**: the speaker->mic ring buffer is zeroed and its preroll
  gate re-armed whenever a capture stream enters `KSSTATE_RUN` from a non-RUN state
  (`CAdapterCommon::ResetLoopbackBuffer`, under the loopback spinlock).
- **Accurate engaged counts**: `RUN -> PAUSE` now decrements and `PAUSE -> RUN` increments;
  each stream contributes at most 1 (`m_bCountedAsEngaged`) and releases it exactly once on
  STOP / ACQUIRE / destruction. `count == running streams` at all times.
- **Startup suppression removed**: the 5 s post-start window during which the mic event was
  not signalled (while the counter still incremented) is gone; the event is set whenever the
  counter is >= 1.
- **New events**: `Global\CallJoynaMicEngaged` (same semantics as the retained
  `Global\ISLMicEngaged`, both always set/cleared together) and
  `Global\CallJoynaSpeakerEngaged` for render streams, backed by `m_lSpeakerEngagedCount`.
- **Telemetry property** `KSPROPSETID_CallJoynaTelemetry`
  `{EA30EDA4-0EDC-4C03-B8B4-6455AFE518E1}` / id 1 (GET + BASICSUPPORT) on both topology
  filters, returning `CALLJOYNA_TELEMETRY` (engaged counts, ring bytes available,
  write/read call counts, overruns, underruns). Header: `Source/Inc/calljoyna_telemetry.h`.
- `DriverVer` bumped to `09/16/2026, 2.0.18.0`.
- `PKEY_AudioDevice_NeverSetAsDefaultEndpoint` reviewed and intentionally kept at `0x304`
  (see above).

---

## Building the Driver

### Prerequisites

1. **Visual Studio 2019/2022** with C++ workload
2. **Windows Driver Kit (WDK)** for Windows 10/11
3. **Windows SDK** matching your WDK version

### Build Steps

#### Using Visual Studio

1. Open `VirtualAudioDriver.sln` in Visual Studio
2. Select **Release | x64** configuration
3. Build Solution (Ctrl+Shift+B)

#### Using Command Line (MSBuild)

```powershell
# Find your MSBuild path (adjust for your VS installation)
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"

# Build Release x64
& $msbuild VirtualAudioDriver.sln /p:Configuration=Release /p:Platform=x64 /t:Rebuild
```

### Build Output

After successful build, files are located at:
- `x64\Release\virtualaudiodriver.sys` - The driver binary
- `x64\Release\virtualaudiodriver.pdb` - Debug symbols
- `DriverPackage\VirtualAudioDriver.inf` - Installation INF file

---

## Driver Installation

### Method 1: Using Device Manager (Recommended)

1. Open **Device Manager** (Win+X → Device Manager)
2. Select **Sound, video and game controllers**
3. Action menu → **Add legacy hardware**
4. Choose **Install the hardware that I manually select from a list (Advanced)**
5. Select **Sound, video and game controllers**
6. Click **Have Disk...** and browse to `DriverPackage\VirtualAudioDriver.inf`
7. Complete the installation

### Method 2: Using pnputil (Command Line)

```powershell
# Run as Administrator
# Install the driver
pnputil /add-driver "DriverPackage\VirtualAudioDriver.inf" /install

# Create the device instance
devcon install "DriverPackage\VirtualAudioDriver.inf" ROOT\VirtualAudioDriver
```

### Uninstalling the Driver

```powershell
# Run as Administrator
# Remove the device
devcon remove ROOT\VirtualAudioDriver

# Or use Device Manager:
# 1. Right-click on "ISL Audio" in Device Manager
# 2. Select "Uninstall device"
# 3. Check "Delete the driver software for this device"
```

---

## Future Plans

- **Advanced Diagnostics**: Logging and debugging tools
- **New Modes & Additional Formats**: Continued expansion of supported audio qualities.
- **Additional Features**: Such as Automatic Volume Leveling (AVL), further spatial audio improvements, and custom routing tools.

> This project is maintained and actively improved. We welcome contributions, suggestions, and issue reports!

---

**Thank you for using the Virtual Audio Driver!**  
Feel free to open issues or submit pull requests if you encounter any problems or have ideas to share. Happy audio routing!
