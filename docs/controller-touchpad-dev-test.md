# Controller touchpad development test plan

Branch: `feature/controller-touchpad-controls` (keep `main` unchanged).

## New settings

In the in-game **Controls** tab (also available in the Controls menu):

- **Controller touchpad target**: Front or Rear. This fork defaults to **Rear**.
- **Touchpad aim and click**: On or Off. This fork defaults to **On**.

The shoulder modifier that formerly selected the rear panel now selects the opposite panel from the configured default. It is the rear cursor shoulder (R1 with the standard shoulder setting, R2 when swapped).

## Expected behavior with aim and click On

1. Rest a finger on the DS4/DualSense touchpad, move it, and verify the crosshair follows. Vita touch contacts should remain absent until clicked or tapped.
2. Physically click while a finger remains on the pad. A Vita touch should start at the current crosshair position. Hold and move to drag; release the click to lift.
3. Quickly tap the touchpad without physically clicking (within 250 ms and without moving more than 55 Vita-panel units). A brief Vita touch should register. Moving the finger, or holding it longer, should *not* synthesize a tap when lifted.
4. Without the shoulder modifier, the controller touchpad should target the rear Vita panel. Hold the modifier **before** placing the finger to target the front Vita panel instead.
5. Confirm that direct Astra 2 screen touches still reach the Vita front panel when streamed as host touchscreen events. Nativ itself cannot guarantee a streaming client forwards direct touchscreen events.
6. Turn **Touchpad aim and click** Off to restore direct contact on finger down/move/up. Change the target to Front to restore the original front-first mapping.
7. Verify normal buttons and gyro still function. Disconnect the controller during a click and confirm no Vita touch remains stuck.

## Streaming-specific caveat

Gamepad finger tracking and the **physical touchpad button** are separate SDL inputs. Streaming may forward finger position but not the physical click. If aim works but clicking does not register, check whether Windows/SDL receives the touchpad button event before changing Nativ's contact logic.

## Build and verification status

Source changes have been committed on the development branch, but no Windows build, automated test run, or live controller/streaming test has been performed. Nativ's runtime is assembled into game-specific builds; use the project's documented build procedure for a supported title before replacing a working installation.

## Follow-up: streamed touchscreen taps and shoulder cursor

- **Astra 2 Multi-touch mode:** a very short SDL screen-finger press and release may arrive between game touch samples. The input layer now retains a release until its first game contact read, without extending ordinary touches that the game has already observed. Confirm short and long taps both work; test repeated rapid taps, drags, and two-finger touches.
- **R1 cursor/panel consistency:** the gamepad touchpad now targets the same Vita panel shown by the active shoulder cursor (blue/front or orange/rear) when the finger first lands. With no shoulder held, the configured touchpad default still applies. Verify with R1 held **before** finger-down; releasing or changing shoulders mid-touch does not transfer an existing contact.
- These are candidate source fixes only. **No Windows build or on-device verification has occurred.**

## Streaming performance trace (opt-in, diagnostic only)

The window present loop supports `RECOMP_STREAM_TRACE=1` and logs a once-per-second
`stream trace:` line showing the window loop's command-buffer acquire, previous
frame fence wait, renderer-lock acquisition, GPU sweep, swapchain acquisition,
and command-buffer submission timings (per-frame averages). It changes neither
the locking behavior nor the Vulkan present mode.

Use these existing diagnostic settings alongside it:
- `RECOMP_WAIT_STATS=10` — report renderer-lock waits/hold times and per-thread
  CPU / kernel waits every 10 game presents (more frequent under severe slowdown).
- `RECOMP_METRICS=1` — per-second game and window metrics.
- `RECOMP_HITCH_LOG=100` — frame hitches over 100 ms.

Run the updated dev build helper to download the latest `runtime/ui/window.c`
and rebuild `PCSA00029`. Set all four environment variables in PowerShell,
then launch `Project Nativ.exe` **from that same PowerShell process** so the
game inherits them. Record a local segment, start the Astra 2 stream, then
disconnect and record recovery. Retrieve the new `session.log` and compare
the `stream trace:`, `waits:`, and `metrics:` lines across segments.

Important: this trace currently measures window-thread SDL calls and waits.
The existing waitstats profiler measures the renderer mutex. It does **not**
separately time each renderer-side Vulkan submission or every SDL fence helper.
If those need finer tracing, add a subsequent targeted diagnostic based on the
first results.

The changes were reviewed by source inspection, but Windows compilation and
streaming execution have not yet been validated.

## Opt-in 60 FPS window presentation cap test

The development branch now supports `RECOMP_WINDOW_FPS_CAP=60` in
`runtime/ui/window.c`. This caps only the SDL window present loop; it does not
alter the game's frame-rate setting, GPU locks, Vulkan present mode, or the
controller/touchpad changes. It is **off by default** and is intended to test
whether the 120 Hz presentation loop's GPU submissions starve the game renderer
when the streaming host is active.

