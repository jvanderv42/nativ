# Experimental candidate: Vita memory, shader subroutines and 16:9/16:10 presets

## Baseline and scope
This branch starts from the accepted Distribution 27 experimental branch, which the user tested successfully. The released Distribution 20 and its original source remain unchanged. This is **not yet a published release**.

## Changes

### Aspect-ratio presets
- The in-game F10 → Display → Widescreen selector now offers **Off, 16:9, 16:10, 21:9, 32:9 and Window**.
- Explicit 16:9 and 16:10 modes change the camera/output aspect ratio, not just display stretching. The shared aspect-register hook and Uncharted camera projection now apply factors below 1.0 instead of silently ignoring them; this is essential for a correct 16:10 picture.
- Note that the original Vita screen is 960×544 (30:17), close to but not exactly 16:9. Off retains native.

### Guest memory management
- Adopted alignment-aware reuse of freed memory holes from Luufen's memory work. Supports page alignment, CDRAM and physically-contiguous types, and optional larger requested alignments.
- Preserved existing allocation/free behavior and UID tracking, instead of replacing the entire allocator.
- Added a user-memory accounting guard based on Luufen's memory-budget helper. It is **disabled by default** to avoid imposing an unvalidated per-game limit on existing Uncharted/Killzone workflows.
- For deliberate compatibility experiments only, set the Windows process environment variable `RECOMP_VITA_USER_MEMORY_MB` to an explicit memory limit in megabytes, e.g. `256`. Close and restart the game to change it. Do not permanently enable a limit without game-specific validation.
- This is not full automatic Vita SFO ATTRIBUTE2 budget emulation; importing that would require more system metadata handling and separate testing.

### Shader-subroutine support
- Adapted the USSE shader-call inliner from Luufen commit `b73f8ddd9` with a safe fallback when an unsupported branch/call shape is encountered.
- Goal: handle programs using initial subroutines and repeated calls that would otherwise fall back to CPU processing.
- Verify synthetic shader-control-flow tests and real rendering in Uncharted and Killzone. This does not guarantee a general graphics or FPS improvement.

### Previous candidate features retained
- Uncharted UC-LAMP render-target scaling.
- Vblank-aligned Vita touch sampling (rollback: `RECOMP_TOUCH_EDGE_SAMPLING=0`).
- Window aspect 16:10 support (rollback: `RECOMP_ALLOW_NARROW_ASPECT=0`).
- Distribution 20's tested DS4 input behavior and 120 FPS changes.

## Acceptance tests
1. CI: memory-budget and aligned-hole tests, USSE branch/control-flow tests, aspect and touch tests, full Windows cross-build and packaging.
2. Recompile Uncharted using a separately extracted candidate distribution; retain the previous installed candidate for rollback.
3. F10 Widescreen: Off, 16:9, 16:10, Window, 21:9, 32:9; check camera geometry and HUD/menu/touch alignment, especially 16:10 on Astra 2.
4. DS4 rear/front touch with L1/R1, click-hold-drag-release, quick taps, and Vita system menu navigation.
5. Compare Uncharted glow, cutscenes, and 60/120 FPS local and Nightjar streamed frame pacing.
6. Killzone: verify scene loading, shader visuals (including UI), transitions and memory-heavy scenes.
7. Long-session memory: verify several level transitions without allocator exhaustion or graphics corruption.

Never promote automatically from a successful build. Hands-on tests determine acceptance.
