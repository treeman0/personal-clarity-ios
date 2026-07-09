#!/usr/bin/env python3

import argparse
import datetime as dt
import json
import subprocess
from pathlib import Path
from urllib.parse import quote


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_RECORD = ROOT / "docs" / "V2_LOCAL_ACCEPTANCE_RECORD.md"


def run(*args: str, check: bool = True) -> str:
    try:
        result = subprocess.run(
            args,
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as error:
        if check:
            raise RuntimeError(f"Required command not found: {args[0]}") from error
        return ""
    if check and result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or f"Command failed: {' '.join(args)}")
    return result.stdout.strip()


def workflow_evidence(workflow: str, sha: str) -> str:
    output = run(
        "gh", "run", "list",
        "--workflow", workflow,
        "--commit", sha,
        "--limit", "1",
        "--json", "databaseId,status,conclusion,url,headSha",
        check=False,
    )
    if not output:
        return f"not found for {sha}"
    try:
        runs = json.loads(output)
    except json.JSONDecodeError:
        return f"gh unavailable for {sha}"
    if not runs:
        return f"not found for {sha}"
    item = runs[0]
    return (
        f"run {item['databaseId']} {item['status']}/{item['conclusion']} "
        f"for {item['headSha']} {item['url']}"
    )


def alert_count(endpoint: str) -> str:
    output = run("gh", "api", endpoint, "--jq", "length", check=False)
    return output if output.isdigit() else "unknown"


def repository_status(sha: str, record_path: Path) -> str:
    pathspecs = [".", ":(exclude)docs/V1_ACCEPTANCE_RECORD.md"]
    try:
        relative_record = record_path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        pass
    else:
        pathspecs.append(f":(exclude){relative_record}")
    status = run("git", "status", "--porcelain", "--", *pathspecs)
    upstream = run("git", "rev-parse", "@{upstream}", check=False)
    if not status and upstream == sha:
        return f"clean and synced at {sha}"
    details = status.replace("\n", "; ") or f"upstream={upstream or 'not configured'}"
    return f"not clean/synced at {sha}: {details}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate ClarityHub V2 Local acceptance evidence.")
    parser.add_argument("--output", default=str(DEFAULT_RECORD))
    args = parser.parse_args()
    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = ROOT / output_path
    output_path.parent.mkdir(parents=True, exist_ok=True)

    sha = run("git", "rev-parse", "HEAD")
    verifier_output = run("bash", "scripts/verify-v2-config.sh", check=False)
    verifier = "V2 Cloud and Local configurations verified." if "V2 Cloud and Local configurations verified." in verifier_output else "failed"
    branch = run("git", "branch", "--show-current")
    code_scanning_endpoint = (
        "repos/treeman0/personal-clarity-ios/code-scanning/alerts"
        f"?state=open&ref={quote('refs/heads/' + branch, safe='')}"
    )
    alerts = (
        f"code_scanning_alerts={alert_count(code_scanning_endpoint)}, "
        f"secret_scanning_alerts={alert_count('repos/treeman0/personal-clarity-ios/secret-scanning/alerts?state=open')}, "
        f"dependabot_alerts={alert_count('repos/treeman0/personal-clarity-ios/dependabot/alerts?state=open')}"
    )

    content = f"""# ClarityHub V2 Local Acceptance Record

Candidate commit: {sha}
Date: {dt.date.today().isoformat()}
Tester:
Device:
iOS version:
Personal Team ID:
Bundle ID: com.treeman0.ClarityHub.Personal
Local/remote status: {repository_status(sha, output_path)}
V2 configuration verifier: {verifier}
iOS CI: {workflow_evidence('iOS CI', sha)}
CodeQL: {workflow_evidence('CodeQL', sha)}
Open security alerts: {alerts}
Local build pass/fail:
Install and launch pass/fail:
Data mode status pass/fail:
Combined HealthKit authorization pass/fail:
HealthKit terminal state pass/fail:
Morning reminder pass/fail:
Relaunch persistence pass/fail:
Open V2-blocking defects:
Notes:
Screenshots captured:
Accepted for V2 Local: no
Reason: Device acceptance has not been executed.
Reviewer:
"""
    output_path.write_text(content, encoding="utf-8")
    print(f"Generated {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