Rebuild Uncharted using `dev/Invoke-NativTouchpadTestBuild.ps1` so the new
source is compiled into its `game_host.exe`. Close Nativ/Uncharted before
rebuilding. For a diagnostic run, start the game from a PowerShell process that
sets:

```powershell
$env:RECOMP_WINDOW_FPS_CAP = '60'
$env:RECOMP_STREAM_TRACE = '1'
$env:RECOMP_WAIT_STATS = '10'
$env:RECOMP_METRICS = '1'
$env:RECOMP_HITCH_LOG = '100'
```

Look for `window: diagnostic FPS cap 60` in the new session log to verify
the variable reached the game. Compare local / streamed / post-stream FPS
and `stream trace:` rows. The window loop should report approximately 60 FPS
locally with the cap enabled; if the game still falls to 5 FPS, this cap did
not resolve the GPU-lock starvation hypothesis.

Rollback: exit Nativ, remove `RECOMP_WINDOW_FPS_CAP` from the launching
PowerShell environment (or use a new PowerShell process), and relaunch. The
cap itself does not persist. The built binary retains dormant code but
normal timing behavior when the variable is unset. Backup the executable
when running the build helper.

Only source review has been performed; Windows compilation, game execution,
and streamed performance validation are pending.

## Experimental frame-aware presentation (2026-11-11)

Opt-in with `RECOMP_WINDOW_FRAME_AWARE=1` and **unset**
`RECOMP_WINDOW_FPS_CAP`. Applies to SDL self-paced present modes
(Mailbox or Immediate), without changing synchronization or the swapchain
mode. The window loop submits when the game publishes a new image; if the
game is idle/paused, it continues SDL event polling and provides an
approximately 30 Hz UI refresh (menus, toasts, touch overlays).

This is a test of redundant window submissions and renderer-lock
contention, not a proven permanent fix. If an explicit
`RECOMP_WINDOW_FPS_CAP` is set, that cap takes precedence. If the
experimental variable is absent, the previous pacing remains unchanged.

### Rebuild and A/B verification

Close the game, run `dev/Invoke-NativTouchpadTestBuild.ps1` from the
installed player release as documented above, and use a newly built
`game_host.exe` (the script backs up the previous binary and source).

Start the launcher from the same PowerShell session:

```powershell
Remove-Item Env:RECOMP_WINDOW_FPS_CAP -ErrorAction SilentlyContinue
$env:RECOMP_WINDOW_FRAME_AWARE = '1'
$env:RECOMP_STREAM_TRACE = '1'
$env:RECOMP_WAIT_STATS = '10'
$env:RECOMP_METRICS = '1'
$env:RECOMP_HITCH_LOG = '100'
& 'C:\Installed Games\ProjectNativ-v0.1.5-windows\Project Nativ.exe'
```

Verify the session log reports
`window: experimental frame-aware presentation (30 Hz idle refresh)`.
Compare 15 seconds local, 15 seconds streaming to Astra 2, 15 seconds
local again. Include menu open, menu animations, overlay/toast/cursor,
touch input, and pause/resume in the visual check. Then submit
`session.log` for review; report whether the streamed picture actually
looks smooth. The logger measures window FPS and renderer-lock timing.

### Rollback

Close Nativ. Clear `RECOMP_WINDOW_FRAME_AWARE`; restore
`RECOMP_WINDOW_FPS_CAP=60` and launch through the same PowerShell
session. Do not disable `RECOMP_WINDOW_LOCK`. This requires no rebuild.
A build failure should restore the backup via the helper.

Code was reviewed by inspection; Windows compilation and on-device
validation have **not** yet occurred.

## Persistent frame-aware presentation and shoulder-cursor cleanup

Rebuild with `dev/Invoke-NativTouchpadTestBuild.ps1` to incorporate the
updated `runtime/ui/window.c` and `runtime/ui/overlay.cpp`.

Frame-aware presentation is now **enabled by default** in self-paced SDL
GPU modes (Vulkan Mailbox/Immediate). It no longer requires a PowerShell
environment variable. During gameplay, open **F10 > Performance >
Frame-aware presentation** to disable or re-enable it; the selection is
saved using `window_frame_aware` in Nativ's settings. To verify, enable
`RECOMP_STREAM_TRACE=1` and compare game FPS versus window FPS.

Diagnostic environment overrides remain available:
- `RECOMP_WINDOW_FRAME_AWARE=0` forces the old self-paced behavior.
- `RECOMP_WINDOW_FRAME_AWARE=1` forces frame-aware mode.
- `RECOMP_WINDOW_FPS_CAP=60` takes precedence over frame-aware pacing.

