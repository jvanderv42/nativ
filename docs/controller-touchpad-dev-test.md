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
