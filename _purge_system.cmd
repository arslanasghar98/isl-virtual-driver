@echo off
net stop Audiosrv /y >nul 2>&1
net stop AudioEndpointBuilder /y >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render\{59433FBA-9024-40F1-B5BE-58B462C8190B}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture\{AFE5240C-DB2B-4D8D-B54F-BBC94AEC31E2}" /f
net start AudioEndpointBuilder >nul 2>&1
net start Audiosrv >nul 2>&1
echo done > "D:\Datics\Virtual-Audio-Driver\_purge_done.txt"
