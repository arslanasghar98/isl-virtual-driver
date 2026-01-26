================================================================================
                    VIRTUAL AUDIO DRIVER - QUICK START
================================================================================

IMPORTANT: Before installing, you MUST enable Test Mode!

Run this command in Administrator Command Prompt:
    bcdedit /set testsigning on

Then REBOOT your computer.

================================================================================
INSTALLATION
================================================================================

EASIEST METHOD:
    1. Right-click INSTALL.bat
    2. Select "Run as administrator"
    3. Follow the on-screen instructions
    4. Reboot if the device doesn't appear automatically

ALTERNATIVE METHODS:
    - See INSTALLATION_GUIDE.md for detailed instructions
    - Use Device Manager manual installation method

================================================================================
UNINSTALLATION
================================================================================

EASIEST METHOD:
    1. Right-click UNINSTALL.bat
    2. Select "Run as administrator"
    3. Follow the on-screen instructions

================================================================================
FILES INCLUDED
================================================================================

x64\Debug\
    virtualaudiodriver.sys  - Driver binary
    VirtualAudioDriver.inf  - Driver installation info

INSTALL.bat                 - Quick install launcher
UNINSTALL.bat               - Quick uninstall launcher
Install-VirtualAudioDriver.ps1    - PowerShell install script
Uninstall-VirtualAudioDriver.ps1  - PowerShell uninstall script
INSTALLATION_GUIDE.md       - Detailed installation guide
INSTALL_README.txt          - This file

================================================================================
AFTER INSTALLATION
================================================================================

You should see these audio devices:
    - ISL Speaker (Output)
    - ISL Mic (Input)

Set them as default in Windows Sound Settings to use them.

================================================================================
TROUBLESHOOTING
================================================================================

Problem: Installation fails
Solution: Make sure Test Mode is enabled (see top of this file)

Problem: Device doesn't appear
Solution: Reboot your computer

Problem: Code 52 error
Solution: Test Mode not enabled - see top of this file

For more help, see INSTALLATION_GUIDE.md

================================================================================
