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
