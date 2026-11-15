# Uncharted Golden Abyss depth-of-field sampling — isolated diagnostic

**Status:** Experimental, not a fix. Based on Distribution 35 (`experiment/memory-graphics-aspect-20261114`). The stable release and tested Distribution 35 remain unchanged.

## Capture-based findings

Comparing `frame_2230.vfc` (sharp Touch to Start) and `frame_2355.vfc` (blurred menu):

- Fragment program `0x1fa2aa48` is exactly the same 806-byte GXP binary in both captures (SHA-256 `9773dd1e36f592aeaa93f8a84e1c099a960267095fa892de7d694b6e4f084f71`).
- The GXP includes named uniform `g_vDofParams` (four float words at its uniform-register index 16) and samplers `g_tEngineSampler0`, `g_tEngineSampler1`, `g_tEngineSampler2` (units 8, 9, 10).
- `g_vDofParams` changes from approximately `(0.25, 2.75196, 5.0, 0.14286)` to `(1.0, 10.13902, 0.1, 10.0)`. Those are exact values represented in the capture, not speculative shader parameter names.
- The shader contains 23 primary and 10 secondary USSE instructions and no **explicit** SMP instruction. Input samplers are supplied via the fragment pipeline's texture iterators.
- The captured draw reads three textures:

| Unit | Texture address | Size | Captured filter | GXP name |
|---|---|---|---|---|
| 8 | `0x19d40000` | 720 × 408 | point | `g_tEngineSampler0` |
| 9 | `0x1a7a27c0` | 180 × 102 | linear | `g_tEngineSampler1` |
| 10 | `0x19f89e00` | 720 × 408 | point | `g_tEngineSampler2` |

The low-resolution effect already enters this draw, which blends/weights samples before the final 960 × 544 menu composition.

**Unresolved:** whether the visible pixelated depth-of-field boundary is original game behavior, incorrect sampler interpolation, or a GPU shader translation mismatch. No GPU/software replay has established a divergence. This diagnostic does not establish a fix.

## Temporary A/B switch

`RECOMP_UC_DOF_SAMPLER` is read on the first relevant sampler binding; close and relaunch between tests.

- Unset: original Vita sampler filter settings, unchanged.
- `depth-linear`: change unit 10 from point to linear **only for shader `0x1fa2aa48`** (does not assert that this is literally a hardware depth texture).
- `scene-linear`: change unit 8 from point to linear for the same shader.
- `blur-point`: change unit 9 from linear to point for the same shader, as a negative control.

All modes leave other programs, source-texture data, formats, render-target view selection, and other samplers untouched.

### PowerShell, Windows gaming PC

```powershell
# From a separate experimental installation; the game must use its recompiled diagnostic runtime.
Remove-Item Env:RECOMP_GPU_NO_VIEWS -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_GPU_NO_VIEW_SIZE -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_GPU_NO_VIEW_ADDR -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_GFX_CHECK -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_GFX_CHECK_FPROG -ErrorAction SilentlyContinue

$env:RECOMP_UC_DOF_SAMPLER = 'depth-linear'
& '.\Project Nativ.exe'
```

Verify the log reports that the shader sampler was changed. Inspect the same blurred main and pause menus. Compare the jagged/stepped boundaries, correct color and geometry, and FPS against default settings. Test `scene-linear` only if needed, then `blur-point` as an optional negative control.

Cleanup:

```powershell
Remove-Item Env:RECOMP_UC_DOF_SAMPLER -ErrorAction SilentlyContinue
```

Do not promote this branch based on visual improvements alone. If smoothing only hides a wrong depth-of-field threshold or introduces halos, the underlying emulator mismatch would remain.
