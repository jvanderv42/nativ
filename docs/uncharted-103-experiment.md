# Experimental Uncharted: Golden Abyss 1.03 port

**Status:** isolated experimental branch `feature/uncharted-103-puzzle-20261116` based on `main`. Do not merge until the 1.03 game has been recompiled and tested. No new public release.

## Reference

Ported from [frankyfife/nativ_ff](https://github.com/frankyfife/nativ_ff), with version-specific 1.03 addresses, a 1.03 executable SHA-256, and the original **Complete the open puzzle** action. Our fork's 1.00 enhancements, including the AK47 early-stop correction, remain intact.

## Version behavior

- **1.00:** Existing main-fork graphics/touch/120 FPS/audio fixes, plus puzzle completion. Chapter unlock is intentionally excluded.
- **1.03:** Reference fork's function/instruction hook map, guest addresses, 1.03 seed, and libgxm wait safeguard. Only puzzle completion is wired into the Game menu; chapter unlock is intentionally excluded.
- The seven Scream gunfire audio hooks have been mapped to 1.03 and exercised with `RECOMP_UC_SND_TRACE=1`. The 1.03 Game menu still does not advertise the fix until regression testing is complete; `RECOMP_UC_FIRE_LOOP_FIX=0|1` provides an explicit test override. Native 1.03 menu-blur composite shaders are identified, with the existing toggle enabled for experimental testing. Exact visual parity with 1.00 remains an acceptance criterion.

## How to test

1. Keep the existing stable installation and compiled Uncharted 1.00 executable for rollback.
2. Install the **experimental branch's Windows distribution artifact** into a separate folder.
3. Provide your own properly decrypted 1.03 update/game files and recompile Uncharted under that installation. The expected 1.03 `uncharted.self.elf` SHA-256 in the reference pack is `661457de5a4192fad214fba8d9a3e627faeeed671502eacf0f702f00268ad33b`.
4. First test a clean load into the title menu, load a save and run gameplay at 30 FPS. Then verify 60 and 120 FPS, touchpad/touchscreen, cutscenes, reloading/death and presentation changes.
5. Open any supported puzzle. Use **F10 → Game → Complete the open puzzle → Do it**, **F3**, or **Back + R1**. The action requests the game's own `ForceComplete` on its game thread; verify that the puzzle completes and the story proceeds, rather than merely dismissing the UI.
6. Test puzzle cancellation with no puzzle open (should present a notification), and verify the control is not present in other games. The **Unlock every chapter** action is intentionally excluded.
7. Regression-test Uncharted 1.00 and Killzone before considering any merge.

## Native shader translator investigation — November 16, 2026

The user's unmodified 1.03 game launches on the Vulkan GPU backend (RTX 5090), but several *native* 1.03 vertex programs fail SPIR-V translation with `LDST base register 1.6 isn't formed from an SA pointer`. Confirmed program addresses in sessions: `0x230a7b48`, `0x230a6b08`, `0x230d21c8`, `0x23091dc8`, `0x230907c8`. The renderer then falls back to software for affected draws, repeatedly downloading render targets; slow gameplay and poor graphics follow. This is not proof that all shader programs or the GPU backend are software-rendered.

### Targeted I32MAD repeat candidate — November 16, 2026

The second 1.03 test's `RECOMP_UC103_LDST_TRACE=1` log identifies the same missing SA-pointer provenance in all five unsupported vertex shaders (GXP hashes `0xcd4b5b2f`, `0xf0279875`, `0x6045cc65`, `0x2e9ab44f`, `0x3678c2f9`). Each repeatedly computes bone pointers using an `SMLSI`-configured two-repeat `I32MAD`; the `LDST` reads a later PA register (for example PA6) written by the second repeat. Previously `writes_word` recognized only the first PA destination and returned unknown provenance. A tightly scoped candidate recognizes **only** repeated `I32MAD` with a full-width SA addend, computing destination and SA register stepping from preceding `SMLSI`/`SMBO` state. Ordinary code paths and software fallback remain intact if provenance is still unknown.

**Not yet game-verified.** Test native unmodified 1.03 at 30 FPS and 1× render scale. Compare the ten original unsupported-program messages, `software path` counts, target downloads, visual correctness (especially skinned characters and their attachments), and frame pacing before and after. A successful translation is not sufficient by itself; GPU geometry must agree with the expected scene. Keep `RECOMP_UC103_LDST_TRACE=1` for this first validation, but remove `RECOMP_NGS_DEBUG=1` during graphics benchmarking because it generated about 47 MB of unbounded Scream voice parameter logs in the second test. The original graphics-focused recording did not include `uc-snd:`/`uc-fl:` events. Subsequent 1.03 audio tracing verified that the mapped hooks execute. In a correction-enabled session, one same-frame start/stop was followed by `stop-lost`, a single retry, and a control value returning to zero; the user did not hear a stuck loop. Earlier fix-disabled videos reproduce the audible symptom, but their lower-level NGS logs cannot independently correlate the game-level stop to a specific voice.

The experimental branch adds **read-only shader translation diagnostics** behind `RECOMP_UC103_LDST_TRACE=1` in `runtime/gfx/usse_spirv.c`. This reports decoded instructions and marks the last writer of the LDST base register, capped at 32 failures. It does not fix or bypass the unsupported instruction. With the newest experimental distribution, capture a fresh session on native 1.03 shaders using that environment setting, entering gameplay where the failure occurs. Compare the `uc103 ldst:` output to `usse.c`'s CPU interpreter and develop a narrowly scoped SA-pointer origin rule only when the required provenance is verified. Validate with the already provided VFC captures and new test runs before accepting a translator change.

Maintain the proven 1.00 gameplay and AK47 behavior; do not merge to `main` until user approval. The 1.03 AK47 sound-control and native menu-blur shader mappings are implemented experimentally; both require further regression testing.

### Native 1.03 shader support (Option B)

Use **unmodified version 1.03 shader bundles**. Do not copy 1.00 shader binaries into 1.03 `patch.bin`.

The reference fork's `dev/uc_shaders103.py` helper was a compatibility workaround: it constructed a modified copy of the 1.03 update, replacing `game/bspsh.bin` (fragment shaders) and `game/bsvsh.bin` (vertex shaders) with the original 1.00 bundles. It did not translate the new shaders or implement the blur correction on native 1.03 assets. That helper is removed from this experimental branch because this project is pursuing native 1.03 support.

Start by recompiling 1.03 with its original assets. Collect shader diagnostics/captures to identify the 1.03 title-menu and pause-menu composite programs and confirm their uniform layout. Adapt the narrowly scoped blur correction only after identifying the exact shaders. The 1.03 blur toggle is now exposed for experimental testing, pending in-game visual acceptance. Document any software-shader fallback, attachment misalignment, or unexpected rendering separately.

## Native 1.03 menu/pause DOF correction candidate — November 16, 2026

The three original-asset VFC files have been examined directly: `frame_2925.vfc` (277 draws), `frame_3717.vfc` (411 draws), and `frame_4549.vfc` (562 draws). Their complete draw records, native fragment-program binaries, and default-uniform buffers establish:

| 1.03 composite | Fragment program | GXP content hash | Draw | Captured g_vDofParams |
|---|---|---|---|---|
| Title menu | `0x1fa2a4c8` | `0x7de431e4` | 267 in frame 2925 | `(1.0, 10.139, 0.1, 10.0)` |
| Paused cinematic | `0x1fa2c288` | `0x8b9e8245` | 403 in frame 3717 | `(1.0, 24.903, 0.1, 10.0003)` |
| Paused gameplay | `0x1fa2c288` | `0x8b9e8245` | 551 in frame 4549 | `(1.0, 2.7, 0.1, 10.0)` |

Both versions place `g_vDofParams` at default-uniform floats 16–19, and both 1.03 composites consume the sharp full-resolution scene and 192×96 blurred scene. The sampled focus parameters reproduce the narrow in-focus band for which the **working 1.00 correction** already adjusts only the draw's temporary SA register copy.

The experimental change adds the two **native 1.03 hashes only** to the renderer's existing four-condition menu/pause correction; the algorithm, threshold gate, saved setting, default On, environment override, and 1.00 hashes stay unchanged. The existing `F10 → Game → Menu blur correction` toggle is enabled for 1.03. No shader bundle is replaced.

**Acceptance still requires in-game A/B validation** at title and pause screens: verify that Off exhibits the sharp sliver, On removes it, the setting persists, and gameplay depth of field stays unchanged. Check the `gpu: RECOMP_UC_MENU_BLUR: Uncharted menu in-focus slab removed` log entry when On. The hash+uniform analysis does not independently prove that a new 1.03 shader executes the same blend math; if the test does not behave as expected, investigate the original 1.03 shader instruction sequence before modifying parameters further.

### Evidence required before merging

- 1.03 import/version recognition and recompilation success.
- Gameplay, audio, loading, cutscenes, save/load and visual tests.
- The Complete the open puzzle action tested on a real 1.03 puzzle, including its F10 and controller shortcuts.
- 1.00 regression on touch, 120 FPS and existing gunfire fix.
- Any divergences from the reference fork documented with logs and exact commit/build.

**No in-game validation is implied by a green GitHub Actions Windows distribution build.** Such a build verifies packaging and generic runtime checks; the proprietary game must be supplied and recompiled separately.

## Evidence checkpoint — November 17, 2026

- Distribution 58 graphics testing identified frame-time spikes and repeated render-target downloads; this does not by itself prove that the five original LDST shaders still fail translation. Separate the translator's unsupported-program messages from other software fallback causes.
- The repeated-`I32MAD` SA-pointer provenance candidate is already in `runtime/gfx/usse_spirv.c`. A bounded `uc103 ldst: repeated-origin` trace now reports when that rule matches a load. The trace is diagnostic only; it does not change shader output or rendering behavior. Keep `RECOMP_UC103_LDST_TRACE=1` for the first new build validation, then disable it for performance comparisons.
- Test native 1.03 at 30 FPS/1× first. Compare shader failure counts, software fallback causes, target downloads, geometry correctness, and frame times against Distribution 58. The candidate cannot be accepted from compilation success alone.
- The fix-enabled AK47 trace shows a recovered lost-stop state. Retain the correction experimentally, avoid changing it without new contradictory evidence, and test ordinary weapon behavior and audio timing separately.
- Preserve the v1.00 DOF algorithm. Compare the 1.03 title, gameplay pause, and cinematic pause captures visually with the accepted v1.00 output before adjusting parameters.
- No changes to `main` or public release are authorized by this checkpoint.
