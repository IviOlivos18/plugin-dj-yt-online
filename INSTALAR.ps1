$ErrorActionPreference = 'Stop'
$source = $PSScriptRoot
$target = Join-Path $env:LOCALAPPDATA 'YouTube Plugin Online'
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
Write-Host ''
Write-Host 'Instalacion completada. Reinicia VirtualDJ y busca YouTube Plugin Online en Online Music.' -ForegroundColor Green
Write-Host 'El servicio guarda videos descargados en su cache; no se borran automaticamente.'
