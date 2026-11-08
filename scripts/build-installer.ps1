$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = (Get-Content (Join-Path $root 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'VERSION invalida' }
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$stage = Join-Path ([IO.Path]::GetTempPath()) ('plugin-online-package-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
try {
  foreach ($name in @('backend','docs','scripts')) {
    Copy-Item -LiteralPath (Join-Path $root $name) -Destination (Join-Path $stage $name) -Recurse
  }
  $dllDest = Join-Path $stage 'plugin\online-source\prebuilt\x64'
  New-Item -ItemType Directory -Force -Path $dllDest | Out-Null
  Copy-Item -LiteralPath (Join-Path $root 'plugin\online-source\prebuilt\x64\YouTube Plugin Online.dll') -Destination $dllDest
  $trayCompiler = Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
  & $trayCompiler /nologo /target:winexe /reference:System.Windows.Forms.dll /reference:System.Drawing.dll /reference:System.Web.Extensions.dll "/out:$stage\Plugin Online Bandeja.exe" (Join-Path $root 'packaging\TrayApp.cs')
  if ($LASTEXITCODE -ne 0) { throw 'No se pudo compilar el icono de la bandeja.' }
  foreach ($name in @('INSTALAR.ps1','INSTALAR.bat','INICIAR.bat','README.md','LICENSE','THIRD_PARTY_NOTICES.md','VERSION','pyproject.toml','uv.lock')) {
    Copy-Item -LiteralPath (Join-Path $root $name) -Destination $stage
  }
  Get-ChildItem -LiteralPath $stage -Recurse -Directory -Filter '__pycache__' | Remove-Item -Recurse -Force
  $zip = Join-Path ([IO.Path]::GetTempPath()) ('plugin-online-payload-' + [guid]::NewGuid().ToString('N') + '.zip')
  Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip
  $exe = Join-Path $dist ("Plugin-Online-$version-windows-x64-setup.exe")
  $compiler = Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
  if (-not (Test-Path -LiteralPath $compiler)) { throw 'No se encontro el compilador de .NET Framework.' }
  & $compiler /nologo /target:winexe /reference:System.IO.Compression.dll /reference:System.IO.Compression.FileSystem.dll /reference:System.Windows.Forms.dll /reference:System.Drawing.dll "/resource:$zip,payload.zip" "/out:$exe" (Join-Path $root 'packaging\Installer.cs')
  if ($LASTEXITCODE -ne 0) { throw 'No se pudo compilar el instalador.' }
  & $exe --verify-only
  if ($LASTEXITCODE -ne 0) { throw 'El paquete no supero la verificacion.' }
  $hash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant()
  Set-Content -Encoding ascii -Path "$exe.sha256" -Value "$hash  $(Split-Path -Leaf $exe)"
  Write-Host "Instalador: $exe"
  Write-Host "SHA256: $hash"
} finally {
  if ($zip -and (Test-Path -LiteralPath $zip)) { Remove-Item -LiteralPath $zip -Force }
  if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
