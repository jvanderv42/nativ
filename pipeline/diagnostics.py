"""Launch-time diagnostics for Project Nativ.

The game menu saves diag_log_level in settings.ini. This module turns that
preference into process environment values before launch. Explicit environment
variables override individual defaults. No log file is touched when Off.
"""
import os
import subprocess


def read_saved_level(path):
    """Return a saved 0..3 diagnostic level, or None if absent/invalid."""
    try:
        with open(path, encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if not line or line.startswith(("#", ";")) or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                if key.strip() == "diag_log_level":
                    return max(0, min(3, int(value.strip())))
    except (OSError, ValueError):
        pass
    return None


def diagnostic_level(game_settings_path, shared_settings_path):
    """Per-game override precedes the shared setting, matching runtime/settings.c."""
    game_level = read_saved_level(game_settings_path)
    if game_level is not None:
        return game_level
    shared_level = read_saved_level(shared_settings_path)
    return shared_level if shared_level is not None else 0


def launch_diagnostics(level, environ):
    """Produce the effective diagnostic environment for this new game process.

    Nonempty explicit environment values win, including "0". Every level is
    silent by default unless its logging was requested; other diagnostics are
    not silently enabled when session recording is forced Off.
    """
    level = max(0, min(3, int(level)))
    enabled = environ.get("RECOMP_SESSION_LOG", "1" if level else "0") == "1"
    def choice(key, default):
        value = environ.get(key)
        return value if value is not None and value != "" else str(default)

    return {
        "RECOMP_SESSION_LOG": "1" if enabled else "0",
        "RECOMP_DIAG_LOG_LEVEL": str(level),
        "RECOMP_HITCH_LOG": choice("RECOMP_HITCH_LOG", "50" if enabled else "0"),
        "RECOMP_STALL_PROF": choice("RECOMP_STALL_PROF", "150" if enabled else "0"),
        "RECOMP_UC_SND_TRACE": choice("RECOMP_UC_SND_TRACE", "1" if enabled and level >= 2 else "0"),
        "RECOMP_NGS_DEBUG": choice("RECOMP_NGS_DEBUG", "2" if enabled and level >= 3 else "0"),
    }


def run_session(argv, env, cwd, start_game, tee_run):
    """Launch without touching log files when recording is Off.

    The caller's start_game wraps platform-specific Windows error reporting.
    In recording mode, preserve the existing rotation and tee behavior.
    """
    if env["RECOMP_SESSION_LOG"] == "1":
        current = os.path.join(cwd, "session.log")
        previous = os.path.join(cwd, "session.prev.log")
        if os.path.isfile(current):
            os.replace(current, previous)
        return tee_run(argv, env, cwd, current)

    # Intentionally discard even errors as the user selected no logging.
    process = start_game(argv, env=env, cwd=cwd, stderr=subprocess.DEVNULL)
    try:
        return process.wait()
    except KeyboardInterrupt:
        process.terminate()
        return process.wait()
