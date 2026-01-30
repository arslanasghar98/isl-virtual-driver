# Update-Driver.ps1 - Must be run as Administrator
# Updates the virtual audio driver with the latest build

$ErrorActionPreference = "Continue"

Write-Host "Updating Virtual Audio Driver..." -ForegroundColor Cyan

# Copy the new driver
$source = "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.sys"
$dest = "C:\Windows\System32\drivers\virtualaudiodriver.sys"

if (Test-Path $source) {
    Write-Host "Copying new driver from $source..."
    try {
        Copy-Item -Force $source $dest
        Write-Host "Driver copied successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error copying driver: $_" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "Source driver not found at $source" -ForegroundColor Red
    exit 1
}

# Restart the device
Write-Host "Restarting device..."
$result = pnputil /restart-device "ROOT\MEDIA\0000" 2>&1
Write-Host $result

Write-Host ""
Write-Host "Done! If you see errors, check Device Manager or restart the computer." -ForegroundColor Yellow
