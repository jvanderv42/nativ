# 120 FPS stability and performance validation

## Scope and source baseline

This branch is derived from `experimental/120fps` commit
`f2a9b6fd2d887e9665aa2f255d802fed9ff4ca30`.
The verified Windows distribution #6 and `release/v0.1.5-custom.1`
remain unchanged. Recompile each game using a new distribution from this
branch; do not overwrite known-good game executables.

## Changes to verify

- Settings files: failed temporary-file creation/write/rename keeps changes
  pending for a later retry; oversized merges refuse to overwrite existing files.
- Fixed deterministic clock: switching the virtual vblank grid from 60 to
  120 Hz and back preserves accumulated elapsed time.
- Frame-rate state: display-rate read and capture override avoid unsynchronized
  access across threads.
- Game-thread creation: reports failures rather than leaving an idle window;
  a rejected custom stack size falls back to the default.
- Numeric settings: a single mutex acquisition instead of two per lookup.
- Frame-aware presentation: interactive F10/save dialogs target an idle
  refresh near 60 Hz; fully idle gameplay retains near-30 Hz refresh.

## Automated checks

The experimental Windows distribution workflow runs:
1. Existing 30/60/120 frame-rate helper tests.
2. Frame-clock continuity and repeated 60/120 transition tests.
3. Settings-save retry test with an initially missing destination directory.
4. Windows distribution assembly and release manifest/integrity checks.

These tests do **not** validate full gameplay, GPU latency, or online behavior.

## Manual regression matrix

Test both US packs: Uncharted PCSA00029 and Killzone PCSA00107. Preserve the
original compiled executables before each rebuild.

1. Launch at 60 FPS; test menu, controllers, touchscreen, gyro, and saves.
2. Select 120 FPS from F10; confirm F1 reports new frames and normal game speed.
3. Switch 120 > 30 > 60 > 120; include a pause and resume between transitions.
4. Leave the F10 menu open for a minute, interact with tabs, then resume.
5. Test a cutscene, physics/movement, firing/reload and a level transition.
6. Repeat local play before testing Nightjar on a 120 Hz client.
7. Compare with the same save/scene/graphics settings on distribution #6.
8. Verify settings persist after restart. A failed save should be reported in
   stderr rather than silently marked successful.

## Performance capture

Before benchmarking, disable unrelated downloads and ensure the game and
Windows power settings are identical across runs. Use a real 120 Hz local display.

Windows PowerShell, in the same terminal used to start the game executable:

```powershell
# Diagnostics only; no persistent system configuration changes.
$env:RECOMP_STREAM_TRACE = '1'
$env:RECOMP_HITCH_LOG = '12'
$env:RECOMP_GPU_STATS = '1'

# Start the *recompiled* game using the normal launcher workflow.
# Preserve stdout/stderr logs for each 60 FPS and 120 FPS run.
```

The 12 ms hitch threshold is useful to isolate frames over the 8.33 ms
120-FPS budget without generating a trace for every frame. For more focused
120-FPS analysis, repeat with `RECOMP_HITCH_LOG=9`. GPU statistics and
hitch accounting share some counters: run a separate pass with only one
enabled if the reports appear inconsistent.

Capture: FPS, average frame interval, 1% low, lock wait, command-buffer
acquisition, swapchain wait, fence wait, shader/pipeline compilation and
visible frame pacing. Record whether a hitch coincides with first-use shaders
or regular sustained rendering. Do not disable GPU synchronization simply
because it appears in a profile: several locks and fences protect previously
observed SDL/Vulkan races.

To remove diagnostic environment variables from the current shell:

```powershell
Remove-Item Env:RECOMP_STREAM_TRACE, Env:RECOMP_HITCH_LOG, Env:RECOMP_GPU_STATS -ErrorAction SilentlyContinue
```

## Decision criteria

Accept changes only if automated checks pass and 30/60 FPS gameplay does not
regress. A performance change must show an improvement in repeated comparable
traces, not just a higher instantaneous FPS reading. Do not infer stable
120-FPS compatibility from a short session.

## Rollback

Switch back to `experimental/120fps` or install Windows distribution #6
in a separate directory, and restore its original game executables.
Never merge this improvement branch into the verified release as part of
performance experimentation.

