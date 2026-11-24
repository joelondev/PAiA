@echo off
rem Double-click to install the PAiA offline pack (model + engines). No network used.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-PAiA-Offline-Pack.ps1" %*
echo.
pause
