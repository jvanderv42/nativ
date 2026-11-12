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
