# Invoke-NativTouchpadTestBuild.ps1
# Run in Windows PowerShell 5.1 or PowerShell 7 from the Project Nativ install folder.
# This modifies two installed runtime source files and rebuilds Uncharted: Golden Abyss.
# The existing game executable and original source files are backed up first.
[CmdletBinding()]
param(
    [string]$installFolder = (Get-Location).Path,
    [string]$titleId = 'PCSA00029'
)

$ErrorActionPreference = 'Stop'
$branch = 'feature/controller-touchpad-controls'
$repository = 'jvanderv42/nativ'
$sourcePaths = @('runtime/ui/window.c', 'runtime/ui/overlay.cpp')

function Assert-FileExists {
    param([string]$filePath, [string]$description)
    if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
        throw "$description not found: $filePath"
    }
}

$installFolder = (Resolve-Path -LiteralPath $installFolder).Path
$pipelinePath = Join-Path $installFolder 'pipeline/vitarecomp.py'
Assert-FileExists $pipelinePath 'Nativ build pipeline'
foreach ($sourcePath in $sourcePaths) {
    Assert-FileExists (Join-Path $installFolder $sourcePath) 'Installed runtime source'
}

# Reuse the bundled Python and Windows toolchain provided with the Nativ release.
$pythonCandidates = @(
    (Join-Path $installFolder 'python/python.exe'),
    (Join-Path $installFolder '.venv/Scripts/python.exe')
)
$pythonPath = $pythonCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $pythonPath) { throw 'No bundled Nativ Python found. Use a full Windows player release installation.' }

$compilerPath = Join-Path $installFolder 'toolchain/llvm-mingw/bin/x86_64-w64-mingw32-clang.exe'
Assert-FileExists $compilerPath 'Bundled Windows compiler'

# Find the user's existing Nativ game files; do not download or modify game data.
$libraryFolder = if ($env:ATIV_DUMP) { $env:ATIV_DUMP } else {
    Join-Path $env:LOCALAPPDATA 'ProjectNativ/Nativ/library'
}
$recompFolder = Join-Path $libraryFolder "decrypted/$titleId/recomp"
if (-not (Test-Path -LiteralPath $recompFolder -PathType Container)) {
    throw "No existing compiled game directory found: $recompFolder. Build Uncharted in the normal launcher first."
}
$mainBinary = Join-Path $recompFolder 'game_host.exe'
if (-not (Test-Path -LiteralPath $mainBinary -PathType Leaf)) {
    throw "Existing Uncharted executable not found: $mainBinary. Build the game in Nativ first."
}
if (Get-Process -Name 'game_host' -ErrorAction SilentlyContinue) {
    throw 'Close the running Nativ game before rebuilding.'
}

# Keep all backups next to the installed runtime, in a uniquely named folder.
$backupFolder = Join-Path $installFolder ("touchpadBackup-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -Path $backupFolder -ItemType Directory -ErrorAction Stop | Out-Null
foreach ($sourcePath in $sourcePaths) {
    $backupPath = Join-Path $backupFolder $sourcePath
    New-Item -Path (Split-Path $backupPath -Parent) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $installFolder $sourcePath) -Destination $backupPath
}
Copy-Item -LiteralPath $mainBinary -Destination (Join-Path $backupFolder 'game_host.exe')

# Preserve the original release manifest before any development size adjustments.
$manifestPath = Join-Path $installFolder '.nativ-files'
$manifestBackupPath = Join-Path $backupFolder '.nativ-files'
$hasManifest = Test-Path -LiteralPath $manifestPath -PathType Leaf
if ($hasManifest) {
    Copy-Item -LiteralPath $manifestPath -Destination $manifestBackupPath -ErrorAction Stop
}

