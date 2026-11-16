<p align="center">
  <img src="assets/brand/banner.svg" alt="Project Nativ — PS Vita games recompiled for PC" width="720">
</p>

<h1 align="center">Project Nativ Custom</h1>
<p align="center"><strong>Play supported PS Vita games as native Windows applications, with improved controller touch input, experimental 120 FPS playback, and targeted Uncharted visual and audio corrections.</strong></p>
<p align="center">
  An unofficial Windows-focused fork of <a href="https://github.com/TheLostPantheon/nativ">Project Nativ</a>, developed and tested with Uncharted: Golden Abyss, Killzone: Mercenary, and DualShock 4 touch controls.
</p>
<p align="center">
  <a href="https://github.com/jvanderv42/nativ/releases"><img src="https://img.shields.io/badge/Download-Windows%20distribution-3cba91?style=for-the-badge&logo=windows&logoColor=white" alt="Download Windows distribution"></a>
  <a href="https://github.com/jvanderv42/nativ/releases"><img src="https://img.shields.io/badge/Latest%20release-View%20downloads-5969df?style=for-the-badge" alt="See releases"></a>
</p>
<p align="center">
  <a href="https://github.com/jvanderv42/nativ/releases"><img src="https://img.shields.io/github/downloads/jvanderv42/nativ/total?label=downloads" alt="Release downloads"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--2.0%2B-blue" alt="GPL-2.0 or later"></a>
  <a href="https://github.com/jvanderv42/nativ/actions"><img src="https://img.shields.io/badge/builds-GitHub%20Actions-2088ff" alt="GitHub Actions builds"></a>
</p>