## Texture-upload burst experiment (post-distribution #13)

The next performance candidate retains all existing upload ordering, GPU
fences and synchronization. It changes only **when** completed staging-ring
fences are polled, not when overlapping memory may be reused: overlap always
waits for its outstanding fence. It sweeps normally every eight allocations,
or aggressively when the in-flight list approaches capacity.

`RECOMP_GPU_TRING_SWEEP_EVERY=1` restores the original query-per-upload
behavior in the **same binary**. Compare this against the default (8) at
the same save location. Look for changes in peak frame time during texture
bursts and any GPU-driver errors. If the result is not repeatably improved,
restore 1 or revert the commit.

Detailed per-texture diagnostics normally write only when an individual
upload exceeds 8 ms (previously 1 ms) to avoid extra synchronous stderr
writes during 60-texture bursts. The frame hitch summary still reports
**all** uploads. For fine-grained old-style logs use
`RECOMP_GPU_TEXTURE_TRACE_MS=1`.

The hitch log now subdivides upload time into `decode`, `stage`
(transfer buffer/map), and `submit` (command-buffer work). Those
subtimings are nested inside the total upload time and should not be
added to it. Test with `RECOMP_HITCH_LOG=18`,
`RECOMP_METRICS=1`, and `RECOMP_STREAM_TRACE=1`.
Ensure `RECOMP_GPU_STATS` is **unset** for a clean per-hitch report.

An unknown 1-second event in the previous log is **not yet explained**;
no speculative GPU locking or resource-lifetime changes have been made.

### A/B launch variables (PowerShell)

```powershell
# A: updated fence polling (default).
Remove-Item Env:RECOMP_GPU_TRING_SWEEP_EVERY -ErrorAction SilentlyContinue

# B: original upload-fence polling, without changing executables.
$env:RECOMP_GPU_TRING_SWEEP_EVERY = '1'

# Optional: original verbose texture event threshold.
$env:RECOMP_GPU_TEXTURE_TRACE_MS = '1'
```

These environment variables must be set before launching Project Nativ.
Close the launcher and game fully between A and B runs.

## Touchpad cursor cadence diagnostic (post-distribution #16)

`RECOMP_TOUCH_TRACE=1` enables **diagnostic-only** timing in the window/input
thread. It does not change controller mappings, touch coordinates, gesture
handling, gyro, or GPU pacing. While a shoulder cursor is active or a
DualSense touchpad finger is down, the session log prints one `touch trace:`
summary per second and a final summary on release:

- `loop`: window input-loop iterations/s and worst loop gap.
- `pad ev`, `motion`, `changed`: SDL touchpad input event frequency and
  finger-0 coordinate changes; `gap` is the longest time between delivered
  touchpad events.
- `stick ev`, `cursor changes`: stick axis event frequency and visible
  shoulder cursor coordinate changes.
- `overlay frames`, `gap`: how often the touch overlay was drawn and its
  largest interval while input was active.

When a finger moves in large jumps but the game stays at 120 FPS:
- Low `pad motion` and high `pad gap`, with `overlay frames` near 120:
  investigate the Nightjar virtual controller, SDL delivery or event timing.
- Frequent `pad motion`, but few `changed`: investigate incoming positions
  and touch-coordinate processing.
- Frequent events and coordinate changes, but low `overlay frames` or a
  large overlay gap: investigate window pacing, GPU waits and overlay path.
- The shoulder-stick cursor uses `stick ev` and `cursor changes`, not
  `pad motion`; keep those distinct.

Use a continuous drag for 10-15 seconds at least once when input behaves
normally, and another during the intermittent choppy behavior. Don't use
F5 during the movement because diagnostic capture can itself stall the game.
Upload `session.log` afterward; the trace is opt-in and normally silent.

```powershell
$env:RECOMP_TOUCH_TRACE = "1"
$env:RECOMP_HITCH_LOG = "18"
$env:RECOMP_METRICS = "1"
$env:RECOMP_STREAM_TRACE = "1"
```

The window/input thread is the timing reference, so low pad event frequency
cannot on its own distinguish controller transport (Astra 2/Nightjar) from
SDL's incoming event queue. Direct-connected controller comparison is a
separate diagnostic step if required.
