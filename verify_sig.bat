@echo off
cd /d "D:\Datics\Virtual-Audio-Driver\x64\Release"
set "SIG=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
(
echo --- Verifying .cat ---
"%SIG%" verify /pa virtualaudiodriver.cat
echo --- Verifying .sys ---
"%SIG%" verify /pa virtualaudiodriver.sys
echo --- Done ---
) > "D:\Datics\Virtual-Audio-Driver\verify_log.txt" 2>&1
