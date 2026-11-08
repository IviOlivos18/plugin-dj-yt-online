$ErrorActionPreference = 'Stop'
$source = $PSScriptRoot
$target = Join-Path $env:LOCALAPPDATA 'YouTube Plugin Online'
if (Get-Process -Name virtualdj -ErrorAction SilentlyContinue) { throw 'Cierra VirtualDJ antes de instalar o actualizar.' }
& (Join-Path $source 'scripts\stop-previous-service.ps1') -Port 8766
$installedTray = Join-Path $target 'Plugin Online Bandeja.exe'
Get-Process -Name 'Plugin Online Bandeja' -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $installedTray } | Stop-Process


Write-Host 'Instalando YouTube Plugin Online para el usuario actual...'
New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -Path (Join-Path $source '*') -Destination $target -Recurse -Force
Set-Location $target
& (Join-Path $target 'scripts\setup-and-start.ps1')
if ($LASTEXITCODE -ne 0) { throw 'No se pudo completar la preparacion.' }
$shell = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$link = $shell.CreateShortcut((Join-Path $desktop 'YouTube Plugin Online.lnk'))
$link.TargetPath = Join-Path $target 'INICIAR.bat'
$link.WorkingDirectory = $target
$link.Description = 'Iniciar el servicio local de YouTube Plugin Online'
$link.Save()
$startup = [Environment]::GetFolderPath('Startup')
$trayLink = $shell.CreateShortcut((Join-Path $startup 'Plugin Online Bandeja.lnk'))
$trayLink.TargetPath = Join-Path $target 'Plugin Online Bandeja.exe'
$trayLink.WorkingDirectory = $target
$trayLink.Description = 'Avisos de actualizaciones al abrir VirtualDJ'
$trayLink.Save()
$serviceLink = $shell.CreateShortcut((Join-Path $startup 'Plugin Online Servicio.lnk'))
$serviceLink.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$serviceScript = Join-Path $target 'scripts\start-backend.ps1'
$serviceLink.Arguments = '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $serviceScript + '" -Port 8766 -NoBrowser'
$serviceLink.WorkingDirectory = $target
$serviceLink.Description = 'Iniciar el servicio local del plugin'
$serviceLink.Save()
Write-Host ''
Write-Host 'Instalacion completada. Reinicia VirtualDJ y busca YouTube Plugin Online en Online Music.' -ForegroundColor Green
Write-Host 'El servicio guarda videos descargados en su cache; no se borran automaticamente.'