> **The short version:** This unofficial Windows fork packages a complete Project Nativ environment and integrates improved PS Vita touch controls, frame-aware presentation, optional experimental 120 FPS gameplay, graphics and stability updates, and toggleable Uncharted menu/pause blur and gunfire sound corrections (enabled by default). Download the current release from **[Releases](https://github.com/jvanderv42/nativ/releases)**.

## Why this fork exists

[Project Nativ](https://github.com/TheLostPantheon/nativ) is a static-recompilation project that can rebuild supported PS Vita games into native desktop programs. That is a remarkable starting point, but playing those games on a PC—or streaming them to an Android handheld—introduces practical differences from the original Vita hardware.

Several practical problems motivated this fork:

1. **Touch controls:** Uncharted: Golden Abyss uses the Vita's front touchscreen and rear touch surface. A DualShock 4 touchpad is a natural substitute, but brief taps, drag gestures, modifier buttons, and occasional cursor stuttering made some interactions awkward.
2. **Streaming and frame pacing:** The Windows runtime could vary in presentation behavior with focus changes, the Windows taskbar, or an active streaming overlay. The goal was predictable gameplay and smoother presentation over Nightjar, including higher-refresh-rate experiments.
3. **Uncharted-specific issues:** Narrow in-focus bands appeared in title/pause blur, and an early audio stop could be overwritten by gunfire script initialization, leaving an automatic weapon firing audibly long after its magazine emptied.

Development and hands-on testing focused on a Windows gaming PC streaming to an **Astra 2 Android handheld** using [Nightjar Custom](https://github.com/jvanderv42/nightjar). The improvements are not limited in principle to that hardware, but other devices and configurations have not all been tested.

**This fork does not replace or claim to be the original Project Nativ.** It builds on the upstream project and maintains a downloadable custom Windows distribution for these specific improvements.

## What this edition adds

| Improvement | What it does |
| --- | --- |
| **DualShock 4 touchpad controls** | Uses the controller touchpad to emulate Vita touch interactions, including taps and drag gestures. |
| **Front/rear touch targeting** | Rear-touch behavior by default, with L1/R1 modifiers for changing the emulated touch target. |
| **Better tap and drag handling** | Improves detection of short taps and physical touchpad click-hold-drag-release sequences. |
| **Cleaner cursor behavior** | Reduces unwanted touch-cursor overlays during normal gameplay. |
| **Android handheld touchscreen input** | Improves recognition of short touches and longer presses when using the streamed handheld's screen. |
| **Frame-aware presentation** | Reduces unnecessary rendering/presentation work to support more consistent Windows and streamed gameplay. |
| **Optional 120 FPS mode** | Adds experimental 120 Hz timing and 30/60/120 FPS configuration options; results depend on the game and hardware. |
| **Uncharted menu blur correction** | Removes narrow sharp bands in title and pause-menu background blur, without changing gameplay depth of field; enabled by default, with a per-game On/Off toggle. |
| **Uncharted automatic gunfire fix** | Retries an early stop request if a looping weapon-sound script overwrites it; verified with the AK47 at 30 and 120 FPS. Enabled by default, with a per-game toggle and diagnostic override. |
| **Graphics and reliability updates** | Includes targeted render-target scaling, widescreen/visual settings, memory reuse and other stability improvements from the tested custom development branch. |
| **Complete Windows distribution** | Packages the launcher, runtime, Python environment, toolchain, and supporting files for Windows setup without building the entire development environment yourself. |

These are custom-fork changes or packaging improvements layered on top of Project Nativ's existing game recompilation and runtime technology. They do **not** mean every game supports every feature.

## Download and install

**Get the latest available Windows distribution: [Project Nativ Custom — Releases](https://github.com/jvanderv42/nativ/releases).** Each release identifies its source commit and verification status. The gunfire correction was tested at 30 and 120 FPS in experimental Distribution 11; the subsequently added in-game toggle and rearranged menus still require a separate in-game check.

1. Open **Releases**, select the latest stable custom release, and download the Windows distribution ZIP.
2. Extract the **entire archive** to its own directory; do not launch the executable from inside the ZIP.
3. Open the extracted `ProjectNativ` folder and run `Project Nativ.exe`.
4. Follow the launcher setup to provide your **own legally obtained game files and Sony PS Vita firmware**. This project does not supply them.
5. Build or recompile the supported game from the launcher. **An existing compiled game executable may not include the new runtime changes until you recompile it.**
6. Configure the desired frame-rate and input options, then play locally or stream from the Windows PC.

Keep a backup of any known-good distribution, game builds, and save data before switching versions. The published release ZIP, checksums, and build details are available on the [Releases page](https://github.com/jvanderv42/nativ/releases), not only as expiring GitHub Actions artifacts.

**Platform note:** The packaged *custom release* is for **Windows**. The original Project Nativ also has macOS and Linux support, but this fork does not advertise tested custom binaries for those platforms.

## Uncharted menu blur correction

In **Uncharted: Golden Abyss**, a game-specific correction smooths the title and pause-menu background blur by removing narrow in-focus bands. It does **not** replace normal gameplay depth of field.

- **Default:** On, including the first launch with no saved preference.
- **In-game setting:** Press **F10 → Game → Menu blur correction**, or use the top-edge **Game** menu.
- **Saved preference:** On/Off changes are applied to subsequent relevant draws and stored in Uncharted's own `settings.ini`. The setting does not appear in other games.
- **Diagnostic override:** `RECOMP_UC_MENU_BLUR=0` disables the correction and `RECOMP_UC_MENU_BLUR=1` forces it on for the process. When an override is set, the corresponding in-game control is unavailable until the game is restarted without it.

The correction was evaluated in the Windows/Nightjar workflow and is intentionally limited to the identified Uncharted menu/pause compositing shaders. See [technical notes](docs/uncharted-menu-focus-slab.md) for details.

## Uncharted gunfire sound fix

In **Uncharted: Golden Abyss**, automatic gunfire could keep playing for about 15 seconds after the weapon stopped firing (seen with the AK-47: fire from cover until the magazine is empty, keep fire held, return to cover). A game-specific correction stops it.

- **Default:** On, including the first launch with no saved preference.
- **In-game setting:** Press **F10 → Game → Gunfire sound fix**, or use the top-edge **Game** menu. A change applies at once.
- **Saved preference:** Stored in Uncharted's own `settings.ini`. The setting does not appear in other games.
- **Diagnostic override:** `RECOMP_UC_FIRE_LOOP_FIX=0` disables the correction and `RECOMP_UC_FIRE_LOOP_FIX=1` forces it on for the process. When an override is set, the in-game control is unavailable until the game is restarted without it.
- **Trace:** `RECOMP_UC_SND_TRACE=1` logs each gunfire loop from start to end (`uc-snd:` and `uc-fl:` lines). Off by default.

The correction only re-sends a stop the game itself already requested, and only for looping gun sounds. A cancelled burst can still start one shot; in the AK47 tests that shot was not perceptible to the tester. The fix was validated at 30 and 120 FPS with the environment override; the in-game toggle introduced afterward has not yet been tested on the device. Recompile Uncharted after updating: the correction is part of the game's own hooks. See [technical notes](docs/uncharted-ak47-early-stop.md).

## Controller and touchscreen setup

For games with Vita touch requirements:

- **DualShock 4 touchpad:** Use the touchpad for emulated touch input. The fork was developed around rear-touch behavior with L1/R1 touch-target modifiers.
- **Quick taps and drags:** Short gestures, click-and-hold, dragging and release handling received particular attention.
- **Android handheld:** When streaming to an Astra 2 or similar device, the handheld's touchscreen can provide front-touch input in supported configurations.
- **Vita system dialogs:** Check D-pad and face-button navigation in save, load and other system menus after recompiling a game.

### Streaming with Nightjar

This fork was tested in a workflow where Project Nativ runs **on the Windows PC** and [Nightjar Custom](https://github.com/jvanderv42/nightjar) streams the desktop game to an Android handheld. Nightjar is a separate application: **Project Nativ does not run natively on Android**, and this Windows ZIP is not an Android APK.

The streaming host, network, controller pairing and client settings still determine end-to-end latency and stream quality. The frame-aware runtime is intended to avoid unnecessary work in the Windows game's own presentation path; it cannot eliminate network jitter or guarantee a particular FPS.

## Games and compatibility

The underlying Project Nativ repository includes game packs for these **US-region** game versions:

| Game | Title ID | Supported upstream pack versions | Custom-fork testing |
| --- | --- | --- | --- |
| **Uncharted: Golden Abyss** | `PCSA00029` | 1.00 | Primary focus; local and Nightjar-streamed gameplay tested |
| **Killzone: Mercenary** | `PCSA00107` | 1.00, 1.12 | Compiled and played; earlier 60 FPS streaming tests |
| Unit 13 | `PCSA00014` | 1.00 | Included upstream pack; not independently verified for this fork |
| Shovel Knight | `PCSE00640` | 1.00 | Included upstream pack; not independently verified for this fork |

Supported versions are matched against the game's executable. Other regions or later game updates are not automatically supported just because a game has the same title. Check the launcher and [upstream player guide](docs/player-guide.md).

### Performance expectations

- **60 FPS:** Earlier Uncharted and Killzone gameplay testing reached approximately 60 FPS locally and over Nightjar in the tested setups.
- **120 FPS:** An experimental mode was implemented and tested successfully in Uncharted gameplay. This is **not** a blanket compatibility guarantee for cinematics, scripted events, animation timing or physics, and Killzone gameplay at 120 FPS was not established in the same way.
- **Streaming:** Higher configured FPS requires sufficient PC performance, streaming host/client support, display refresh rate, decoder capacity and network conditions.

## How Project Nativ works

Project Nativ is **not conventional emulation**. Its recompilation pipeline translates a supported PS Vita game's ARMv7/Thumb-2/VFP/NEON code into C ahead of time and compiles that output into a native desktop executable. It reconstructs the system-library and runtime behavior the game expects: threading, input, graphics, audio, media and networking.

The game and firmware are supplied locally by the user. **No Sony firmware or commercial game code/data is included in this repository or release downloads.**

For a detailed explanation, see [Architecture](docs/architecture.md), [Runtime](docs/runtime.md) and [Developer documentation](docs/developers.md).

## Releases, source and development

**Download the current build from [Releases](https://github.com/jvanderv42/nativ/releases).** The release page is the authoritative source for packaged Windows binaries, checksums and the source commit; older releases remain available for rollback. Do not substitute a historical package for a newer source tree: an old binary does not automatically include the new gunfire and menu changes.

The current `main` branch combines the previously accepted touch-input, frame-pacing, 120 FPS, graphics and stability changes with the Uncharted menu blur and early-stop gunfire fixes. Both are game-specific and default to On. Use **F10 → Game** for their saved toggles. Changes to the menu layout and the newly added gunfire toggle require validation in-game even when the source compiles and packages successfully.

The accepted earlier Distribution 45 is preserved under [v0.1.5-custom.4](https://github.com/jvanderv42/nativ/releases/tag/v0.1.5-custom.4); that older ZIP **predates the gunfire fix** and the blur-control menu relocation. The experimental AK47 fix was exercised at 30 and 120 FPS in the lab build, but the latest integrated source should be rebuilt and Uncharted recompiled before testing the in-game toggle.

This Windows distribution is built through [GitHub Actions](https://github.com/jvanderv42/nativ/actions). Release packages include a complete installation, provenance and SHA-256 checksums. Historical development branches remain for reference; continue normal development from `main` and isolate experiments on dedicated branches.

## Known limitations and feedback

- **120 FPS is experimental.** Some Vita titles may tie game logic or cinematic timing to their original frame rate.
- **Touch input can still vary with load.** Intermittent touch-cursor stuttering was observed during demanding scenes and cinematics; the accepted release is a stable baseline, not proof that every edge case is solved.
- **Device coverage is limited.** Hands-on testing primarily covered the Windows/Android handheld/DualShock 4 workflow described above.
- **Not every upstream game pack has been independently verified with this fork.**
- **No bundled games or firmware.** You must supply your own supported files.
- **Recompile Uncharted after updating** to include the gunfire hook and other game-specific recompilation changes. Keep a known-good game build for rollback.
- **Gunfire fix coverage is limited:** confirmed with the AK47 at 30 and 120 FPS; other automatic weapons and unusual transitions have not been exhaustively tested. A single cancelled-shot event can still occur.

For a useful bug report, include the release or source commit, game title ID/version, Windows and GPU information, controller model and connection method, local-versus-streamed behavior, reproduction steps, and logs if available. Please remove personal information from logs before sharing.

[Open an issue for this fork](https://github.com/jvanderv42/nativ/issues) for custom Windows distribution, touch-input or streaming-related problems. For general upstream Project Nativ behavior, see the [original repository](https://github.com/TheLostPantheon/nativ).

## Documentation

- [Player guide](docs/player-guide.md) — installing, first run, controls and troubleshooting
- [Architecture](docs/architecture.md) — static recompilation and system/runtime design
- [Developer guide](docs/developers.md) — build pipeline, tools and game packs
- [Runtime](docs/runtime.md) — graphics, timing, audio and input
- [Verification](docs/verification.md) — regression testing and validation
- [Debugging](docs/debugging.md) — diagnostics, captures and logs
- [Online play](docs/online.md) — matchmaking and networking

## Credits, licensing and relationship to upstream

**Project Nativ Custom is an independent, unofficial fork** of [Project Nativ by TheLostPantheon and contributors](https://github.com/TheLostPantheon/nativ). The original project's static recompiler, game packs, platform runtime, launcher, documentation and foundational game-compatibility work remain the basis of this fork. This edition adds Windows-focused touch/input, presentation, high-refresh-rate and packaging changes.

The repository is licensed under **GNU GPL version 2 or (at your option) any later version**; see [LICENSE](LICENSE). Third-party dependencies retain their own licenses; see [THIRD_PARTY.md](THIRD_PARTY.md).

As documented by the original project, AI-assisted tools have been used in development and documentation under human direction and testing.

The original project's [Ko-fi](https://ko-fi.com/kingtorro) belongs to its upstream developer, **not** to this custom fork.

---

<p align="center">
  <strong>Want to try PS Vita recompilation with improved touch controls and PC streaming?</strong>
</p>
<p align="center">
  <a href="https://github.com/jvanderv42/nativ/releases"><strong>Download Project Nativ Custom</strong></a>
  &nbsp;·&nbsp;
  <a href="https://github.com/jvanderv42/nativ/issues">Report an issue</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/TheLostPantheon/nativ">Original Project Nativ</a>
</p>
