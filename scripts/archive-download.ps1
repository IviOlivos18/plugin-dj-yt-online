Add-Type -AssemblyName System.IO.Compression.FileSystem

function Test-ZipArchive([string]$Path, [string]$ExpectedPattern = '*') {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
        try { return @($archive.Entries | Where-Object { $_.FullName -like $ExpectedPattern }).Count -gt 0 }
        finally { $archive.Dispose() }
    } catch { return $false }
}

function Get-VerifiedZip([string]$Url, [string]$Destination, [string]$ExpectedPattern) {
    if (Test-ZipArchive $Destination $ExpectedPattern) {
        Write-Host "Valid archive already present: $Destination"
        return
    }
    $lastError = $null
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        $temporary = "$Destination.$([guid]::NewGuid().ToString('N')).part"
        try {
            Write-Host "Downloading archive (attempt $attempt of 2)"
            $oldProgress = $ProgressPreference
            try { $ProgressPreference = "SilentlyContinue"; Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $temporary }
            finally { $ProgressPreference = $oldProgress }
            if (-not (Test-ZipArchive $temporary $ExpectedPattern)) { throw 'El archivo descargado esta incompleto o danado.' }
            Move-Item -LiteralPath $temporary -Destination $Destination -Force
            return
        } catch {
            $lastError = $_
            Write-Warning "No se pudo preparar el archivo en el intento $attempt."
        } finally {
            if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
        }
        if ($attempt -lt 2) { Start-Sleep -Seconds 1 }
    }
    throw "No se pudo descargar un archivo completo despues de dos intentos: $($lastError.Exception.Message)"
}
