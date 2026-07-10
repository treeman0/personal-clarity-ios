#!/usr/bin/env python3

import argparse
import re
from pathlib import Path
from typing import List, Optional


REQUIRED_FIELDS = [
    "Candidate commit:",
    "Date:",
    "Tester:",
    "Device:",
    "iOS version:",
    "Personal Team ID:",
    "Bundle ID:",
    "Local/remote status:",
    "V2 configuration verifier:",
    "iOS CI:",
    "CodeQL:",
    "Open security alerts:",
    "Local build pass/fail:",
    "Install and launch pass/fail:",
    "Data mode status pass/fail:",
    "Combined HealthKit authorization pass/fail:",
    "HealthKit terminal state pass/fail:",
    "Morning reminder pass/fail:",
    "Relaunch persistence pass/fail:",
    "Open V2-blocking defects:",
    "Notes:",
    "Screenshots captured:",
    "Accepted for V2 Local:",
    "Reason:",
    "Reviewer:",
]

PASS_FIELDS = [
    "Local build pass/fail:",
    "Install and launch pass/fail:",
    "Data mode status pass/fail:",
    "Combined HealthKit authorization pass/fail:",
    "HealthKit terminal state pass/fail:",
    "Morning reminder pass/fail:",
    "Relaunch persistence pass/fail:",
]

PLACEHOLDERS = {"", "none", "n/a", "na", "todo", "tbd", "pending", "not run"}


def field_value(content: str, field: str) -> Optional[str]:
    match = re.search(rf"(?m)^{re.escape(field)}[ \t]*(.*)$", content)
    return match.group(1).strip() if match else None


def validate(path: Path) -> List[str]:
    content = path.read_text(encoding="utf-8")
    failures: List[str] = []

    for field in REQUIRED_FIELDS:
        value = field_value(content, field)
        if value is None:
            failures.append(f"Missing field: {field}")
        elif value.lower() in PLACEHOLDERS:
            failures.append(f"Unfilled field: {field}")

    candidate = field_value(content, "Candidate commit:") or ""
    if not re.fullmatch(r"[0-9a-fA-F]{7,40}", candidate):
        failures.append("Candidate commit must be a 7-40 character Git SHA.")
    else:
        for field in ("Local/remote status:", "iOS CI:", "CodeQL:"):
            value = field_value(content, field) or ""
            if candidate not in value:
                failures.append(f"{field} must reference candidate commit {candidate}.")

    if field_value(content, "Bundle ID:") != "com.treeman0.ClarityHub.Personal":
        failures.append("Bundle ID must be com.treeman0.ClarityHub.Personal.")

    team_id = field_value(content, "Personal Team ID:") or ""
    if not re.fullmatch(r"[A-Z0-9]{10}", team_id):
        failures.append("Personal Team ID must be a 10-character Apple team identifier.")

    status = field_value(content, "Local/remote status:") or ""
    if not status.startswith("clean and synced at "):
        failures.append("Local/remote status must be clean and synced.")

    verifier = field_value(content, "V2 configuration verifier:")
    if verifier != "V2 Cloud and Local configurations verified.":
        failures.append("V2 configuration verifier must pass.")

    for field in ("iOS CI:", "CodeQL:"):
        value = field_value(content, field) or ""
        if not re.search(r"run \d+ completed/success", value):
            failures.append(f"{field} must identify a successful workflow run.")

    expected_alerts = "code_scanning_alerts=0, secret_scanning_alerts=0, dependabot_alerts=0"
    if field_value(content, "Open security alerts:") != expected_alerts:
        failures.append("Open security alerts must all be zero.")

    for field in PASS_FIELDS:
        if (field_value(content, field) or "").lower() != "pass":
            failures.append(f"{field[:-1]} must be pass.")

    if field_value(content, "Open V2-blocking defects:") != "0":
        failures.append("Open V2-blocking defects must be 0.")

    screenshots = (field_value(content, "Screenshots captured:") or "").lower()
    if screenshots in PLACEHOLDERS:
        failures.append("Screenshots captured must name real evidence.")

    if (field_value(content, "Accepted for V2 Local:") or "").lower() != "yes":
        failures.append("Accepted for V2 Local must be yes.")

    reason = (field_value(content, "Reason:") or "").lower()
    if any(word in reason for word in ("pending", "not run", "not executed", "todo", "tbd")):
        failures.append("Reason must describe completed acceptance evidence.")

    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate ClarityHub V2 Local acceptance evidence.")
    parser.add_argument("path", nargs="?", default="docs/V2_LOCAL_ACCEPTANCE_RECORD.md")
    args = parser.parse_args()
    path = Path(args.path)
    if not path.exists():
        print(f"V2 Local acceptance record not found: {path}")
        return 1

    failures = validate(path)
    if failures:
        print("V2 Local acceptance record is incomplete:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("V2 Local acceptance record is complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
