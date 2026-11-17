"""Focused regression tests for the in-game Diagnostics controls and launch policy."""
import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from diagnostics import diagnostic_level, launch_diagnostics, run_session


class DiagnosticsTests(unittest.TestCase):
    def test_default_off_does_not_enable_logging(self):
        cfg = launch_diagnostics(0, {})
        self.assertEqual(cfg["RECOMP_SESSION_LOG"], "0")
        self.assertEqual(cfg["RECOMP_HITCH_LOG"], "0")
        self.assertEqual(cfg["RECOMP_STALL_PROF"], "0")
        self.assertEqual(cfg["RECOMP_UC_SND_TRACE"], "0")
        self.assertEqual(cfg["RECOMP_NGS_DEBUG"], "0")

    def test_basic_captures_session_and_hitches_without_verbose_audio(self):
        cfg = launch_diagnostics(1, {})
        self.assertEqual(cfg["RECOMP_SESSION_LOG"], "1")
        self.assertEqual(cfg["RECOMP_HITCH_LOG"], "50")
        self.assertEqual(cfg["RECOMP_STALL_PROF"], "150")
        self.assertEqual(cfg["RECOMP_UC_SND_TRACE"], "0")
        self.assertEqual(cfg["RECOMP_NGS_DEBUG"], "0")

    def test_detailed_only_adds_game_sound_trace(self):
        cfg = launch_diagnostics(2, {})
        self.assertEqual(cfg["RECOMP_SESSION_LOG"], "1")
        self.assertEqual(cfg["RECOMP_UC_SND_TRACE"], "1")
        self.assertEqual(cfg["RECOMP_NGS_DEBUG"], "0")

    def test_verbose_enables_ngs_level_two(self):
        cfg = launch_diagnostics(3, {})
        self.assertEqual(cfg["RECOMP_UC_SND_TRACE"], "1")
        self.assertEqual(cfg["RECOMP_NGS_DEBUG"], "2")

    def test_explicit_zero_overrides_detailed_and_verbose(self):
        cfg = launch_diagnostics(3, {
            "RECOMP_UC_SND_TRACE": "0",
            "RECOMP_NGS_DEBUG": "0",
            "RECOMP_HITCH_LOG": "0",
            "RECOMP_STALL_PROF": "0",
        })
        for key in ("RECOMP_UC_SND_TRACE", "RECOMP_NGS_DEBUG", "RECOMP_HITCH_LOG", "RECOMP_STALL_PROF"):
            self.assertEqual(cfg[key], "0")

    def test_session_override_is_respected(self):
        disabled = launch_diagnostics(3, {"RECOMP_SESSION_LOG": "0"})
        self.assertEqual(disabled["RECOMP_SESSION_LOG"], "0")
        self.assertEqual(disabled["RECOMP_NGS_DEBUG"], "0")
        enabled = launch_diagnostics(0, {"RECOMP_SESSION_LOG": "1"})
        self.assertEqual(enabled["RECOMP_SESSION_LOG"], "1")
        self.assertEqual(enabled["RECOMP_NGS_DEBUG"], "0")

    def test_explicit_audio_override_remains_available_with_recording_off(self):
        cfg = launch_diagnostics(0, {"RECOMP_UC_SND_TRACE": "1"})
        self.assertEqual(cfg["RECOMP_SESSION_LOG"], "0")
        self.assertEqual(cfg["RECOMP_UC_SND_TRACE"], "1")

    def test_saved_level_is_shared_unless_game_overrides(self):
        with tempfile.TemporaryDirectory() as root:
            game = Path(root) / "game.ini"
            shared = Path(root) / "shared.ini"
            shared.write_text("# a comment\ndiag_log_level = 2\n", encoding="utf-8")
            self.assertEqual(diagnostic_level(str(game), str(shared)), 2)
            game.write_text("diag_log_level = 3\n", encoding="utf-8")
            self.assertEqual(diagnostic_level(str(game), str(shared)), 3)
            game.write_text("diag_log_level = no\n", encoding="utf-8")
            self.assertEqual(diagnostic_level(str(game), str(shared)), 2)

    def test_saved_level_defaults_off_and_clamps_invalid_range(self):
        with tempfile.TemporaryDirectory() as root:
            game = Path(root) / "game.ini"
            shared = Path(root) / "shared.ini"
            self.assertEqual(diagnostic_level(str(game), str(shared)), 0)
            shared.write_text("diag_log_level = 99\n", encoding="utf-8")
            self.assertEqual(diagnostic_level(str(game), str(shared)), 3)
            shared.write_text("diag_log_level = -4\n", encoding="utf-8")
            self.assertEqual(diagnostic_level(str(game), str(shared)), 0)

    def test_off_never_creates_or_rotates_logs(self):
        class FakeProcess:
            def wait(self):
                return 0
            def terminate(self):
                raise AssertionError("Unexpected termination")

        with tempfile.TemporaryDirectory() as root:
            existing = Path(root) / "session.log"
            existing.write_text("existing", encoding="utf-8")
            started = []
            def fake_start(argv, **kwargs):
                started.append(kwargs)
                return FakeProcess()
            def unexpected_tee(*args):
                raise AssertionError("Session logging was not requested")

            result = run_session(["game"], launch_diagnostics(0, {}), root, fake_start, unexpected_tee)
            self.assertEqual(result, 0)
            self.assertEqual(existing.read_text(encoding="utf-8"), "existing")
            self.assertFalse((Path(root) / "session.prev.log").exists())
            self.assertEqual(started[0]["stderr"], __import__("subprocess").DEVNULL)

    def test_enabled_rotates_previous_session_and_calls_tee(self):
        with tempfile.TemporaryDirectory() as root:
            previous = Path(root) / "session.log"
            previous.write_text("old", encoding="utf-8")
            calls = []
            def fake_tee(argv, env, cwd, path):
                calls.append(path)
                Path(path).write_text("new", encoding="utf-8")
                return 7
            result = run_session(["game"], launch_diagnostics(1, {}), root,
                                 lambda *a, **kw: self.fail("Unexpected silent run"), fake_tee)
            self.assertEqual(result, 7)
            self.assertEqual((Path(root) / "session.prev.log").read_text(encoding="utf-8"), "old")
            self.assertEqual(previous.read_text(encoding="utf-8"), "new")
            self.assertEqual(calls, [str(previous)])


if __name__ == "__main__":
    unittest.main()
