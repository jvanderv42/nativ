# Uncharted: Golden Abyss — Enhanced DOF prototype

**Status: experimental opt-in, not a verified visual correction.** Based directly on Distribution 35. Original rendering remains the default. The accepted stable builds and Distribution 35 are unchanged.

## Why

Captured Uncharted menu images reveal a 180x102 quarter-resolution depth-of-field input sampled by fragment program `0x1fa2aa48` (`g_vDofParams`). The game's existing blur transition has a coarse, irregular boundary. Real PlayStation TV footage suggests some of the blockiness is inherited from the Vita game, and 4x render scale makes it easier to see.

Prior tests showed changing the two scene input samplers to linear does not improve the boundary; changing the 180x102 blur texture to point filtering causes severe visible pixelation. We are therefore testing whether **slightly smoother reconstruction of that original low-resolution blur input** improves image quality while preserving the game's shader and DOF parameters.

## What changed

- `RECOMP_UC_ENHANCED_DOF=1` enables a five-sample cross-filter on **nondependent fragment texture unit 9**, only in the verified Uncharted DOF fragment GXP (content hash `0xb8a9cc91`). The original bilinear centre tap has weight 0.5, and each of the four samples one low-resolution texel left/right/up/down contributes 0.125.
- Normal sampler modes, input texture data, the game's `g_vDofParams`, game code, other shader programs, UI, controller handling and resolution settings are preserved.
- An additional shader-variant cache-key bit ensures that enhanced and original shaders do not share a shader-cache entry. The feature is **completely off when the environment variable is absent**, avoiding any extra samples during normal rendering.
- This initial version is **not depth-aware**. It may smooth the coarse blur but cannot reconstruct missing detail or repair a depth-mask threshold. It may also introduce halos or extra softness; those are explicit rejection criteria.

The enhancement is an opt-in prototype using an environment variable. A permanent **Display > Depth of Field: Original / Enhanced** UI setting is a separate follow-up after visual and frame-time validation, not implemented here.

## A/B testing

On the Windows gaming PC, extract this candidate into a separate directory and recompile Uncharted using the candidate runtime. Avoid using your accepted Distribution 35 installation for the experiment.

Run with original rendering:

```powershell
Remove-Item Env:RECOMP_UC_ENHANCED_DOF -ErrorAction SilentlyContinue
& '.\Project Nativ.exe'
```

Then close the process and run with Enhanced DOF:

```powershell
$env:RECOMP_UC_ENHANCED_DOF = '1'
& '.\Project Nativ.exe'
```

For the enhanced run, verify that stderr contains `gpu: experimental Uncharted Enhanced DOF active`. If absent, do not infer the enhancement was active. Use identical game resolution, graphics settings, menu state, camera and DOF intensity between runs.

Inspect:
1. The irregular contour below/around the brown title-menu ribbon and the stone steps.
2. Fine foreground edges, foliage, menu text and gameplay — must not acquire halos or additional blur.
3. The in-game pause menu — same effect must remain correct.
4. Movement/transition into and out of the menu (no flashing or temporal artifacts).
5. At 120 FPS, frame-time consistency and streaming through Nightjar (visual quality wins do not justify frequent >8.33 ms frames).

If the effect is improved without noticeable degradation, preserve screenshots and results before further development. If it worsens halos, sharpness or frame pacing, revert.

**Rollback**: close game and run `Remove-Item Env:RECOMP_UC_ENHANCED_DOF -ErrorAction SilentlyContinue`, then restart the game. You can also switch back to Distribution 35; this branch doesn't modify it.

## Known limitations

- Shader matching is by this captured GXP content hash; if a different game version uses a different GXP, the prototype will remain inactive.
- `RECOMP_UC_ENHANCED_DOF=1` is read when its target shader is used; restart the process between tests.
- A five-tap smoothing filter is an enhancement hypothesis, not a confirmed fix. More complex edge/depth-aware methods should only follow if image quality warrants them.
- The earlier GPU/software shader comparison did not produce PPM differences, but without a positive checker-execution report that does not prove agreement.
