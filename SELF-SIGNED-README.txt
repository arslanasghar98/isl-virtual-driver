================================================================================
                VIRTUAL AUDIO DRIVER - SELF-SIGNED INSTALLATION
================================================================================

This is the RECOMMENDED installation method!

BENEFITS:
  ✓ NO Test Mode required
  ✓ NO "Test Mode" watermark on desktop
  ✓ Driver signature enforcement stays ENABLED
  ✓ More secure than disabling signature checks
  ✓ Works only on your specific machine

================================================================================
QUICK START (EASIEST METHOD)
================================================================================

1. Right-click:  SELF-SIGN-INSTALL.bat
2. Select:       "Run as administrator"
3. Follow:       On-screen instructions
4. Reboot:       When prompted

That's it! The script will:
  - Create a self-signed certificate
  - Install it to your trusted certificates
  - Sign the driver with it
  - Install the signed driver

================================================================================
STEP-BY-STEP METHOD
================================================================================

If you prefer to run each step manually:

Step 1: Create Certificate
  - Right-click: 1-Create-Certificate.ps1
  - Select: "Run with PowerShell" (as admin)

Step 2: Sign Driver
  - Right-click: 2-Sign-Driver.ps1
  - Select: "Run with PowerShell" (as admin)

Step 3: Install Signed Driver
  - Right-click: 3-Install-Signed-Driver.ps1
  - Select: "Run with PowerShell" (as admin)

Step 4: Reboot
  - Restart your computer

================================================================================
WHAT HAPPENS BEHIND THE SCENES
================================================================================

1. CREATE CERTIFICATE
   - Creates a code-signing certificate
   - Installs it to "Trusted Root Certification Authorities"
   - Installs it to "Trusted Publishers"
   - Certificate is valid for 5 years

2. SIGN DRIVER
   - Uses signtool.exe from Windows SDK/WDK
   - Signs virtualaudiodriver.sys with your certificate
   - Creates and signs catalog file (if available)
   - Timestamps the signature

3. INSTALL DRIVER
   - Verifies driver is properly signed
   - Adds driver to Windows driver store
   - Creates virtual audio device
   - No signature warnings because certificate is trusted

================================================================================
REQUIREMENTS
================================================================================

✓ Windows 10/11 (64-bit)
✓ Administrator privileges
✓ Windows SDK or WDK (for signing tools)
  - Usually already installed if you built the driver
  - If missing, download from:
    https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/

================================================================================
AFTER INSTALLATION
================================================================================

You should see these audio devices in Sound Settings:
  - ISL Speaker (Output)
  - ISL Mic (Input)

To use them:
  1. Right-click speaker icon in system tray
  2. Select "Open Sound settings"
  3. Set ISL Speaker as default output
  4. Set ISL Mic as default input

================================================================================
UNINSTALLATION
================================================================================

Use the same uninstall script:
  - Right-click: UNINSTALL.bat
  - Select: "Run as administrator"

To also remove the certificate (optional):
  1. Press Win+R
  2. Type: certmgr.msc
  3. Expand: Trusted Root Certification Authorities > Certificates
  4. Find: "VirtualAudioDriver Self-Signed Certificate"
  5. Right-click > Delete
  6. Repeat for: Trusted Publishers > Certificates

================================================================================
TROUBLESHOOTING
================================================================================

Problem: "signtool.exe not found"
Solution: Install Windows SDK from the URL above

Problem: Device doesn't appear after installation
Solution: Reboot your computer

Problem: "Certificate not found" error in Step 2 or 3
Solution: Run Step 1 (Create Certificate) first

Problem: PowerShell execution policy error
Solution: Run as administrator and use the .bat files

================================================================================
COMPARISON: Self-Signed vs Test Mode
================================================================================

SELF-SIGNED (This method):
  ✓ No Test Mode watermark
  ✓ Signature enforcement enabled
  ✓ More secure
  ✓ Professional approach
  ✗ Requires Windows SDK/WDK
  ✗ Few more steps

TEST MODE (Alternative):
  ✓ Simpler (one command)
  ✓ No additional tools needed
  ✗ "Test Mode" watermark on desktop
  ✗ Disables all signature checks
  ✗ Less secure

For this driver, SELF-SIGNED is recommended!

================================================================================
FILES INCLUDED
================================================================================

SELF-SIGN-INSTALL.bat           - All-in-one installer (EASIEST)
1-Create-Certificate.ps1        - Step 1: Create certificate
2-Sign-Driver.ps1              - Step 2: Sign driver files
3-Install-Signed-Driver.ps1    - Step 3: Install signed driver
SELF-SIGNED-README.txt         - This file
UNINSTALL.bat                  - Uninstaller

x64\Debug\
    virtualaudiodriver.sys     - Driver binary
    VirtualAudioDriver.inf     - Driver installation info

================================================================================

For more help, see INSTALLATION_GUIDE.md

================================================================================
