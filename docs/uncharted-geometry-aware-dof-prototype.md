# Uncharted: Golden Abyss — geometry-aware DOF prototype (#2)

**Experimental, opt-in, not yet visually verified.** This branch is based on the original Distribution 35 experiment (`experiment/memory-graphics-aspect-20261114`), **not** Distribution 41. Its earlier five-tap blur reconstruction is deliberately excluded so the effects can be evaluated separately.

## Capture evidence

In `frame_2355.vfc`, DOF fragment program `0x1FA2AA48` (GXP content hash `0xB8A9CC91`) draws with:

- Unit 8, 720x408, packed HDR scene colour (`0x9a840000`)
- Unit 9, 180x102, packed HDR low-resolution blur (`0x9a000000`)
- Unit 10, 720x408, RGBA16F scene data (`0x1b840000`), stored tiled

Inspecting unit 10's actual half-float values shows smooth spatial coordinate changes across visible surfaces and sharp discontinuities at object boundaries. For example, early samples include `(-88.31, 5.12, 56.34, 19.98)`. The first three channels appear position-like. Neighbor differences, mapped as an image, trace the foliage, ground and stairs.

This supports a **geometry-aware** experiment. It does **not** establish that any particular channel is linear camera depth or prove the exact interpretation of `g_vDofParams`.

## What it changes

- Only when `RECOMP_UC_EDGE_DOF=1`, the targeted translated shader samples four additional full-resolution neighbors from unit 10, ±one original 720x408 pixel in X and Y.
- It computes a conservative boundary signal from the maximum absolute difference among the first three position channels and their neighbors.
- After the game's **original** DOF shader finishes its composition, this experiment gently restores up to **30% of the existing sharp scene color** at large geometry discontinuities; its alpha is preserved. Weight = `0.30 * clamp((maxPositionDelta - 0.35)/2.5, 0, 1)`.
- This is **edge protection**, not a faithful reconstruction of the game's CoC/blending weights. It may sharpen foreground outlines, but it may also sharpen distant objects or make existing jaggies more obvious. It is a conservative diagnostic prototype, not a confirmed fix.
- The shader cache key contains a dedicated high bit to keep original and geometry-aware modules separate.
- No five-tap blur from Distribution 41; no global filter changes; no modification to other shaders or games.
- Off by default. No Display setting is added yet.

## A/B test on Windows

Extract the Actions artifact into a **separate** directory and **recompile Uncharted with the candidate's runtime**. Keep the stable build and Distribution 35 unchanged.

Original:

```powershell
Remove-Item Env:RECOMP_UC_EDGE_DOF -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_UC_ENHANCED_DOF -ErrorAction SilentlyContinue
& '.\Project Nativ.exe'
```

Geometry-aware:

```powershell
$env:RECOMP_UC_EDGE_DOF = '1'
Remove-Item Env:RECOMP_UC_ENHANCED_DOF -ErrorAction SilentlyContinue
& '.\Project Nativ.exe'
```

A targeted startup message is expected:

```text
gpu: experimental Uncharted geometry-aware DOF active for shader 0x1fa2aa48
```

This message **confirms the feature's selection condition**, not that the visible correction had a measurable pixel effect. For diagnostic logging in PowerShell:

```powershell
$env:RECOMP_UC_EDGE_DOF = '1'
$logPath = Join-Path (Get-Location) 'edgeDof.log'
& '.\Project Nativ.exe' 2>&1 | Out-File -FilePath $logPath -Encoding utf8
Select-String -Path $logPath -Pattern 'geometry-aware DOF|shader'
```

Compare the same menu scene with HDR-consistent screenshots, ideally the Astra 2 stream as before. Examine:
1. The jagged boundary above and below the brown menu ribbon.
2. Stairway blur transitions and leaves near the middle left.
3. New sharp outlines or halos around foreground/distant objects (a potential failure mode).
4. In-game paused DOF, transition animations, menu text and gameplay.
5. GPU frame times during 120 FPS play; four position-neighbor samples and shader arithmetic have a cost.

## Decision and rollback

- If the boundary improves without unnatural sharpness or a frame-time regression, continue with more accurate CoC/depth weighting.
- If it sharpens or outlines the original artifact, **reject this prototype** and use the capture's position buffer to develop a more accurate edge-aware blend. Do not increase its strength.
- If no effect appears, verify the log and active shader variant, and determine whether the output already approximates the sharp input at those boundaries.

Rollback: close the game, run `Remove-Item Env:RECOMP_UC_EDGE_DOF -ErrorAction SilentlyContinue`, and relaunch, or restore Distribution 35.

**Important:** This is the first targeted implementation for #2, not a full depth-aware refactor or proof that the final artifact can be eliminated.
