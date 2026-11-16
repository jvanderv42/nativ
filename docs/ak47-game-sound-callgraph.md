# AK47 high-level sound event investigation (read-only call-graph discovery)

Observed: Golden Abyss 1.00 repeats layered AK47 shots after the magazine empties while the fire button is held in cover. Reproduced at 30 and 120 FPS, with the default and Vita guest schedulers. Normal and defective NGS callbacks have matched delivery counts. The high-level sound-event stop path is **not yet identified**.

## Discovery

The current `sfx-context:` trace has a common immediate Play LR of `0x815acd3d`. The supplied repository does not include the user's decrypted Uncharted game or its locally generated analysis export, so it cannot prove the upstream owner solely from source inspection.

The Nativ pipeline generates `library/decrypted/PCSA00029/analysis/eboot.data.json` during `vitarecomp analyze`. Run the helper in a PowerShell session after verifying that file exists:

```powershell
# Run from a Project Nativ source checkout containing dev/Find-Ak47SoundCallers.py.
$analysisPath = Join-Path $env:LOCALAPPDATA 'ProjectNativ/Nativ/library/decrypted/PCSA00029/analysis/eboot.data.json'
if (-not (Test-Path -LiteralPath $analysisPath -PathType Leaf)) {
    throw "Missing analysis export: $analysisPath. Locate the existing eboot.data.json or run the normal analyze step."
}
py -3 dev/Find-Ak47SoundCallers.py $analysisPath --lr 0x815acd3d --depth 3 --top 60
```

This utility imports Capstone (a recompiler dependency), decodes **static direct** ARM/Thumb calls, identifies the function containing the logged return LR, and prints up to three levels of guest callers and call-site addresses. It does **not** modify the export, game code, pack config, NGS, or saves. Indirect calls may be missing; entries are candidates rather than confirmed sound-event ownership.

Review the upstream candidate list and the corresponding disassembly/analysis before choosing explicit HOOKS/IHOOKS entries. To prove cause, compare the same *held-fire at zero* trigger against *released-fire at zero* and capture game-side sound start, update and stop events. Do not implement a fixed sound timeout or unverified address hooks.

Stable `main` and the previous NGS diagnostic branch are preserved. No runtime build is necessary for this source-analysis-only helper.
