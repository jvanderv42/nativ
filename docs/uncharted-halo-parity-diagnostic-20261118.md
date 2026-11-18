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

## November 18 follow-up: on-demand capture

The earlier eight-draw shader filter ran during startup, before Drake reached the actual halo location. The new opt-in **manual trigger** addresses that without slowing ordinary navigation:

- Set `RECOMP_GFX_CHECK_TRIGGER=1` in addition to the three environment variables above, before starting the game.
- Navigate to the lighting/angle where the halo is clearly visible, then press **F11** once.
- Only after F11, Nativ checks the next eight eligible draws matching `RECOMP_GFX_CHECK_FPROG`. This is a **one-shot diagnostic**: subsequent presses do not reset the budget, and restarting the program is necessary for a new capture.
- `F11` is inert with respect to this feature unless the explicit trigger environment variable is present.
- The log prints `F11 armed shader-specific comparison`, `selected first draw`, and `completed eight comparisons`. Diagnostic PPMs are written only for the **first differing draw**; if there are no differences, no images are expected.
- File output remains relative to the process **working directory**.
- **Important:** neither this trigger nor the prior patch synchronizes the interpreter's accumulated GPU stencil/depth state. For draw `0x1fa2e708` (stencil_func 5), the comparison remains **inconclusive as evidence of a shader translation fault**.

Example PowerShell (run from the *diagnostic distribution directory*):

```powershell
$env:RECOMP_GFX_CHECK = 'rgb'
$env:RECOMP_GFX_CHECK_FPROG = '1fa2e708'
$env:RECOMP_GFX_CHECK_TRIGGER = '1'
$env:RECOMP_SESSION_LOG = '1'
& '.\Project Nativ.exe'
Remove-Item Env:RECOMP_GFX_CHECK, Env:RECOMP_GFX_CHECK_FPROG, Env:RECOMP_GFX_CHECK_TRIGGER, Env:RECOMP_SESSION_LOG -ErrorAction SilentlyContinue
```

The PowerShell session must remain in the distribution directory, or else the PPM files will be emitted into the actual working directory used at launch. Do not reuse older PPM files when reviewing a new comparison.

## Phase 1 — GPU stencil-coverage reference (November 18)

The earlier 40,875-pixel F11 mismatch was **inconclusive** because the CPU reference was initialized with cleared stencil and the target shader uses stencil function `5` (NOT_EQUAL).

The experimental diagnostic now includes a GPU-side stencil-coverage pass that uses the same hardware stencil attachment, stencil comparison, reference and compare mask as the target draw. Its pipeline uses KEEP for all stencil operations, a zero stencil write mask, and no depth testing. A separate RGBA8 target receives white pixels where the comparison passes and black elsewhere. This target is read back strictly for the diagnostic; normal gameplay render targets and their contents are unchanged.

For a supported draw, the software reference executes without its reset stencil test, and pixels outside the measured GPU coverage are replaced with their pre-draw colors before comparison. This permits a more meaningful **color-output comparison for the pixels the original stencil compare allows**, without assuming that stale CPU stencil bytes match the actual GPU stencil.

### Scope restrictions (intentional)
- Render scale must be 1×, the GPU color and depth/stencil surfaces must have matching dimensions, depth comparison must be ALWAYS, depth writing must be disabled, and the targeted draw must not modify stencil (unless its stencil write mask is zero).
- When any of these conditions is absent, the diagnostic logs that coverage is unavailable and retains the previous **INCONCLUSIVE** warning for depth/stencil-dependent comparisons.
- This is **not** a general depth/stencil readback, and it does not establish shader correctness on unrelated depth-tested draws. It also cannot prove fidelity to native Vita hardware when both paths share a decoding error.
- The shader's GPU input textures must still be considered separately; a color-output disagreement could reflect an input-synchronization difference.

### Expected new log / file
`RECOMP_GFX_CHECK: GPU stencil coverage N/294912 pixels; software output masked using actual GPU stencil compare...`

The first divergent selected draw produces `gfxcheck_gpu.ppm`, `gfxcheck_soft.ppm`, and new `gfxcheck_stencil_mask.ppm`. Compare all three and the `session.log`, not just the percentage of differing pixels.

### Build note
The new Vulkan fragment shader lives at `runtime/gfx/shaders/stencil_mask.frag`. The Windows distribution workflow compiles **only this additional shader** with `glslangValidator` and appends it to the package's generated `runtime/gfx/vk_shaders.h`. The existing precompiled Vulkan shaders are left untouched. Manual source builds must compile/append that shader or regenerate the header using the repository's shader build script before compiling the game. The Windows compilation check and on-device comparison must be verified separately.

### Runtime installation / recompilation

The Project Nativ launcher distribution includes runtime source; the game executable incorporates that source at its build. To test new GPU runtime code, rebuild/recompile the **Uncharted v1.03 game executable** with the new diagnostic distribution. Retain the prior known-good game executable and distribution for rollback. Merely extracting the distribution and launching an older already-compiled game may leave it using the old renderer.
