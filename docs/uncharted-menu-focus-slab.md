# Uncharted: Golden Abyss — menu in-focus slab (lab experiment 1)

**Status:** visually accepted by the user; integration branch adds a saved toggle (on by default). The Windows integration build and cross-game regression tests remain pending. Based on Distribution 35
(`experiment/memory-graphics-aspect-20261114`, `142107e`). Lives only in `nativ-llm-lab`.

## What was found

From the captures `frame_1954-1x.vfc` and `frame_2021-4x.vfc` (blurred title menu), using `usse_dis` and `usse_run`:

- Draw 260 builds the 180x102 blur buffer in one pass: nine bilinear taps of the 720x408 HDR scene within about two
  pixels of centre. It is essentially a 4:1 downsample; the softness comes from stretching it back up bilinearly.
- Draw 262 (fragment program `0x1fa2aa48`, GXP hash `0xb8a9cc91`) blends sharp and blurred scene by

  ```text
  blur = x * saturate((|W - y| - z) * w)        g_vDofParams = (x, y, z, w), W = unit 10's fourth channel
  ```

- In the title menu `g_vDofParams = (1.0, 10.139, 0.1, 10.0)`: everything is blurred except a slab about 0.2 units
  deep around distance 10.139, which stays fully sharp. It covers about 3% of the screen: a stair-shaped band across
  the stone steps, the palm trunk and the bottom-left foliage — where the jagged boundaries are seen.
- Where the scene is fully blurred, the 1x composite matches "tonemap of the bilinearly sampled blur buffer" to within
  0.4 of an 8-bit level: no translation fault was found in this draw.
- The blur buffer is 12–16% rougher at 2x/4x than at 1x (undersampled taps); a minor factor, not addressed here.

## Pause menus (captures `frame_5715.vfc`, `frame_9171.vfc`)

In game the composite is a second program, fragment `0x1fa2c8c8`, GXP hash `0xaecc460e`: one more sampler (unit 11,
bloom), the same blend, `g_vDofParams` at the same place. Paused, the game keeps the last focus distance and collapses
the range: `(1, 24.95, 0.1, 10)` in a paused cinematic (slab 1.2% of the screen, stray slivers), `(1, 2.7, 0.1, 10)`
paused in gameplay (5.6%: most of the player character, minus his backpack and one leg, and some foreground grass).
The first build matched only the title menu's hash, so the pause menus were unchanged; both hashes are matched now.

## The change

`RECOMP_UC_MENU_BLUR=1`, for those two GXP hashes only: when the in-focus range is thin (`0 <= z <= 0.25`, `w >= 4`, `x > 0`)
the focus distance in the draw's own register copy is moved out of the scene, so the whole scene takes the blur at the
game's strength `x`. Guest memory, the shader, gameplay DOF states (e.g. `(0.25, 2.75, 5.0, 0.143)`) and other games are
untouched. One comparison per draw of that program; no extra GPU work.

Checked offline with `usse_run`: with the override the program returns the blurred input for every W tried.

## Test

Same settings and menu state for both runs; restart between them. Judge on the PC display, not over the stream.

```powershell
# Original
Remove-Item Env:RECOMP_UC_MENU_BLUR -ErrorAction SilentlyContinue
& '.\Project Nativ.exe'

# Slab removed
$env:RECOMP_UC_MENU_BLUR = '1'
& '.\Project Nativ.exe'
```

Look for `gpu: RECOMP_UC_MENU_BLUR: Uncharted menu in-focus slab removed` in stderr.

**Accept** if the sharp sliver across the steps and foliage is gone in the title menu, with no change in gameplay.
**Check too:** both pause menus (the player character is now blurred with the rest of the paused scene) and a gameplay depth-of-field scene, which must not change.
**Not expected to change:** the soft blockiness of the blur itself — that is the next experiment.

**Rollback:** unset `RECOMP_UC_MENU_BLUR`.

## Integrated settings toggle

For Uncharted, use **F10 → Display → Menu blur correction** (also available under the top-edge **View** menu). The correction defaults to **On**, can be switched off without restarting, and saves to the game's own settings.ini as `uc_menu_blur = 0|1`. Other games do not display the control.

The existing `RECOMP_UC_MENU_BLUR=0|1` environment variable is retained as a diagnostic override. If set, it wins over the saved setting and disables the in-game control until the next launch without the override. The renderer reads the saved setting only for the two recognized Uncharted DOF programs.

Integration verification: build the distribution; start without the environment override; verify On default, Off/On visual change in title and pause menus, persistence after restarting, and normal gameplay DOF, controller input, and 120 FPS behavior. Confirm the toggle is absent in Killzone. No changes have been made to the virtual vblank, frame-aware pacing, or controller paths.
