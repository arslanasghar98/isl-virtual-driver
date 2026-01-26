# Silent Installation Guide for ISL Audio Driver

This guide explains how to silently install the ISL Speaker and ISL Mic virtual audio drivers from your Electron application.

## Overview

The ISL Audio Driver creates two virtual audio devices:
- **ISL Speaker** - Virtual audio output device
- **ISL Mic** - Virtual microphone input device

## Prerequisites

1. Driver files built for your target architecture (x64 or ARM64):
   - `VirtualAudioDriver.sys`
   - `VirtualAudioDriver.inf`
   - `virtualaudiodriver.cat`

2. Administrator privileges required for driver installation

## Silent Installation Methods

### Method 1: Using PnPUtil (Recommended)

PnPUtil is included with Windows and is the recommended method for silent driver installation.

#### Installation Command

```bash
pnputil /add-driver "path\to\VirtualAudioDriver.inf" /install
```

#### Full Installation Script (PowerShell)

```powershell
# Install driver silently
$infPath = "C:\path\to\your\driver\VirtualAudioDriver.inf"

# Add and install the driver
$result = Start-Process -FilePath "pnputil.exe" -ArgumentList "/add-driver `"$infPath`" /install" -Wait -PassThru -NoNewWindow

if ($result.ExitCode -eq 0) {
    Write-Host "Driver installed successfully"
    exit 0
} else {
    Write-Host "Driver installation failed with exit code: $($result.ExitCode)"
    exit $result.ExitCode
}
```

### Method 2: Using DevCon (Alternative)

DevCon is a command-line tool from the Windows Driver Kit (WDK).

```bash
devcon install "path\to\VirtualAudioDriver.inf" ROOT\VirtualAudioDriver
```

## Electron App Integration

### Step 1: Package Driver Files

Include the driver files in your Electron app's resources directory:

```
your-electron-app/
├── resources/
│   └── drivers/
│       ├── x64/
│       │   ├── VirtualAudioDriver.sys
│       │   ├── VirtualAudioDriver.inf
│       │   └── virtualaudiodriver.cat
│       └── ARM64/
│           ├── VirtualAudioDriver.sys
│           ├── VirtualAudioDriver.inf
│           └── virtualaudiodriver.cat
```

### Step 2: Detect Architecture

```javascript
const os = require('os');
const arch = os.arch(); // 'x64' or 'arm64'
```

### Step 3: Install Driver on App Installation

#### Option A: Using Node.js child_process

```javascript
const { execFile } = require('child_process');
const path = require('path');
const os = require('os');

function installAudioDriver() {
    return new Promise((resolve, reject) => {
        const arch = os.arch();
        const driverPath = path.join(
            process.resourcesPath,
            'drivers',
            arch,
            'VirtualAudioDriver.inf'
        );

        const args = ['/add-driver', driverPath, '/install'];

        execFile('pnputil.exe', args, (error, stdout, stderr) => {
            if (error) {
                console.error('Driver installation failed:', error);
                reject(error);
                return;
            }
            console.log('Driver installed successfully');
            resolve(stdout);
        });
    });
}

// Call during app startup or first run
installAudioDriver()
    .then(() => console.log('ISL Audio Driver ready'))
    .catch(err => console.error('Failed to install driver:', err));
```

#### Option B: Using electron-builder's afterInstall Hook

In your `package.json` or electron-builder configuration:

```json
{
  "build": {
    "afterInstall": "scripts/install-driver.js"
  }
}
```

Create `scripts/install-driver.js`:

```javascript
const { execSync } = require('child_process');
const path = require('path');
const os = require('os');

exports.default = async function(context) {
    if (process.platform !== 'win32') return;

    const arch = os.arch();
    const driverPath = path.join(
        context.appOutDir,
        'resources',
        'drivers',
        arch,
        'VirtualAudioDriver.inf'
    );

    try {
        execSync(`pnputil /add-driver "${driverPath}" /install`, {
            stdio: 'inherit'
        });
        console.log('ISL Audio Driver installed successfully');
    } catch (error) {
        console.error('Failed to install driver:', error);
        // Optionally show error dialog to user
    }
};
```

### Step 4: Request Administrator Privileges

Modify your `package.json` to request admin privileges:

```json
{
  "build": {
    "win": {
      "requestedExecutionLevel": "requireAdministrator"
    }
  }
}
```

Or use electron-sudo for runtime elevation:

```javascript
const sudo = require('sudo-prompt');

function installDriverWithElevation() {
    const options = {
        name: 'ISL Audio Driver Installer'
    };

    const arch = os.arch();
    const driverPath = path.join(
        process.resourcesPath,
        'drivers',
        arch,
        'VirtualAudioDriver.inf'
    );

    const command = `pnputil /add-driver "${driverPath}" /install`;

    sudo.exec(command, options, (error, stdout, stderr) => {
        if (error) {
            console.error('Installation failed:', error);
            return;
        }
        console.log('Driver installed:', stdout);
    });
}
```

## Verification

### Check if Driver is Installed

```javascript
const { exec } = require('child_process');

