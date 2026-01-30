@echo off
"C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" "D:\Datics\Virtual-Audio-Driver\VirtualAudioDriver.sln" /p:Configuration=Release /p:Platform=x64 /t:Rebuild
