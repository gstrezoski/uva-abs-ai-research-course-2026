@echo off
rem Double-click this file to run teardown-windows.ps1. It asks you to type YES
rem before it deletes anything. Keep it in the same folder as the .ps1 file.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0teardown-windows.ps1"
set EXITCODE=%ERRORLEVEL%
echo.
pause
exit /b %EXITCODE%
