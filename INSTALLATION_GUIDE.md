# Virtual Audio Driver - Installation Guide

This guide explains how to install and uninstall the Virtual Audio Driver (ISL Speaker/Mic).

## Contents

- `x64\Debug\virtualaudiodriver.sys` - The driver binary
- `x64\Debug\VirtualAudioDriver.inf` - Driver installation information file
- `Install-VirtualAudioDriver.ps1` - Silent installation script
- `Uninstall-VirtualAudioDriver.ps1` - Uninstallation script

## Prerequisites

- Windows 10/11 (64-bit)
- Administrator privileges
- Disabled Driver Signature Enforcement (for unsigned drivers)

## Disabling Driver Signature Enforcement

**IMPORTANT**: This driver is unsigned and requires driver signature enforcement to be disabled.

### Option 1: Temporary Disable (Until Next Reboot)

1. Open Command Prompt or PowerShell as Administrator
2. Run: `bcdedit /set testsigning on`
3. Reboot your computer
4. You should see "Test Mode" watermark on desktop

### Option 2: One-Time Disable (Manual)

1. Hold Shift and click Restart from the Start menu
2. Select "Troubleshoot" > "Advanced options" > "Startup Settings"
3. Click "Restart"
4. Press F7 to select "Disable driver signature enforcement"
5. Windows will boot with signature enforcement disabled (one-time only)

## Installation Methods

### Method 1: Automated Installation (Recommended)

1. **Right-click** on `Install-VirtualAudioDriver.ps1`
2. Select **"Run with PowerShell"** or **"Run as Administrator"**
3. Follow the on-screen instructions
4. If the device doesn't appear automatically, **reboot** or use Method 3

### Method 2: Manual Installation via Command Line

Open PowerShell as Administrator and run:

```powershell
cd "D:\Datics\Virtual-Audio-Driver"
.\Install-VirtualAudioDriver.ps1
```

### Method 3: Manual Installation via Device Manager

If the automated installation doesn't create the device automatically:

1. Open **Device Manager** (devmgmt.msc)
2. Click **Action** > **Add legacy hardware**
3. Click **Next** > Select **Install the hardware that I manually select from a list**
4. Select **Sound, video and game controllers** > Click **Next**
5. Click **Have Disk...**
6. Click **Browse...** and navigate to: `D:\Datics\Virtual-Audio-Driver\x64\Debug\`
7. Select `VirtualAudioDriver.inf` and click **Open**
8. Click **OK**
9. Select **ISL Speaker** from the list
10. Click **Next** > **Next** > **Finish**

## Verification

After installation, you should see the following audio devices in Sound Settings:

- **ISL Speaker** - Virtual audio output device
- **ISL Mic** - Virtual audio input device (microphone)

To verify:
1. Right-click the speaker icon in the system tray
2. Select **Open Sound settings**
3. Check both **Output** and **Input** device lists

## Uninstallation

### Automated Uninstallation (Recommended)

1. **Right-click** on `Uninstall-VirtualAudioDriver.ps1`
2. Select **"Run with PowerShell"** or **"Run as Administrator"**
3. Follow the on-screen instructions

### Manual Uninstallation

1. Open **Device Manager**
2. Expand **Sound, video and game controllers**
3. Right-click on **ISL Speaker** (or any ISL device)
4. Select **Uninstall device**
5. Check **Delete the driver software for this device**
6. Click **Uninstall**

Then remove the driver from the driver store:

```powershell
# Find the driver
pnputil /enum-drivers | Select-String -Pattern "virtualaudiodriver" -Context 0,5

# Remove it (replace oemXX.inf with the actual published name)
pnputil /delete-driver oemXX.inf /uninstall /force
```

## Troubleshooting

### Driver Installation Fails

**Issue**: Error during installation
**Solution**: Ensure you've disabled Driver Signature Enforcement (see above)

### Device Doesn't Appear

**Issue**: Installation completes but no audio device appears
**Solution**:
1. Reboot the computer
2. OR use Manual Installation Method 3

### Audio Not Working

**Issue**: Device appears but no audio
**Solution**:
1. Set ISL Speaker as the default playback device
2. Set ISL Mic as the default recording device
3. Check volume levels aren't muted

### "Test Mode" Watermark

**Issue**: Windows shows "Test Mode" watermark
**Solution**: This is normal when test signing is enabled. To remove it (will break unsigned driver):
```cmd
bcdedit /set testsigning off
```
Then reboot.

### Code 52 Error (Cannot verify signature)

**Issue**: Device Manager shows Code 52
**Solution**: Enable test mode:
```cmd
bcdedit /set testsigning on
```
Then reboot.

## Technical Information

- **Driver Name**: Virtual Audio Driver
- **Hardware ID**: `ROOT\VirtualAudioDriver`
- **Driver Type**: KMDF (Kernel-Mode Driver Framework)
- **KMDF Version**: 1.33
- **Platform**: Desktop (Windows 10/11)
- **Architecture**: x64

## Support

For issues or questions, please check the project documentation or create an issue in the project repository.

---

**WARNING**: This driver is for development/testing purposes. Installing unsigned drivers can pose security risks. Only install drivers from trusted sources.
