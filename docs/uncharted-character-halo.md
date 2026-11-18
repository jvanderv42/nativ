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


## November 17 update: controlled v1.00 and v1.03 comparison

Older v1.00 AK47 gameplay captures (ak47-30fps-onset.jpg, ak47-6-detailed.jpg,
ak47-stuck-sound-onset-frames.png) show Drake in the ruins without the prominent
bright silhouette in v1.03 videos. These frames are *not* location/camera/lighting
matched, so the comparison raises a credible v1.03 regression hypothesis but does
not prove it. Original Vita reviews remain a separate historical observation.

The pack does **not** configure RECOMP_SSAO; Project Nativ's optional SSAO
postprocess is not enabled for this title, so disabling it is not a useful halo
diagnostic in the current build.

## Consolidated experimental v1.03 diagnostic — one build

The 1.03-only F10 → Game option **Character halo investigation** defaults to
**Normal** and offers two diagnostic modes in addition to **Normal**:
- **Skip late overlays**: omits captured fragment program `0x1fa0cec8` (frame_2177 draws 340–342), which normally writes into intermediate target `0x19d40000`; the final composite remains active. Look for a change in the silhouette or scene effects.
- **Before final composite**: omits fragment program `0x1fa3c1c8` (frame_2177 draw 353), which normally samples processed target `0x19d40000` and writes to the original scene target `0x1a1c00c0`. This bypass may display incorrect colors or incomplete imagery because that final pass also changes target interpretation.

No guest shader/program bytes, audio, physics or v1.00 paths are modified.

- Expect the bypass image to look unusually bright, dark, tonally incorrect,
  or to omit other effects. This is **not** a visual-quality mode.
- At the same camera location where the halo appears, compare Drake's **edge
  shape**, not overall brightness, between Normal, Skip late overlays, and Before final composite.
- If Skip late overlays changes the edge, investigate those overlay shaders and their inputs. If only Before final composite changes the edge, investigate the final composite and upstream targets. If none changes it, prioritize main-scene character lighting, shader translation, and earlier depth processing. The before-final view may be too visually degraded to judge; do not infer a result from unusable imagery.
- Additionally compare FXAA Off vs FXAA On using the existing Display menu
  (no rebuild needed). Do not change resolution/camera between comparisons.
- Restore **Normal** after the A/B comparison. Do not keep the bypass enabled
  for gameplay.
- Remains a *diagnostic* and does not establish the specific cause or eliminate
  the halo. No original Vita parity claim until matched footage is available.

The investigation is isolated to the experimental branch. Do not merge the
bypass into the main release without a decision to remove or hide it.


## Character material audit — 2026-11-17 (after eight screenshots)

Read-only VFC analysis identifies the actual outfit texture, not just a generic character-shaped render target:

- `frame_2977.vfc` primary scene draws **249–251** and `frame_5428.vfc` draws **266–268** use vertex program `0x230d5288`, fragment program **`0x1fa44f08`**, seven vertex attributes and 2,874/4,800/2,964 indices. The first two draws sample PVRTC-II 512×1024 textures at **`0x1c076060`** (outfit diffuse, visually identified from a read-only texture block-endpoint preview of Drake's shirt and straps) and `0x1c0d0060` (blue normal-map-like texture).
- Additional draws `frame_2977` **263–264** and `frame_5428` **282–283** reuse those clothing textures but use vertex program **`0x230a7b48`** / fragment program **`0x1fa1d988`**. This vertex program is among the five v1.03 LDST translator cases. Primary outfit vertex program `0x230d5288` is *not* one of those five, so do not blame the whole body halo on LDST without further evidence.
- Another mesh with 3,084 indices appears at main scene draw 317 and another later pass draw 383 (`frame_2977`). The draws reuse exactly the same index buffer `0x23e79960` and vertex streams `0x23e7b180` and `0x23e755a0` with vertex programs `0x230a6b08` / `0x230907c8` respectively. Both are LDST cases, but that mesh has **not** been identified as Drake.
- Nativ's PVRTC-II decoder has a documented missing hard-block mode-1 path. The captured outfit materials **do not contain any hard-transition mode-1 blocks** (0% among the sampled textures), so that specific decoder omission is unlikely to explain the observed bright silhouette.
- Across the eight user screenshots the halo survives both resolutions and the `0x1fa0cec8` late-overlay bypass. Final-composite bypass yields unusable multicolored output; it is not evidence of a correction. FXAA softens edges but does not eliminate the bright highlights.

**Next engineering target:** Compare original-vs-translated character fragment shader `0x1fa44f08` and its normal/diffuse inputs, using a GPU replay at main-scene draws 249–251 and 263–264. Only patch if a concrete discrepancy is found. Preserve v1.00 behavior and the known-good DOF/audio fixes. The older halo bypass diagnostics must **not** be merged into main.

A human-visible PVRTC block-endpoint preview was used only to identify the outfit material; it is not a faithful shader render or a GPU replay. No new renderer fix or gameplay validation is claimed.
