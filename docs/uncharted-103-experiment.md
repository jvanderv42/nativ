# Experimental Uncharted: Golden Abyss 1.03 port

**Status:** isolated experimental branch `feature/uncharted-103-puzzle-20261116` based on `main`. Do not merge until the 1.03 game has been recompiled and tested. No new public release.

## Reference

Ported from [frankyfife/nativ_ff](https://github.com/frankyfife/nativ_ff), with version-specific 1.03 addresses, a 1.03 executable SHA-256, and the original **Complete the open puzzle** action. Our fork's 1.00 enhancements, including the AK47 early-stop correction, remain intact.

## Version behavior

- **1.00:** Existing main-fork graphics/touch/120 FPS/audio fixes, plus puzzle completion and chapter unlock actions.
- **1.03:** Reference fork's function/instruction hook map, guest addresses, 1.03 seed, and libgxm wait safeguard. Puzzle completion and chapter unlock are wired into the in-game Game menu.
- The 1.00-specific gunfire early-stop hook addresses have **not** been mapped for 1.03. The 1.03 Game menu does not advertise this fix. Likewise, the menu-blur toggle is held back until 1.03 shaders are checked. Neither should be assumed fixed on 1.03.

## How to test

1. Keep the existing stable installation and compiled Uncharted 1.00 executable for rollback.
2. Install the **experimental branch's Windows distribution artifact** into a separate folder.
3. Provide your own properly decrypted 1.03 update/game files and recompile Uncharted under that installation. The expected 1.03 `uncharted.self.elf` SHA-256 in the reference pack is `661457de5a4192fad214fba8d9a3e627faeeed671502eacf0f702f00268ad33b`.
4. First test a clean load into the title menu, load a save and run gameplay at 30 FPS. Then verify 60 and 120 FPS, touchpad/touchscreen, cutscenes, reloading/death and presentation changes.
5. Open any supported puzzle. Use **F10 → Game → Complete the open puzzle → Do it**, **F3**, or **Back + R1**. The action requests the game's own `ForceComplete` on its game thread; verify that the puzzle completes and the story proceeds, rather than merely dismissing the UI.
6. Test puzzle cancellation with no puzzle open (should present a notification), and verify the control is not present in other games. Test the optional **Unlock every chapter** separately on a disposable save, because it modifies chapter-completion records.
7. Regression-test Uncharted 1.00 and Killzone before considering any merge.

### Shader-bundle compatibility

The reference port reports 1.03's updated shader bundles can cause software fallback and mispositioned skinned attachments. `dev/uc_shaders103.py` (imported unchanged from the reference fork) prepares an **output copy** of your own 1.03 `patch.bin` using the two shaders bundles from your own 1.00 `gamedata.bin`:

```powershell
python dev/uc_shaders103.py <path-to-1.00-gamedata.bin> <path-to-1.03-patch.bin> <output-patch.bin>
```

Back up both inputs. Do **not** overwrite the original update during initial testing. The script is a manual compatibility tool, not an automatic importer or proof that every scene renders correctly; compare with unmodified 1.03 shader assets first if diagnosing rendering differences. No game data is included in this repository.

### Evidence required before merging

- 1.03 import/version recognition and recompilation success.
- Gameplay, audio, loading, cutscenes, save/load and visual tests.
- The Complete the open puzzle action tested on a real 1.03 puzzle, including its F10 and controller shortcuts.
- 1.00 regression on touch, 120 FPS and existing gunfire fix.
- Any divergences from the reference fork documented with logs and exact commit/build.

**No in-game validation is implied by a green GitHub Actions Windows distribution build.** Such a build verifies packaging and generic runtime checks; the proprietary game must be supplied and recompiled separately.
