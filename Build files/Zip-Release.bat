@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Zip-Release.ps1" %*
pause
