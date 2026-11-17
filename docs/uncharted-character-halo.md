# Uncharted: Golden Abyss — character outline / halo (November 17, 2026)

**Status: origin in the original Vita game confirmed by contemporaneous reviews; the exact cause of any additional Project Nativ amplification has NOT been established. No speculative renderer fix.** This is an investigation record for the experimental v1.03 branch, not acceptance of a new rendering patch.

## Independent baseline

The original February 2012 IGN review described "a noticeable halo around drake in certain spots" (https://www.ign.com/articles/2012/02/13/uncharted-golden-abyss-review). A separate February 2012 Vita review described "a weird aura around some of the character models and stuff" (https://www.yetanotherreviewsite.co.uk/2012/02/21/uncharted-golden-abyss/).

This demonstrates the effect predates Project Nativ. It does not establish that the particular halo visible in the user's Windows recordings is identical in strength, location, color, or shader cause. An original artifact may still be worth improving, but that would be an explicit visual enhancement, not automatically a bug fix.

## Controlled captures already supplied

| Capture | Game | Resolution scale | Menu/pause DOF correction | Halo |
|---|---|---:|---|---|
| frame_2177.vfc and 2026-11-17 13-08-00.mp4 | 1.03 | 1x | Off | present |
| frame_4539.vfc and 2026-11-17 13-04-43.mp4 | 1.03 | 1x | On | present |
| frame_6001.vfc and 2026-11-17 13-01-11.mp4 | 1.03 | 4x | Off | present |
| frame_47045.vfc, frame_49137.vfc and 2026-11-17 12-52-54.mp4 | 1.03 | 4x | On | present |

Menu/pause DOF is confirmed functional because switching it Off restores the previously corrected menu and pause artifacts. Since the halo persists when Off, avoid changing the menu/pause DOF correction for this issue.

The game renders using multiple intermediate surfaces, including main scene / position data and compositing passes. For draw dependency mapping see `halo-investigation-20261117.md` from the working analysis. Recovered MEMP records cannot reliably stand in for GPU render-target results: target bytes may be stale or formatted as depth/position rather than RGB color. No faulty draw or shader has yet been proven.

## Decision and safety

- Do not change global renderer color, alpha, depth, FXAA, SSAO, shader translation or menu/pause DOF based solely on this halo; these would risk regression in 1.00, Killzone, and scenes without the artifact.
- Do not treat a stable 1x/4x result as proof of correct rendering; the effect could be original, amplified, or modified by recompilation.
- Preserve the branch's native 1.03 shader bundles, the LDST provenance fix, and the accepted v1.00-derived menu/pause DOF method.
- A useful candidate should identify its *specific* contributing shader or pass; be Off by default, affect Uncharted only, be reversible in the Game menu, and pass 1x/4x and 1.00/Killzone regression checks before merge.

## Consolidated no-rebuild comparison (if needed)

Existing F10 controls already allow testing in one session, without any new distribution:
1. Preserve the same save, camera position and lighting. Keep menu/pause DOF unchanged.
2. Toggle antialiasing FXAA Off/On; note whether the fringe changes or only edge softness changes.
3. Toggle ambient occlusion Off/On in Display if available; note whether the fringe changes.
4. Compare original 1.03 screenshots with original Vita footage or a real Vita at the same location, if available. A visual match is the strongest basis for declaring the effect a faithful original artifact.
5. If the halo differs materially from Vita, trace intermediate GPU surfaces with gfxreplay using RECOMP_REPLAY_KEEP_TARGETS=1 and inspect the original color target and postprocessing outputs. Captured G-buffer/position surfaces must not be interpreted as RGB frames without format-aware decoding.

## Pre-merge follow-up

Do not claim the halo is fixed or implement a broad visual patch until baseline fidelity and a targeted cause have been established. Treat optional attenuation of an original-game halo as a separate enhancement from implementing v1.03 support. Defer the separate 4x menu seam issue for later.