function isDriverInstalled() {
    return new Promise((resolve) => {
        exec('pnputil /enum-drivers', (error, stdout) => {
            if (error) {
                resolve(false);
                return;
            }
            // Check if our driver is in the list
            resolve(stdout.includes('VirtualAudioDriver.inf'));
        });
    });
}
```

### Check if Devices are Available

```javascript
const { exec } = require('child_process');

function checkAudioDevices() {
    return new Promise((resolve, reject) => {
        // Use PowerShell to check for devices
        const psScript = `
            $speakers = Get-AudioDevice -List | Where-Object {$_.Name -like '*ISL Speaker*'}
            $mics = Get-AudioDevice -List | Where-Object {$_.Name -like '*ISL Mic*'}

            @{
                SpeakerFound = ($speakers -ne $null)
                MicFound = ($mics -ne $null)
            } | ConvertTo-Json
        `;

        exec(`powershell -Command "${psScript}"`, (error, stdout) => {
            if (error) {
                reject(error);
                return;
            }
            resolve(JSON.parse(stdout));
        });
    });
}
```

## Uninstallation

### Silent Uninstallation

```javascript
function uninstallAudioDriver() {
    return new Promise((resolve, reject) => {
        // First, get the published name
        exec('pnputil /enum-drivers', (error, stdout) => {
            if (error) {
                reject(error);
                return;
            }

            // Parse output to find our driver's published name (e.g., oem123.inf)
            const match = stdout.match(/Published Name\s*:\s*(oem\d+\.inf)[\s\S]*?Original Name\s*:\s*VirtualAudioDriver\.inf/);

            if (!match) {
                resolve('Driver not found');
                return;
            }

            const publishedName = match[1];

            // Uninstall the driver
            exec(`pnputil /delete-driver ${publishedName} /uninstall /force`, (error, stdout) => {
                if (error) {
                    reject(error);
                    return;
                }
                resolve(stdout);
            });
        });
    });
}
```

## Troubleshooting

### Common Issues

1. **Installation fails with access denied**
   - Ensure the app is running with administrator privileges
   - Check Windows UAC settings

2. **Driver installed but devices not appearing**
   - Reboot the system
   - Check Device Manager for any error codes
   - Verify the driver is signed (or test signing is enabled)

3. **Driver conflicts**
   - Check for existing virtual audio drivers
   - Uninstall conflicting drivers first

### Test Signing Mode (Development Only)

For unsigned drivers during development:

```bash
# Enable test signing (requires reboot)
bcdedit /set testsigning on

# Disable after development
bcdedit /set testsigning off
```

## Production Checklist

- [ ] Driver files are properly signed with a valid code signing certificate
- [ ] Driver files are included in the Electron app package
- [ ] Installation script handles errors gracefully
- [ ] User is notified if installation requires reboot
- [ ] Uninstaller removes the driver cleanly
- [ ] Installation is logged for debugging
- [ ] App requests administrator privileges appropriately

## Example: Complete Integration

```javascript
const { app } = require('electron');
const { execFile } = require('child_process');
const path = require('path');
const os = require('os');

class ISLAudioDriverManager {
    constructor() {
        this.arch = os.arch();
        this.driverPath = this.getDriverPath();
    }

    getDriverPath() {
        return path.join(
            process.resourcesPath,
            'drivers',
            this.arch,
            'VirtualAudioDriver.inf'
        );
    }

    install() {
        return new Promise((resolve, reject) => {
            const args = ['/add-driver', this.driverPath, '/install'];

            execFile('pnputil.exe', args, (error, stdout, stderr) => {
                if (error) {
                    console.error('Driver installation failed:', stderr);
                    reject(error);
                    return;
                }
                console.log('Driver installed:', stdout);
                resolve(stdout);
            });
        });
    }

    async checkInstalled() {
        return new Promise((resolve) => {
            execFile('pnputil.exe', ['/enum-drivers'], (error, stdout) => {
                if (error) {
                    resolve(false);
                    return;
                }
                resolve(stdout.includes('VirtualAudioDriver.inf'));
            });
        });
    }
}

// Usage in main process
app.whenReady().then(async () => {
    const driverManager = new ISLAudioDriverManager();

    const isInstalled = await driverManager.checkInstalled();

    if (!isInstalled) {
        try {
            await driverManager.install();
            console.log('ISL Audio Driver installed successfully');
            // Optionally show success notification to user
        } catch (error) {
            console.error('Failed to install ISL Audio Driver:', error);
            // Show error dialog to user
        }
    } else {
        console.log('ISL Audio Driver already installed');
    }
});
```

## Additional Resources

- [PnPUtil Documentation](https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil)
- [Electron Builder Documentation](https://www.electron.build/)
- [Windows Driver Installation](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/)
