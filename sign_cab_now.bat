@echo off  
set "SIGNTOOL=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"  
set "THUMBPRINT=a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b"  
"%SIGNTOOL%" sign /sha1 %THUMBPRINT% /fd sha256 /tr http://timestamp.digicert.com /td sha256 "D:\Datics\Virtual-Audio-Driver\VirtualAudioDriver_MultiArch.cab"  
"%SIGNTOOL%" verify /pa "D:\Datics\Virtual-Audio-Driver\VirtualAudioDriver_MultiArch.cab" 
