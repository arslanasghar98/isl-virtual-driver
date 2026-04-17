# Check CallJoyna device
Write-Host "Checking ROOT\MEDIA\0002 device..." -ForegroundColor Cyan

$device = Get-PnpDevice -InstanceId "ROOT\MEDIA\0002" -ErrorAction SilentlyContinue
if ($device) {
    Write-Host "Device found:" -ForegroundColor Green
    Write-Host "  FriendlyName: $($device.FriendlyName)"
    Write-Host "  Status: $($device.Status)"
    Write-Host "  Class: $($device.Class)"

    # Get driver info
    $driver = Get-PnpDeviceProperty -InstanceId "ROOT\MEDIA\0002" -KeyName "DEVPKEY_Device_DriverInfPath" -ErrorAction SilentlyContinue
    if ($driver) {
        Write-Host "  Driver: $($driver.Data)"
    }
} else {
    Write-Host "Device not found" -ForegroundColor Red
}

Write-Host "`nAll MEDIA devices with ROOT:" -ForegroundColor Cyan
Get-PnpDevice -Class MEDIA | Where-Object { $_.InstanceId -like "ROOT*" } | Format-Table FriendlyName, InstanceId, Status
