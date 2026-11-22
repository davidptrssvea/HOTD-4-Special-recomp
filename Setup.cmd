@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0setup.ps1" %*
set "SETUP_RESULT=%ERRORLEVEL%"
if not "%SETUP_RESULT%"=="0" echo Setup failed. Please read the error above.
pause
exit /b %SETUP_RESULT%
