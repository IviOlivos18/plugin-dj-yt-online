@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALAR.ps1"
if errorlevel 1 (
 echo.
 echo La instalacion no se completo. Revisa el mensaje anterior.
 pause
 exit /b 1
)
echo.
pause
