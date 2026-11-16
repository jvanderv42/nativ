# Experimental Uncharted: Golden Abyss 1.03 port

**Status:** isolated experimental branch `feature/uncharted-103-puzzle-20261116` based on `main`. Do not merge until the 1.03 game has been recompiled and tested. No new public release.

## Reference

Ported from [frankyfife/nativ_ff](https://github.com/frankyfife/nativ_ff), with version-specific 1.03 addresses, a 1.03 executable SHA-256, and the original **Complete the open puzzle** action. Our fork's 1.00 enhancements, including the AK47 early-stop correction, remain intact.

## Version behavior

- **1.00:** Existing main-fork graphics/touch/120 FPS/audio fixes, plus puzzle completion and chapter unlock actions.
- **1.03:** Reference fork's function/instruction hook map, guest addresses, 1.03 seed, and libgxm wait safeguard. Only puzzle completion is wired into the Game menu; chapter unlock is intentionally excluded.
- The 1.00-specific gunfire early-stop hook addresses have **not** been mapped for 1.03. The 1.03 Game menu does not advertise this fix. Likewise, the menu-blur toggle is held back until 1.03 shaders are checked. Neither should be assumed fixed on 1.03.

## How to test

1. Keep the existing stable installation and compiled Uncharted 1.00 executable for rollback.
2. Install the **experimental branch's Windows distribution artifact** into a separate folder.
3. Provide your own properly decrypted 1.03 update/game files and recompile Uncharted under that installation. The expected 1.03 `uncharted.self.elf` SHA-256 in the reference pack is `661457de5a4192fad214fba8d9a3e627faeeed671502eacf0f702f00268ad33b`.
4. First test a clean load into the title menu, load a save and run gameplay at 30 FPS. Then verify 60 and 120 FPS, touchpad/touchscreen, cutscenes, reloading/death and presentation changes.
5. Open any supported puzzle. Use **F10 → Game → Complete the open puzzle → Do it**, **F3**, or **Back + R1**. The action requests the game's own `ForceComplete` on its game thread; verify that the puzzle completes and the story proceeds, rather than merely dismissing the UI.
6. Test puzzle cancellation with no puzzle open (should present a notification), and verify the control is not present in other games. The **Unlock every chapter** action is intentionally excluded.
7. Regression-test Uncharted 1.00 and Killzone before considering any merge.

### Native 1.03 shader support (Option B)

Use **unmodified version 1.03 shader bundles**. Do not copy 1.00 shader binaries into 1.03 `patch.bin`.

The reference fork's `dev/uc_shaders103.py` helper was a compatibility workaround: it constructed a modified copy of the 1.03 update, replacing `game/bspsh.bin` (fragment shaders) and `game/bsvsh.bin` (vertex shaders) with the original 1.00 bundles. It did not translate the new shaders or implement the blur correction on native 1.03 assets. That helper is removed from this experimental branch because this project is pursuing native 1.03 support.

Start by recompiling 1.03 with its original assets. Collect shader diagnostics/captures to identify the 1.03 title-menu and pause-menu composite programs and confirm their uniform layout. Adapt the narrowly scoped blur correction only after identifying the exact shaders. The 1.03 blur toggle remains unavailable until that validation passes. Document any software-shader fallback, attachment misalignment, or unexpected rendering separately.

### Evidence required before merging

- 1.03 import/version recognition and recompilation success.
- Gameplay, audio, loading, cutscenes, save/load and visual tests.
- The Complete the open puzzle action tested on a real 1.03 puzzle, including its F10 and controller shortcuts.
- 1.00 regression on touch, 120 FPS and existing gunfire fix.
- Any divergences from the reference fork documented with logs and exact commit/build.

**No in-game validation is implied by a green GitHub Actions Windows distribution build.** Such a build verifies packaging and generic runtime checks; the proprietary game must be supplied and recompiled separately.
