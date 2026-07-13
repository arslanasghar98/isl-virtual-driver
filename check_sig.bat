@echo off
set "SIGNTOOL=C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"

echo ========================================
echo Signature Details for x64 Driver
echo ========================================
"%SIGNTOOL%" verify /v /pa "D:\Datics\Virtual-Audio-Driver\x64\Release\virtualaudiodriver.sys"

echo.
echo ========================================
echo Signature Details for ARM64 Driver
echo ========================================
"%SIGNTOOL%" verify /v /pa "D:\Datics\Virtual-Audio-Driver\ARM64\Release\virtualaudiodriver.sys"

echo.
echo ========================================
echo Signature Details for Catalog
echo ========================================
"%SIGNTOOL%" verify /v /pa "D:\Datics\Virtual-Audio-Driver\MultiArchPackage\virtualaudiodriver.cat"

pause
