# Uncharted menu blur: selective GPU-view diagnostic

This experimental branch starts from the tested Distribution 35 code. It changes only GPU-view selection and the Windows build workflow. It is **not** a graphical correction or stable release.

## Why this exists

The same jagged blur boundary appears in the main menu and in-game pause menu in older and newer distributions.

Observed A/B checks:
- `RECOMP_GPU_NO_VIEWS=1`: the specific boundary appears absent, but unrelated rendering becomes incorrect and performance decreases.
- `RECOMP_GPU_VIEW_FAST=0`: boundary persists.
- `RECOMP_GPU_VIEW_HOIST=0`: boundary persists.

The next question is which source render-target size, if any, contributes to the problem.

## Temporary switch

`RECOMP_GPU_NO_VIEW_SIZE=<width>x<height>` bypasses GPU view conversion for that Vita render-target size, taking the existing guest-memory read path instead. It is disabled when unset. The size refers to the original target's dimensions, not 4x host render scale. Other render-target views are unchanged. Direct exact-target sampling is unchanged.

Suggested independent test values:

- `720x408` — main world/composition surface
- `360x204` — half-resolution post-processing
- `180x102` — quarter-resolution post-processing

To test, close the game, run Project Nativ from the same PowerShell process, and examine the menu and pause blur at unchanged graphics settings:

```powershell
# Run on your Windows gaming PC, from the extracted experimental distribution.
Remove-Item Env:RECOMP_GPU_NO_VIEWS -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_GPU_VIEW_FAST -ErrorAction SilentlyContinue
Remove-Item Env:RECOMP_GPU_VIEW_HOIST -ErrorAction SilentlyContinue
$env:RECOMP_GPU_NO_VIEW_SIZE = '360x204'
& '.\Project Nativ.exe'
```

Close the program before changing to another size, because the selection is read once per process. Remove the diagnostic variable to restore default behavior:

```powershell
Remove-Item Env:RECOMP_GPU_NO_VIEW_SIZE -ErrorAction SilentlyContinue
```

## What to record

For each of the three sizes: (1) whether the distinctive jagged transition is present, reduced or absent, (2) whether the rest of the background and UI are correct, (3) whether FPS is stable, and (4) whether the result is consistent in the main and pause menus.

If all three selective tests leave the problem unchanged, the next step is identifying the exact sampled view by target address and format rather than assuming an effect buffer based on dimensions.

A successful visual result is evidence for a specific branch of rendering, **not proof** of the root cause. Do not promote this diagnostic build as a fix.
