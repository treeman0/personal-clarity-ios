#!/usr/bin/env python3

import tempfile
import unittest
from pathlib import Path
from typing import List

from validate_v2_local_acceptance import validate


VALID_RECORD = """# ClarityHub V2 Local Acceptance Record

Candidate commit: 0123456789abcdef0123456789abcdef01234567
Date: 2026-07-09
Tester: Test User
Device: Test iPhone
iOS version: 18.6.2
Personal Team ID: A1B2C3D4E5
Bundle ID: com.treeman0.ClarityHub.Personal
Local/remote status: clean and synced at 0123456789abcdef0123456789abcdef01234567
V2 configuration verifier: V2 Cloud and Local configurations verified.
iOS CI: run 100 completed/success for 0123456789abcdef0123456789abcdef01234567
CodeQL: run 101 completed/success for 0123456789abcdef0123456789abcdef01234567
Open security alerts: code_scanning_alerts=0, secret_scanning_alerts=0, dependabot_alerts=0
Local build pass/fail: pass
Install and launch pass/fail: pass
Data mode status pass/fail: pass
Combined HealthKit authorization pass/fail: pass
HealthKit terminal state pass/fail: pass
Morning reminder pass/fail: pass
Relaunch persistence pass/fail: pass
Open V2-blocking defects: 0
Notes: Local target installed and completed the focused device pass.
Screenshots captured: Settings data mode, Body Health state, reminder state, persisted goal after relaunch.
Accepted for V2 Local: yes
Reason: The no-cost V2 target passed automated and physical-device acceptance.
Reviewer: Test Reviewer
"""


class V2AcceptanceToolingTests(unittest.TestCase):
    def validate_record(self, content: str) -> List[str]:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "record.md"
            path.write_text(content, encoding="utf-8")
            return validate(path)

    def test_complete_record_passes(self) -> None:
        self.assertEqual(self.validate_record(VALID_RECORD), [])

    def test_unaccepted_record_fails(self) -> None:
        failures = self.validate_record(VALID_RECORD.replace(
            "Accepted for V2 Local: yes",
            "Accepted for V2 Local: no",
        ))
        self.assertIn("Accepted for V2 Local must be yes.", failures)

    def test_failed_device_check_fails(self) -> None:
        failures = self.validate_record(VALID_RECORD.replace(
            "Combined HealthKit authorization pass/fail: pass",
            "Combined HealthKit authorization pass/fail: fail",
        ))
        self.assertIn("Combined HealthKit authorization pass/fail must be pass.", failures)

    def test_placeholder_screenshots_fail(self) -> None:
        failures = self.validate_record(VALID_RECORD.replace(
            "Screenshots captured: Settings data mode, Body Health state, reminder state, persisted goal after relaunch.",
            "Screenshots captured: none",
        ))
        self.assertIn("Screenshots captured must name real evidence.", failures)

    def test_blocking_defect_fails(self) -> None:
        failures = self.validate_record(VALID_RECORD.replace(
            "Open V2-blocking defects: 0",
            "Open V2-blocking defects: 1",
        ))
        self.assertIn("Open V2-blocking defects must be 0.", failures)


if __name__ == "__main__":
    unittest.main()
