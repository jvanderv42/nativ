# Uncharted DOF: focused GPU/software comparison

This branch is an **instrumentation-only candidate** based on the tested Distribution 35 source. It does not change texture sampling, shader math, GPU-view selection, or the stable release.

## What prior capture tests established
- The jagged menu/pause-screen blur exists in Distribution 4, 20, 27 and 35.
- The DOF composition fragment program is `0x1fa2aa48`. Its GXP calls the parameter vector `g_vDofParams` and reads three samplers, including a 180x102 effect input.
- Point filtering the 180x102 input produces obvious blocky pixels. Making the two 720x408 point-filtered inputs linear has no meaningful visible improvement.
- All three new filtering-test captures have `g_vDofParams=(0.25,2.752,5.0,0.14286)` whereas the older fully blurred `frame_2355.vfc` has `(1.0,10.139,0.1,10.0)`. Do not interpret them as identical DOF operating points.
- No GPU/software divergence has been demonstrated. A reference from real Vita/Vita3K is still required to judge whether the game's blur was intentionally coarse.

## New diagnostics
The existing `RECOMP_GFX_CHECK=rgb` compares every GPU draw with the software renderer, which is prohibitively slow.
New `RECOMP_GFX_CHECK_ONLY_FPROG=1fa2aa48` restricts the *comparison execution*, not just full-report selection, to this fragment program. Without the new variable, previous behavior is preserved. The existing `RECOMP_GFX_CHECK_FPROG` independently selects which program gets the full report and may also be set.

For Windows, comparison images are now written to the current working directory instead of the POSIX-only `/tmp` path:
- `gfxcheck_gpu.ppm`, `gfxcheck_soft.ppm`
- `gfxcheck_tex0.ppm`, etc., for bound source textures

The comparison may still be slow on a 720x408 full-screen draw. It also has known limitations for depth-buffer history and software draws sampling GPU render targets. Treat disagreements as evidence for deeper investigation, **not yet a confirmed GPU translator bug**.

## Windows diagnostic procedure
Run from a separate installation folder containing the newly recompiled Uncharted runtime.

```powershell
# Reset other experimental rendering settings.
$clearVariables = @(
    'RECOMP_GPU_NO_VIEWS', 'RECOMP_GPU_NO_VIEW_SIZE',
    'RECOMP_GPU_NO_VIEW_ADDR', 'RECOMP_GPU_VIEW_FAST',
    'RECOMP_GPU_VIEW_HOIST', 'RECOMP_UC_DOF_SAMPLER'
)
foreach ($variableName in $clearVariables) {
    Remove-Item -Path "Env:$variableName" -ErrorAction SilentlyContinue
}

$env:RECOMP_GFX_CHECK = 'rgb'
$env:RECOMP_GFX_CHECK_ONLY_FPROG = '1fa2aa48'
$env:RECOMP_GFX_CHECK_FPROG = '1fa2aa48'

& '.\Project Nativ.exe'
```

If slow, run only long enough to reach the blurred title menu, then close normally. Save `gfxcheck_*.ppm` files and the `RECOMP_GFX_CHECK` console output. Captures may include copyrighted game imagery; do not upload publicly.

Rollback, in the same shell:
```powershell
Remove-Item Env:RECOMP_GFX_CHECK -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_GFX_CHECK_ONLY_FPROG -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_GFX_CHECK_FPROG -ErrorAction SilentlyContinue
```

**Acceptance decision:** If GPU and software agree in the DOF draw, do not pursue a shader-translation fix based on this test. Compare the result to an original Vita/Vita3K reference to decide whether a cosmetic enhancement is justified. If they differ, identify the first divergent input or intermediate value before changing shader code.
