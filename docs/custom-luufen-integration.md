# Selective Luufen integration — experimental build

Baseline: [Project Nativ Custom v0.1.5-custom.3](https://github.com/jvanderv42/nativ/releases) (Distribution 20, commit `c1af8e2669742d7e886bb5cbc56ab9edcc94420e`).

This branch is **not a stable release**. It intentionally avoids a wholesale merge from Luufen/nativ, and it does not alter the published Distribution 20 binary.

## Imported and adapted

### Uncharted GPU render targets (Luufen UC-LAMP, `be7aec6`)
- Keep low-resolution post-processing buffers (`360x204`, `180x102`, `256x512`, `32x32`) at their native scaling while retaining the `720x408:1.3333` enhanced scene buffer.
- `runtime/gfx/target_scale.h`, `runtime/gfx/gfx_gpu.c`, `packs/PCSA00029/pack.toml`.
- Automated regression: `runtime/tests/target_scale_test.c`.
- Goal: avoid a grid/square appearance around glow effects at high rendering scales.

### Touch sampling/timing (Luufen touch fix, `52ec688`)
- Vita Peek/Read now use vblank-aligned timestamps and read-report counts rather than timestamps created per API call.
- Adapted to the existing Distribution 20 touchpad/Android input work without replacing controller or touch-contact handling.
- **A/B rollback:** `RECOMP_TOUCH_EDGE_SAMPLING=0` restores Distribution 20-style reporting; enabled by default on this experimental branch.
- `runtime/gfx/display.c`, `runtime/gfx/touch_edge_rules.h`; regression test: `runtime/tests/touch_edge_rules_test.c`.
- This has not been demonstrated to resolve Uncharted cinematic cursor stutter.

### 16:10 window output
- Distribution 20's `window` aspect option intentionally forced ratios narrower than the Vita's native 960:544 back to native. This branch permits proportional narrow output with `aspect_ratio=window`, aimed at 16:10 streaming.
- **A/B rollback:** `RECOMP_ALLOW_NARROW_ASPECT=0` restores the native-aspect clamp.
- `runtime/ui/window.c`, `runtime/ui/aspect_factor.h`; regression test: `runtime/tests/aspect_factor_test.c`.
- This changes camera/view output and could reveal HUD or touch alignment issues; validate before promotion.
- Nightjar and the Windows game output must agree on the selected stream/display aspect. If they do not, bars can remain.

## Deliberately not imported

### Controller mapping changes
Our fork already uses a tested DualShock 4 touchpad and L1/R1 front/rear touch workflow. Luufen's mapping labels, defaults and L/R mapping target different assumptions. Replacing them without gamepad validation risks breaking Vita system-menu navigation (Distribution 19 regression). Review separately if a specific mapping or UI limitation remains.

### Vita memory-budget/allocator rewrite
Luufen's memory budget and freed-block reuse may help other games (especially Silent Hill) but changes low-level allocation behavior across every game. We have no evidence it is needed to improve our tested Uncharted/Killzone workflows. Defer until isolated cross-game tests can establish its safety and usefulness.

## Validation checklist before any release
1. GitHub Actions target scale, touch edge and aspect factor tests pass; Windows distribution assembles successfully.
2. Recompile Uncharted with the candidate distribution; never overwrite the stable Distribution 20 installation.
3. Verify native 16:9 and window-shaped 16:10 output, including camera proportions, HUD, full screen, and touch alignment.
4. Verify L1/R1 touchpad modifier behavior, short taps, drag/release, and Vita save/load menu navigation.
5. Compare cinematics and transitions with `RECOMP_TOUCH_EDGE_SAMPLING=0` and enabled; note cursor frame pacing.
6. Compare lamps/glow at 1x/2x/4x render scale and check 60/120 FPS stream stability.
7. If any regression appears, return immediately to published Distribution 20 and isolate the changed feature before further work.

No published stable release should be replaced merely because CI passes; hands-on gameplay testing is required.
