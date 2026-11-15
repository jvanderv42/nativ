# Uncharted: Golden Abyss — depth-guided DOF experiment

**Status:** Experimental, off by default, not visually verified. Based on Distribution 35; Distribution 41 and 42 are not merged.

## What we learned

Distribution 41's five-tap smoothing barely changed the menu's blocky blur. Distribution 42's position-discontinuity sharpening revealed ghostlike branches and geometry without removing the coarse transitions. The problem with 42 was restoring sharp scene content irrespective of focus.

The captured Uncharted DOF fragment program `0x1FA2AA48` reads:
- Unit 8: original 720×408 HDR scene color.
- Unit 9: 180×102 low-resolution blur texture.
- Unit 10: 720×408 four-component floating-point scene-position-related buffer.

The fourth component of unit 10 varies smoothly within many surfaces and has discontinuities at boundaries. For example, in `frame_2355.vfc` the adjacent horizontal pixel difference is below 0.375 for roughly 90% of comparisons, while a smaller fraction jumps by many units. This is evidence for a depth-like signal, **not proof of camera-linear depth**. We have **not** yet decoded the original `g_vDofParams` circle-of-confusion equation.

## Distribution 43 prototype

With `RECOMP_UC_DEPTH_DOF=1` and only for captured fragment GXP hash `0xB8A9CC91`, the shader reconstructs unit 9 using the four surrounding low-resolution texels. Their normal bilinear weights are multiplied by a depth compatibility term:

```text
compatibility = 1 / (1 + (abs(centerW - neighborW) / 2)^2)
weight = bilinearWeight * compatibility
reconstructed = sum(weight * blurColor) / max(sum(weight), 0.00001)
outputBlur = 0.20 * originalBilinear + 0.80 * reconstructed
```

The depth-like W values are sampled from full-resolution unit 10 at the current fragment and at each low-resolution blur texel center. The **original guest shader then computes its own DOF blend unchanged**.

The method attempts to avoid mixing blur samples whose underlying positions differ greatly. It does not restore sharp scene detail after composition (unlike Distribution 42). It does not change the game's DOF strength, shader uniforms, foreground focus, menu graphics, or other games.

### Limitations and risks

- The low-resolution blur texel already aggregates colors across its source footprint. Depth compatibility cannot recover lost colors or guarantee halo-free edges.
- This is not yet a decoded CoC or a replacement for the original DOF blending equation. The weighting uses an experimental 2-unit threshold and may be too subtle, too aggressive, or inconsistent across scenes.
- Extra samples: four blur samples plus five full-resolution position samples in the targeted shader, beyond the original sampling. Verify frame times, especially at 120 FPS.
- Source sampler coordinates are assumed normalized to the 180×102 low-resolution texture; a different game version or texture layout could require changes.
- Activation log confirms shader selection, not correct visual contribution.
- The original renderer remains the baseline, and the change is fully reversible.

## Test

Extract the Windows Actions artifact to a separate directory and recompile Uncharted with the candidate runtime. Use the same settings and game state for each run. On the Windows gaming PC, in PowerShell in the candidate directory:

**Original:**
```powershell
Remove-Item Env:RECOMP_UC_DEPTH_DOF -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_UC_EDGE_DOF -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_UC_ENHANCED_DOF -ErrorAction SilentlyContinue
& '.\Project Nativ.exe'
```

**Depth-guided:**
```powershell
$env:RECOMP_UC_DEPTH_DOF = '1'
Remove-Item Env:RECOMP_UC_EDGE_DOF -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_UC_ENHANCED_DOF -ErrorAction SilentlyContinue
& '.\Project Nativ.exe'
```

Look for `gpu: experimental Uncharted depth-guided DOF active for shader 0x1fa2aa48` in stderr. Restart the application between runs. Capture both views from Astra 2 to avoid the HDR snipping mismatch.

**Accept** only if the jagged transition is visibly reduced without new outlines, unnatural sharpness, blur smearing, temporal flicker or worse 120 FPS frame pacing. **Reject** if changes are absent or distracting. In that case, stop varying arbitrary thresholds and investigate the actual shader CoC equation and depth representation before another enhancement.

**Rollback:** unset `RECOMP_UC_DEPTH_DOF` and restart; Distribution 35 is unchanged.
