# Uncharted v1.03 halo — bounded parity diagnostic (November 18, 2026)

**Experimental branch only. Not a halo fix.** Commit 406255ad modifies only `runtime/gfx/gfx_gpu.c`.

## Why
The original `RECOMP_GFX_CHECK_FPROG` selected only the *report*, not the expensive comparison. In a Windows session it checked thousands of unrelated draws, downloaded 100K+ GPU targets and made the game nearly unplayable. Its images were hardcoded to `/tmp`, which was missing on the user's Windows installation.

## Updated behavior
- `RECOMP_GFX_CHECK=rgb` enables RGB comparison.
- `RECOMP_GFX_CHECK_FPROG=1fa2e708` filters **before** GPU target synchronization and CPU reference rendering. The value is a guest fragment program **address**, not a content hash. Without a filter, the first eight otherwise-eligible draws are checked.
- The process performs **up to eight comparisons**; subsequently normal GPU rendering continues.
- Images go to the game's **working directory**: `gfxcheck_gpu.ppm`, `gfxcheck_soft.ppm`, and `gfxcheck_tex<unit>.ppm`. The log now explicitly states `saved`, `cannot create`, or `failed writing`.
- Images are produced only when a selected draw has a mismatch above the existing threshold. No output files does not necessarily mean an error; check the session log.
- The software reference still starts with **cleared depth/stencil**, NOT a copy of the GPU's accumulated depth/stencil history. For depth/stencil-dependent draws, the log marks a mismatch `INCONCLUSIVE` and it must not be treated as evidence of incorrect shader translation. The parity check does **not yet** provide a fully faithful depth/stencil comparison.

## Windows validation procedure
1. Keep the existing working distribution intact. Install an extracted build #86 as a separate directory. No Uncharted recompilation is necessary for this runtime-only change.
2. Verify the package/build metadata points to commit `406255ad` or later.
3. Temporarily enable these process environment variables (PowerShell, in the new distribution directory, with `Project Nativ.exe` replaced by the packaged executable path if necessary):

```powershell
$env:RECOMP_GFX_CHECK = 'rgb'
$env:RECOMP_GFX_CHECK_FPROG = '1fa2e708'
$env:RECOMP_SESSION_LOG = '1'
& '.\Project Nativ.exe'
Remove-Item Env:RECOMP_GFX_CHECK, Env:RECOMP_GFX_CHECK_FPROG, Env:RECOMP_SESSION_LOG -ErrorAction SilentlyContinue
```

4. Set game to v1.03, render scale 1×, FXAA Off, halo investigation Normal. Run until the area where the halo can be observed.
5. In the distribution's current working directory, check for `gfxcheck_gpu.ppm`, `gfxcheck_soft.ppm`, `gfxcheck_tex*.ppm` and `session.log`.
6. Log should show at most eight selected comparisons, not thousands of unrelated `also divergent` lines. A selected mismatch should produce image-write statuses.
7. Treat any reported mismatch involving depth/stencil as a diagnostic clue only. Seek an accurate full-frame replay of accumulated depth and stencil before deciding whether the shader translator is wrong.

## Scope and rollback
No renderer output is intentionally altered by this diagnostic code when the feature is off, and normal gameplay should remain unaffected. To revert, remove the three temporary environment variables and launch the previous working distribution; do not merge diagnostic changes to `main` yet.

## Validation state
Source inspection completed; Windows compilation and GPU behavior depend on GitHub Actions build #86 and a subsequent on-device test. No claim of full depth/stencil parity is made.
