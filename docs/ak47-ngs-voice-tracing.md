# AK47 gunfire sound lifecycle diagnostics

This diagnostic branch extends the Project Nativ NGS player-voice log without intentionally changing audio playback, buffering, mixing, timing, or input.

## Enable tracing on Windows

Set `RECOMP_NGS_SFX_TRACE=1` in the environment **before launching the recompiled Uncharted game executable**. This environment variable is read in the game process, not solely by the Project Nativ launcher. A PowerShell example when launching the game directly:

```powershell
# Run in PowerShell on the Windows gaming PC, in the compiled game's directory.
# Diagnostic only: the game and its data are not modified by this command.
$env:RECOMP_NGS_SFX_TRACE = '1'
try {
    & '.\Uncharted.exe' 2>&1 | Out-File -FilePath '.\ak47VoiceTrace.log' -Encoding utf8
}
finally {
    Remove-Item Env:\RECOMP_NGS_SFX_TRACE -ErrorAction SilentlyContinue
}
```

Replace `Uncharted.exe` with the actual game executable filename. Alternatively, set the variable in the game launcher's environment, **if** that launcher passes environment variables through to the game. The normal game `session.log` might already contain stderr events if the launcher captures it; verify that `sfx: ... event=play` appears near the beginning of gameplay.

## What is recorded

Each player voice (PCM, ADPCM, ATRAC9) is assigned a voice index and a per-voice play sequence. Diagnostic lines beginning `sfx:` include a relative monotonic timestamp (`t_ms`), game frame, audio-system update, voice index, sequence, voice handle, definition, relevant guest caller, playing/releasing state, elapsed time, current buffer and offset, loop policy, observed loop count, sample count, and a 64-byte FNV-1a sound fingerprint.

Record types: `play`, `kill-request`, `keyoff-request`, `keyoff-applied`, `pause`, `resume`, `loop-summary`, `buffer-swapped`, `player-stopped`, `end-of-data`, `decode-error`, `release-completed`, `finished-callback-queued`, `finished-callback-delivered`, and `module-callback-delivered`.

A `play` also records the four configured audio-buffer descriptors. Repeated loop events are summarized on the first loop, on powers of two, or at least every five seconds, rather than logging every sample or loop.

## Reproduction

1. Preserve the verified v0.1.5-custom.4 Windows distribution as the rollback copy.
2. Build the diagnostic distribution and **recompile Uncharted** using its runtime; keep compiled games and saves backed up.
3. Start a recording with audio, enable tracing and play locally with mouse and keyboard. Verify `sfx:` lines are produced.
4. On reproduction, stop firing for several seconds but leave the weapon selected; then switch weapons. Note when the stuck sound stops.
5. Exit normally and provide the video and `session.log` or `ak47VoiceTrace.log`. Correlate the `t_ms` / frame with the video and compare the looping voice's sequence against its stop or callback events.

A trace alone cannot tell whether a sample audibly resembles an AK47. Correlation uses the captured video timing, repeated loop activity, playback duration and fingerprint consistency. The log may grow; do not enable it for routine gameplay.

## Validation

The changes are instrumentation-only in the source. A passing GitHub Actions distribution workflow confirms the package was built and contains the instrumented file, **not** that diagnostic output or audio playback have been validated on the target Windows system.

## Cause-trace extension (November 15, 2026)

The first successful diagnostic reproduction exhibited 347, 356, and 306 Play events in consecutive five-second windows (trace 105-120 seconds), with similar numbers of KeyOff requests. That is evidence of repeated game-issued Play calls, not a single voice looping alone, but the NGS implementation could still be influencing guest behavior.

This cause-trace extension preserves NGS audio behavior and adds:

- `cb_depth`, `cb_voice`, `cb_reason`, and `cb_finished` to every `sfx:` record. A nonzero depth means the API was invoked synchronously from a guest NGS callback. Depth zero does not rule out an earlier callback influencing guest state.
- Optional `RECOMP_NGS_SFX_QUERY_TRACE=1`: one-second `sfx-query:` summaries of SceNgsVoiceGetInfo and SceNgsVoiceGetStateData call counts and the active, releasing, and paused statuses observed for each immediate caller LR. Each API tracks up to 24 distinct LR addresses; the rest are omitted. These counters add overhead, so leave disabled outside focused testing.

Launch Project Nativ from PowerShell with both variables set, then use this diagnostic distribution to **recompile Uncharted** before running it:

```powershell
$env:RECOMP_NGS_SFX_TRACE = '1'
$env:RECOMP_NGS_SFX_QUERY_TRACE = '1'
# Run the actual diagnostic 'Project Nativ.exe' from this session.
```

Record a short video, the `session.log`, and the time the stuck sound begins and stops. The next investigation compares callback attribution and voice state polls during the sound burst, not aggregate voice-count totals alone.

Do not interpret a passing build as verification of playback or logging on a target Windows PC.
