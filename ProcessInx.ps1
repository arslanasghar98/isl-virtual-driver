# Process .inx file to create .inf file
$inxPath = "D:\Datics\Virtual-Audio-Driver\Source\Main\VirtualAudioDriver.inx"
$infPath = "D:\Datics\Virtual-Audio-Driver\x64\Debug\VirtualAudioDriver.inf"

# Read the .inx file
$content = Get-Content -Path $inxPath -Encoding Unicode -Raw

# Replace variables
$content = $content -replace '\$KMDFVERSION\$', '1.33'
$content = $content -replace 'NT\$ARCH\$', 'NTamd64'

# Write the .inf file
[System.IO.File]::WriteAllText($infPath, $content, [System.Text.Encoding]::Unicode)

Write-Host "INF file created successfully at: $infPath"
