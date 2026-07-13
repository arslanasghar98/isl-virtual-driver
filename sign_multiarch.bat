@echo off
setlocal

:: DigiCert EV Certificate Thumbprint
set "THUMBPRINT=a2d7275bae5b04324d5d844fc4eb6bd5759d5f7b"
set "SIG=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"
set "INF2CAT=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\inf2cat.exe"
set "LOG=%~dp0sign_multiarch_log.txt"

echo ======================================== > "%LOG%"
echo Multi-Architecture Driver Signing >> "%LOG%"
echo %DATE% %TIME% >> "%LOG%"
echo ======================================== >> "%LOG%"
echo. >> "%LOG%"

:: Sign x64 binaries
echo Signing x64 binaries... >> "%LOG%"
cd /d "%~dp0x64\Release\package"

echo Signing x64 .sys... >> "%LOG%"
"%SIG%" sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /sha1 %THUMBPRINT% virtualaudiodriver.sys >> "%LOG%" 2>&1
echo Exit code: %ERRORLEVEL% >> "%LOG%"

:: Sign ARM64 binaries
echo Signing ARM64 binaries... >> "%LOG%"
cd /d "%~dp0ARM64\Release\package"

echo Signing ARM64 .sys... >> "%LOG%"
"%SIG%" sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /sha1 %THUMBPRINT% virtualaudiodriver.sys >> "%LOG%" 2>&1
echo Exit code: %ERRORLEVEL% >> "%LOG%"

:: Generate multi-arch catalog from x64 folder
echo Generating multi-arch catalog... >> "%LOG%"
cd /d "%~dp0x64\Release\package"
"%INF2CAT%" /driver:. /os:10_X64,10_ARM64 /uselocaltime >> "%LOG%" 2>&1
echo Exit code: %ERRORLEVEL% >> "%LOG%"

:: Sign catalog
echo Signing catalog... >> "%LOG%"
"%SIG%" sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /sha1 %THUMBPRINT% virtualaudiodriver.cat >> "%LOG%" 2>&1
echo Exit code: %ERRORLEVEL% >> "%LOG%"

:: Verify signatures
echo. >> "%LOG%"
echo ======================================== >> "%LOG%"
echo Verifying signatures... >> "%LOG%"
echo ======================================== >> "%LOG%"

echo Verifying x64 .sys... >> "%LOG%"
"%SIG%" verify /pa "%~dp0x64\Release\package\virtualaudiodriver.sys" >> "%LOG%" 2>&1

echo Verifying ARM64 .sys... >> "%LOG%"
"%SIG%" verify /pa "%~dp0ARM64\Release\package\virtualaudiodriver.sys" >> "%LOG%" 2>&1

echo Verifying catalog... >> "%LOG%"
"%SIG%" verify /pa "%~dp0x64\Release\package\virtualaudiodriver.cat" >> "%LOG%" 2>&1

echo. >> "%LOG%"
echo Done! See %LOG% for details. >> "%LOG%"

echo.
echo Multi-architecture signing complete!
echo See %LOG% for details.
echo.
type "%LOG%"

endlocal
pause
