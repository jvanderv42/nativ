# Collect the original Uncharted v1.03 Vita shader programs for offline USSE analysis.
# Run in Windows PowerShell 5.1 or PowerShell 7 on the gaming PC.
# Read-only with respect to the game: this launches it, saves .gxp copies and restores environment settings.
# Requires a Nativ game executable built from a runtime supporting RECOMP_DUMP_GXP.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$gameExecutable,

    [string]$dumpFolder = (Join-Path (Get-Location).Path 'unchartedShaderDump'),

    [string[]]$targetAddresses = @('1fa2e708', '1fa44f08', '1fa14d08')
)

$ErrorActionPreference = 'Stop'

# Resolve and validate input paths before launching the game.
$resolvedExecutable = (Resolve-Path -LiteralPath $gameExecutable -ErrorAction Stop).ProviderPath
if (-not (Test-Path -LiteralPath $resolvedExecutable -PathType Leaf)) {
    throw "Executable not found: $gameExecutable"
}
$gameFolder = Split-Path -Parent $resolvedExecutable
$gameName = Split-Path -Leaf $resolvedExecutable
$dumpFolder = [System.IO.Path]::GetFullPath($dumpFolder)
[System.IO.Directory]::CreateDirectory($dumpFolder) | Out-Null

# Prevent pre-existing output from being mistaken for this run's capture.
$startTime = Get-Date
$previousDump = [Environment]::GetEnvironmentVariable('RECOMP_DUMP_GXP', 'Process')
$previousLocation = (Get-Location).Path
try {
    $env:RECOMP_DUMP_GXP = $dumpFolder
    Set-Location -LiteralPath $gameFolder
    Write-Host "Starting $gameName; shader programs will be saved to $dumpFolder"
    Write-Host 'Open Uncharted v1.03, reach the title screen (or gameplay), then exit normally.'
    & $resolvedExecutable
    $exitCode = $LASTEXITCODE
    Write-Host "Game process exited with code $exitCode"
}
finally {
    [Environment]::SetEnvironmentVariable('RECOMP_DUMP_GXP', $previousDump, 'Process')
    Set-Location -LiteralPath $previousLocation
}

# Match the guest program addresses; list modification times to identify fresh captures.
$results = foreach ($address in $targetAddresses) {
    if ($address -notmatch '^[0-9A-Fa-f]{8}$') {
        throw "Invalid eight-digit hex program address: $address"
    }
    $filePath = Join-Path $dumpFolder ("{0}.gxp" -f $address.ToLowerInvariant())
    if (Test-Path -LiteralPath $filePath -PathType Leaf) {
        $file = Get-Item -LiteralPath $filePath
        $fresh = $file.LastWriteTime -ge $startTime.AddSeconds(-2)
        [pscustomobject]@{
            programAddress = $address.ToLowerInvariant()
            capturedThisRun = $fresh
            bytes = $file.Length
            filePath = $file.FullName
        }
    }
    else {
        [pscustomobject]@{
            programAddress = $address.ToLowerInvariant()
            capturedThisRun = $false
            bytes = 0
            filePath = $filePath
        }
    }
}

$results | Format-Table -AutoSize
if (-not ($results | Where-Object { $_.programAddress -eq '1fa2e708' -and $_.capturedThisRun })) {
    Write-Warning 'Target ambient/specular GXP was not captured this run. Check that the executable contains RECOMP_DUMP_GXP support and that the game registered this shader.'
}
Write-Host 'Upload the captured .gxp files, especially 1fa2e708.gxp, for register/instruction mapping.'
