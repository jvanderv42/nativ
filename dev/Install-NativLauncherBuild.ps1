# Install-NativLauncherBuild.ps1
# Windows PowerShell 5.1 or PowerShell 7; no third-party modules required.
# Installs only the launcher executable from an extracted GitHub Actions artifact.
# Preserves the installed game, runtime sources, manifests, and bundled SDL3.dll.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$artifactFolder,

    [string]$installFolder = 'C:\Installed Games\ProjectNativ-v0.1.5-windows'
)

$ErrorActionPreference = 'Stop'

# Validate the installer input without modifying the existing installation.
$artifactFolder = (Resolve-Path -LiteralPath $artifactFolder -ErrorAction Stop).Path
$installFolder = (Resolve-Path -LiteralPath $installFolder -ErrorAction Stop).Path
$sourcePath = Join-Path $artifactFolder 'Project Nativ.exe'
$hashPath = Join-Path $artifactFolder 'SHA256SUMS.txt'
$installedPath = Join-Path $installFolder 'Project Nativ.exe'

foreach ($requiredPath in @($sourcePath, $hashPath, $installedPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required file not found: $requiredPath"
    }
}

# Require the published checksum before trusting the downloaded executable.
$hashLine = @(Get-Content -LiteralPath $hashPath |
    Where-Object { $_ -match '^([a-fA-F0-9]{64})\s+\*?Project Nativ\.exe$' })
if ($hashLine.Count -ne 1) {
    throw 'Expected exactly one Project Nativ.exe SHA-256 entry in SHA256SUMS.txt.'
}
$expectedHash = ([regex]::Match($hashLine[0], '^([a-fA-F0-9]{64})')).Groups[1].Value
$actualHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256 -ErrorAction Stop).Hash
if ($actualHash -ne $expectedHash) {
    throw 'Launcher SHA-256 mismatch; refusing installation.'
}

$sourceFile = Get-Item -LiteralPath $sourcePath
if ($sourceFile.Length -lt 1024) {
    throw 'Launcher executable is unexpectedly small.'
}
$fileStream = [System.IO.File]::OpenRead($sourcePath)
try {
    $header = New-Object byte[] 2
    if ($fileStream.Read($header, 0, 2) -ne 2 -or
        $header[0] -ne 0x4D -or $header[1] -ne 0x5A) {
        throw 'Launcher is not a recognizable Windows PE executable.'
    }
}
finally {
    $fileStream.Dispose()
}

# Never replace an executable while the Nativ launcher is running.
if (Get-Process -Name 'Project Nativ' -ErrorAction SilentlyContinue) {
    throw 'Close Project Nativ before installing the new launcher.'
}

$backupFolder = Join-Path $installFolder ('launcherBackup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $backupFolder -ErrorAction Stop | Out-Null
$backupPath = Join-Path $backupFolder 'Project Nativ.exe'
Copy-Item -LiteralPath $installedPath -Destination $backupPath -ErrorAction Stop

# Replace exactly one file. Any installation failure restores the prior launcher.
try {
    Copy-Item -LiteralPath $sourcePath -Destination $installedPath -Force -ErrorAction Stop
    $installedHash = (Get-FileHash -LiteralPath $installedPath -Algorithm SHA256 -ErrorAction Stop).Hash
    if ($installedHash -ne $expectedHash) {
        throw 'Post-install checksum verification failed.'
    }

    Write-Host 'Launcher installed and SHA-256 verified.' -ForegroundColor Green
    Write-Host "Previous launcher backup: $backupPath"
    Write-Host 'Only Project Nativ.exe was changed. Test opening Nativ and starting your game.'
}
catch {
    Write-Warning "Installation failed: $($_.Exception.Message)"
    Copy-Item -LiteralPath $backupPath -Destination $installedPath -Force -ErrorAction Stop
    Write-Warning "Previous launcher restored from $backupPath"
    throw
}