The bumper-held touch cursor no longer appears at the center merely
because L1/R1 is held. It appears after a stick is moved, and is hidden
while the DS4 touchpad is actively tracking a finger; the touchpad's
own finger marker remains visible. This only changes overlay marker
rendering, not game touch contacts or the existing tap behavior.

The launcher warning `Project Nativ is missing 60 of its files` is a
separate package-integrity complaint. The development build helper only
backs up and replaces two runtime source files and the generated
`game_host.exe`; it does not remove bundled Python files. If the
warning persists, inspect the missing Python path and compare a newly
extracted **same-version** release in a separate folder before merging
or replacing any files. Preserve the installed runtime, backups and
generated game folders. Do not delete the working game executable.

Windows compilation, launcher file-integrity recovery and on-device
touch/streaming verification are pending.

## Launcher integrity warning for development builds

The Windows release records file sizes in `.nativ-files`. Previously the launcher
reported both missing files and size-changed files as "missing", and it checked
Python `.pyc` bytecode caches that can be regenerated with different sizes.

On `feature/controller-touchpad-controls`:
- `launcher/hub.cpp` ignores `.pyc` entries, including those in older manifests,
  and displays separate counts for missing/unreadable and changed-size files.
- `dev/release.sh` no longer writes generated `.pyc` files into new release
  manifests. Other Python and runtime dependencies are still checked.
- `dev/Invoke-NativTouchpadTestBuild.ps1` backs up `.nativ-files` and updates
  only `runtime/ui/window.c` and `runtime/ui/overlay.cpp` size entries after
  a successful game rebuild. On build/setup failure, the original manifest
  is restored with the source files and game executable.

These changes do not patch an already installed launcher executable. The
launcher must itself be rebuilt to gain the new warning and cache handling.
The build helper modifies the installed manifest only when run again; it
does not require a launcher rebuild. Existing, manually repaired installations
do not need additional changes merely to remove the old warning.

Verification still required: compile the updated launcher on the target
toolchain, perform a successful and failing Windows development rebuild, and
check the alert against a deliberately missing non-cache dependency.

## Build and install a Windows launcher without a local Linux/macOS environment

The workflow `.github/workflows/build-windows-launcher.yml` uses a GitHub-hosted
`ubuntu-22.04` runner to cross-compile the standalone Windows launcher.
It downloads the version- and SHA-256-pinned LLVM-MinGW and SDL3 packages
already specified in `runtime/platform/win/setup-toolchain.sh`; the launcher
does **not** require FFmpeg, zlib, or a full game-runtime rebuild.

The first build is triggered by the workflow's initial commit to
`feature/controller-touchpad-controls`. Subsequent builds can be rerun via
GitHub Actions, or triggered using `workflow_dispatch` once the workflow is
registered on the repository default branch. GitHub typically requires a
workflow definition to exist on the default branch to expose manual Run
workflow controls. Do not merge this experimental branch simply to enable
that control.

In GitHub, open **Actions**, find **Build Windows Nativ Launcher**, select
a successful run, and download the `nativ-windows-launcher-<run number>`
artifact. Extract the artifact to a dedicated folder on the Windows gaming PC.

The artifact contains `Project Nativ.exe`, `SDL3.dll`,
`SHA256SUMS.txt`, and `BUILD-INFO.txt`. It is **not a complete installation**.
For the current v0.1.5 installation, keep the existing SDL3.dll.

Close Nativ, then in Windows PowerShell 5.1 or PowerShell 7:

```powershell
$scriptPath = Join-Path $env:TEMP 'Install-NativLauncherBuild.ps1'
Invoke-WebRequest 'https://raw.githubusercontent.com/jvanderv42/nativ/feature/controller-touchpad-controls/dev/Install-NativLauncherBuild.ps1' -OutFile $scriptPath
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -artifactFolder 'C:\Temp\nativ-windows-launcher-1' -installFolder 'C:\Installed Games\ProjectNativ-v0.1.5-windows'
```

Replace the example `-artifactFolder` with the actual extracted artifact
location. The installer verifies the launcher against SHA256SUMS, backs up the
existing launcher into `launcherBackup-YYYYMMDD-HHMMSS`, and replaces **only**
`Project Nativ.exe`. It does not alter game executables, the integrity
manifest, source files, or SDL3.dll. Restore the original executable from
that backup if the new launcher fails to start or has regressions.

The updated integrity checker distinguishes missing files from changed-size
files; it ignores `.pyc` entries in old manifests. The latest helper
`dev/Invoke-NativTouchpadTestBuild.ps1` independently updates the manifest
for intentional source changes after successful game rebuilds.

Validation: The workflow has been authored, but a successful GitHub Actions
run and an actual Windows launcher installation have not yet been verified.
