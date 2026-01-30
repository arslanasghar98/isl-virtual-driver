@echo off
setlocal
set "DIR=D:\Datics\Virtual-Audio-Driver\x64\Release"
set "SIG=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
set "LOG=D:\Datics\Virtual-Audio-Driver\sign_verify_log.txt"

cd /d "%DIR%"
echo Signing and verifying > "%LOG%"
echo. >> "%LOG%"

echo Signing .cat... >> "%LOG%"
"%SIG%" sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /sha1 a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b virtualaudiodriver.cat >> "%LOG%" 2>&1
echo Exit code .cat sign: %ERRORLEVEL% >> "%LOG%"

echo Signing .sys... >> "%LOG%"
"%SIG%" sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /sha1 a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b virtualaudiodriver.sys >> "%LOG%" 2>&1
echo Exit code .sys sign: %ERRORLEVEL% >> "%LOG%"

echo Verifying .cat... >> "%LOG%"
"%SIG%" verify /pa virtualaudiodriver.cat >> "%LOG%" 2>&1
echo Exit code .cat verify: %ERRORLEVEL% >> "%LOG%"

echo Verifying .sys... >> "%LOG%"
"%SIG%" verify /pa virtualaudiodriver.sys >> "%LOG%" 2>&1
echo Exit code .sys verify: %ERRORLEVEL% >> "%LOG%"

endlocal
