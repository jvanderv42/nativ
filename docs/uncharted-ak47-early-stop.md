# Uncharted: Golden Abyss — gunfire loop whose stop comes too early

**Status:** a per-game setting, `uc_fire_loop_fix`, on by default (F10 → Game → Gunfire sound fix, or the Game menu).
`RECOMP_UC_FIRE_LOOP_FIX=0|1` overrides it for the process. The trace is separate: `RECOMP_UC_SND_TRACE=1`.
Uncharted only: the code is in `packs/PCSA00029/hooks.c` and is compiled into that game.

## Result

Tested on Windows with the AK-47, 2026-11-16, builds from `nativ-llm-lab`:

| Run | Frame rate | Fix | Same-frame stops | What followed |
|---|---|---|---|---|
| baseline | 30 | off | 1 | value 127 counted down to 0: 127 shots, 508 voices, released after 16.1 s |
| fix 1 | 30 | on | 0 | nothing to correct; no retry |
| fix 2 | 30 | on | 1 | one retry; 4 voices (one shot); released after 1.5 s |
| fix 3 | 120 | on | 1 | script started 12-21 ms after the start; one retry then; 4 voices; released after 1.5 s |

About 75 other fire loops in the fix runs stopped normally with no retry and no `stop-lost`. Not tested: other automatic
weapons, weapon switching, reloading. One shot of the cancelled burst still plays: the script's first shot is started in
the tick that sets the count.

## What is known and what is not

Known, from the trace of 2026-11-15 (`ak47SoundBug-20261115-7.log`):

- The game started fire loop handle `0x850d002c` at frame 4637 (t = 118.419 s), asked for its stop in the same frame,
  and sent the stop 3 ms later. It is the last fire loop of the log.
- The 20 other fire loops of that log were stopped 1 to 20 frames after their start (two of them at 1 frame).

Known, from the game's code:

- A looping gun sound is not stopped through Scream's stop call. The game sets "stop requested" on its sound record,
  and its next sound-manager update writes 0 to one control value of the sound (Scream script register 3). The sound's
  script is what reads that value.
- A new sound's four control values start at 0 (`fn_815a3c38`), and no game code writes anything but 0 to register 3.

Known, from the sound banks in the frame captures (grains decoded against the engine's own handlers, table at
`0x81903644`): a looping gun sound's script is

1. set register 3 to 127 (grain 30, bytes `03 7f`; other weapons use 3 or 1),
2. loop: the shot's tones, a wait of about 28 ticks,
3. register 3 -= 1 (grain 33),
4. if register 3 < 1, go to the end marker (grain 34, bytes `03 00 01`, then grain 36).

So the game's 0 ends the loop at the next pass (0 - 1 = -1), and a 0 written before step 1 is replaced by 127: 127
shots, which is what the stuck sound measured (about 127 shots, one per 116 ms).

Step 1 runs after the play call returns, on the sound thread: every `start` line shows register 3 at 0, and it reads
127 between 2 and 36 ms later.

The name `0xddd0d694` is not the AK-47: it is the fire event of every weapon, each in its own bank (`bank=` in the log).

## Terms

| Term | Where | Meaning |
|---|---|---|
| sound record | game, 0x90 bytes, 75 per manager | the game's own bookkeeping for one playing sound |
| sound handle | `record+0x74` | Scream's id for one playing instance; a new one for every start |
| handler | `0x81982400 + ((handle>>16)&0xff)*0x228` | Scream's state for that instance; its first word is the handle while the sound lives |
| `f8c` | `record+0x8c` | bit 0: Scream reports the sound as looping (`fn_815989de`), set when it starts. bit 1: "stop requested" |
| control value | handler byte `+0x167` | script register 3; the game's stop for a gun loop is writing 0 here |
| category | `record+0x48` | `0x1c`/`0x1d` are the two the game stops through the control value |

## What the code does

All in `packs/PCSA00029/hooks.c`; one more instruction hook in `pack.toml` (`0x8102e5e4:uc_snd_update`, the top of the
manager update `fn_8102e5d2`).

Every sound that starts with `f8c` bit 0 set and category `0x1c`/`0x1d` is followed from start to end. Per manager
update (once per game frame), for each followed sound:

1. If Scream's handler no longer carries the handle, the sound is over: log `ended`, forget it.
2. If the record no longer holds the handle, the sound is only watched from then on, never written to.
3. If the game's stop was sent and the control value is above 0 while the sound is alive: log `stop-lost` (once).
   Above 0, not non-zero: a stop that was taken leaves -1 while the last shot fades.
4. Only with the fix on, and only if the game's stop came within 100 ms of the start: set
   `record+0x8c` bit 1 again. The game's update then sends its own stop again in that same update. At most 2 times per
   sound; one is expected to be enough.

The only write is that one bit, on a record that still holds the same handle, still has bit 0 and the category.

- **Retry trigger is a state, not a time.** A retry happens when the control value is seen above 0 after a stop was
  sent: the script's count is running although the game asked for the stop. No retry happens while the value is still
  0, so nothing is written before the script has started.
- **The game does the same itself:** when a sound's owner is gone, its manager update sets "stop requested" again every
  frame until the sound ends (`0x8102e932`). The bit is read only there and in the parameter builder.
- **100 ms** only decides which stops count as "shortly after the start". It covers a stop in the same or the next
  frames at 30 fps (33 ms a frame) and at 120 fps (8 ms a frame). It is a first guess, not a measured requirement.
  A stop later than that is logged but never retried.
- **Already stopped:** the handler no longer carries the handle, so the sound is forgotten before any write.
- **A control value whose meaning changed:** cannot be ruled out without the script. The game itself writes 0 there at
  any moment after a stop request, so one more 0 after a stop request is a write the script already has to accept.
  The 2-retry cap bounds it, and `stop-lost` on a late (non-early) stop would show the value being reused.
- **30 vs 120 fps:** the check runs once per manager update; nothing depends on the frame rate.

## Log lines

`uc-fl:` lines, written with `RECOMP_UC_SND_TRACE=1`:

`start`, `stop-requested` (note `same-frame-as-start`), `stop-sent` (values shown are before the write),
`after-stop-sent` (first update after it: zero, below zero = stop taken, or above zero), `control-value-changed` (the
first change after the start, then every change after the stop: one per shot), `stop-lost`,
`retry`, `retry-limit`, `record-released`, `ended` (`after-the-original-stop` / `after-a-re-requested-stop` /
`no-stop-was-requested`).

Each has `t_ms`, `frame`, record, handle, name, bank, `since_start_ms`, `since_stop_ms`, `regs=` the four control
values and the handler's flag word (or `gone`), the record's current handle, `f8c`, state, the retry count, and
`tones=` / `tones_after_stop=`: voices this sound's own script has started (Scream's tone grain `fn_8159e546`; a child
sound's voices are not counted). If `tones` stays 0 while firing, that hook is not in the recompiled game.

**Limit:** the log shows the control value and whether the sound is alive. It does not show the script's own position,
so "the script initialised" is inferred from the control value changing, not observed directly.

## Test

Recompile Uncharted first (hooks are compiled into the game). With `RECOMP_UC_SND_TRACE=1`, fire from cover until the
magazine is empty, keep fire held, return to cover; then

```powershell
Select-String -Path .\session.log -Pattern 'same-frame-as-start|event=stop-lost|event=retry'
```

A corrected case reads `same-frame-as-start`, `stop-lost`, `retry`, then `ended` with `after-a-re-requested-stop`.
With the setting off the same case reads `stop-lost` and `ended` about 16 s later.
