@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-backend.ps1" -Port 8766
if errorlevel 1 pause
