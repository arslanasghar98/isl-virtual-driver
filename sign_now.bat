@echo off
setlocal

set "SIGNTOOL=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
set "THUMBPRINT=a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b"
set "TIMESTAMP=http://timestamp.digicert.com"

echo ========================================
echo Signing Virtual Audio Driver
echo ========================================
echo.

echo Signing CAB file...
"%SIGNTOOL%" sign /sha1 %THUMBPRINT% /fd sha256 /tr %TIMESTAMP% /td sha256 "D:\Datics\Virtual-Audio-Driver\VirtualAudioDriver_MultiArch.cab"
if %errorlevel% neq 0 echo ERROR: CAB signing failed

echo.
echo Verifying CAB signature...
"%SIGNTOOL%" verify /pa "D:\Datics\Virtual-Audio-Driver\VirtualAudioDriver_MultiArch.cab"

echo.
echo Done!
pause
