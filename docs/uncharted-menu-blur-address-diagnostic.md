# Uncharted Golden Abyss — address-specific GPU-view diagnostic

## Status

This branch is **diagnostic only**, based on Distribution 35 plus the previous selective-by-size experiment. It does not modify the approved stable release or fix any underlying rendering defect.

## Evidence from captured frames

The menu-background distortion is present from Distribution 4 through Distribution 35. Broadly bypassing GPU render-target views (`RECOMP_GPU_NO_VIEWS=1`) appears to suppress that particular jagged boundary but corrupts other graphics and reduces FPS. Disabling fast view conversion or view-pass hoisting separately does not resolve the distortion.

Previous size-specific tests:
- `360x204` (capture `frame_4234.vfc`): effect persists.
- `180x102` (capture `frame_4840.vfc`): effect persists.
- `720x408` (capture `frame_2342.vfc`): picture changes substantially and becomes coarse; not a fix.

All three 720x408 render targets must not be conflated:
- `0x19d40000`: post-processing/HDR composition target. Menu draw 262 reads it with the quarter-resolution effect buffer.
- `0x19f89e00`: intermediate G-buffer or scene-data target sampled by several later passes.
- `0x1a1dfec0`: main scene target, also reused for final 720x408 compositing. Menu draw 263 samples the composited image.

Frame `frame_2355.vfc` captures the full draws 262–263. Some size-bypass captures are incomplete (started partway through an in-progress scene) and cannot independently establish a specific final draw's behavior.

## Diagnostic switch

`RECOMP_GPU_NO_VIEW_ADDR=0x19d40000` selects the **source render-target base address** to bypass its GPU view conversion, using the existing guest-memory read path. This selection does not disable all GPU views. It is inactive unless set. The switch is independent of `RECOMP_GPU_NO_VIEW_SIZE`; leave the size switch unset.

**Important:** Source-address matches that already use the renderer's direct exact-target fast path cannot be bypassed by this switch; the diagnostic logs that explicitly. Target addresses are guest-memory addresses observed in these captures, not guaranteed stable across game versions or recompilation.

Suggested order: `0x19d40000`, `0x19f89e00`, `0x1a1dfec0`. Restart Project Nativ between each test; source selection is read once per process.

```powershell
# Run in PowerShell on the Windows game PC from a separately extracted diagnostic distribution.
Remove-Item Env:RECOMP_GPU_NO_VIEWS -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_GPU_NO_VIEW_SIZE -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_GPU_VIEW_FAST -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_GPU_VIEW_HOIST -ErrorAction SilentlyContinue

$env:RECOMP_GPU_NO_VIEW_ADDR = '0x19d40000'
& '.\Project Nativ.exe'
```

Record in each run: whether the distinctive jagged boundary remains; whether surrounding graphics remain correct; FPS; and whether log text confirms the selected address was matched. Repeat at main and pause menus if safe.

Cleanup:
```powershell
Remove-Item Env:RECOMP_GPU_NO_VIEW_ADDR -ErrorAction SilentlyContinue
```

## Interpretation

One successful address-selective test would narrow the underlying source path. It would **not** prove faulty texture conversion until view mapping, sampling, and CPU/GPU differences were compared at that address. If none of the three source addresses changes the symptom, inspect the actual texture base addresses/format and target-alias selection and consider per-draw instrumentation. Do not promote this branch without gameplay validation.
