@echo off
rem Double-click this file to run setup-windows.ps1. No PowerShell window or
rem execution policy change needed. Keep it in the same folder as the .ps1 file.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-windows.ps1"
set EXITCODE=%ERRORLEVEL%
echo.
if %EXITCODE% neq 0 (
    echo Setup stopped with an error. Read the messages above.
) else (
    echo Setup is done.
)
echo.
pause
exit /b %EXITCODE%