$temporaryFolder = Join-Path $env:TEMP ('nativTouchpad-' + [guid]::NewGuid().ToString('N'))
New-Item -Path $temporaryFolder -ItemType Directory | Out-Null
$sourceChanged = $false
try {
    # Download the exact two changed files from the user's development branch.
    foreach ($sourcePath in $sourcePaths) {
        $filename = Split-Path $sourcePath -Leaf
        $tempPath = Join-Path $temporaryFolder $filename
        $sourceUrl = "https://raw.githubusercontent.com/$repository/$branch/$sourcePath"
        Invoke-WebRequest -Uri $sourceUrl -OutFile $tempPath -ErrorAction Stop
        if ((Get-Item -LiteralPath $tempPath).Length -lt 1000) {
            throw "Unexpectedly small downloaded file: $sourcePath"
        }
        Copy-Item -LiteralPath $tempPath -Destination (Join-Path $installFolder $sourcePath) -Force
        $sourceChanged = $true
    }

    Write-Host "Building $titleId with your touchpad changes..." -ForegroundColor Cyan
    & $pythonPath $pipelinePath build $titleId
    if ($LASTEXITCODE -ne 0) { throw "Nativ build failed (exit code $LASTEXITCODE)." }
    Assert-FileExists $mainBinary 'Rebuilt game executable'

    # The two replaced source files are expected to differ from the packaged
    # release. Update only their size entries after a successful build, leaving
    # validation enabled for the rest of the installation.
    if ($hasManifest) {
        $manifestLines = [System.IO.File]::ReadAllLines($manifestPath)
        $updatedCounts = @{}
        foreach ($sourcePath in $sourcePaths) { $updatedCounts[$sourcePath] = 0 }

        $updatedLines = @(
            foreach ($line in $manifestLines) {
                if ($line -match '^(\\d+) (.+)
    Write-Host "Backup folder: $backupFolder"
}
catch {
    Write-Warning "Build/setup failed: $($_.Exception.Message)"
    if ($sourceChanged) {
        foreach ($sourcePath in $sourcePaths) {
            Copy-Item -LiteralPath (Join-Path $backupFolder $sourcePath) -Destination (Join-Path $installFolder $sourcePath) -Force
        }
    }
    Copy-Item -LiteralPath (Join-Path $backupFolder 'game_host.exe') -Destination $mainBinary -Force
    if ($hasManifest) {
        Copy-Item -LiteralPath $manifestBackupPath -Destination $manifestPath -Force
    }
    Write-Warning "Original runtime sources, game executable and manifest (if present) restored. Backups remain at $backupFolder"
    throw
}
finally {
    Remove-Item -LiteralPath $temporaryFolder -Recurse -Force -ErrorAction SilentlyContinue
}
 -and $updatedCounts.ContainsKey($Matches[2])) {
                    $sourcePath = $Matches[2]
                    $updatedCounts[$sourcePath]++
                    $sourceLength = (Get-Item -LiteralPath (Join-Path $installFolder $sourcePath) -ErrorAction Stop).Length
                    "$sourceLength $sourcePath"
                }
                else {
                    $line
                }
            }
        )
        foreach ($sourcePath in $sourcePaths) {
            if ($updatedCounts[$sourcePath] -ne 1) {
                throw "Expected exactly one manifest entry for $sourcePath; found $($updatedCounts[$sourcePath])."
            }
        }
        $utf8Encoding = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText(
            $manifestPath,
            (($updatedLines -join "`n") + "`n"),
            $utf8Encoding
        )
        Write-Host 'Updated manifest sizes for the two rebuilt development source files.'
    }

    Write-Host 'Build completed. Launch Uncharted from Nativ and test your touchpad.' -ForegroundColor Green
    Write-Host "Backup folder: $backupFolder"
}
catch {
    Write-Warning "Build/setup failed: $($_.Exception.Message)"
    if ($sourceChanged) {
        foreach ($sourcePath in $sourcePaths) {
            Copy-Item -LiteralPath (Join-Path $backupFolder $sourcePath) -Destination (Join-Path $installFolder $sourcePath) -Force
        }
    }
    Copy-Item -LiteralPath (Join-Path $backupFolder 'game_host.exe') -Destination $mainBinary -Force
    Write-Warning "Original runtime sources and game executable restored. Backups remain at $backupFolder"
    throw
}
finally {
    Remove-Item -LiteralPath $temporaryFolder -Recurse -Force -ErrorAction SilentlyContinue
}
