param(
    [string] $OutputPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RepositoryRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Get-StatusOutput {
    $root = Get-RepositoryRoot
    Push-Location $root
    try {
        return ((& (Join-Path $PSScriptRoot "v1-local-status.ps1") *>&1) | Out-String).Trim()
    } finally {
        Pop-Location
    }
}

function Get-AutoFillSection {
    param(
        [Parameter(Mandatory = $true)]
        [string] $StatusOutput
    )

    $marker = "## Acceptance record auto-fill"
    $index = $StatusOutput.IndexOf($marker)
    if ($index -lt 0) {
        throw "v1-local-status.ps1 did not print the '$marker' section."
    }

    return $StatusOutput.Substring($index + $marker.Length).Trim()
}

function Get-CandidateCommit {
    param(
        [Parameter(Mandatory = $true)]
        [string] $AutoFill
    )

    foreach ($line in ($AutoFill -split "`r?`n")) {
        if ($line.StartsWith("Candidate commit: ")) {
            return $line.Substring("Candidate commit: ".Length)
        }
    }

    return "not found; rerun .\scripts\v1-local-status.ps1"
}

$statusOutput = Get-StatusOutput
$autoFill = Get-AutoFillSection $statusOutput
$candidateCommit = Get-CandidateCommit $autoFill
$generatedAt = (Get-Date).ToString("s")

$recordTemplate = @'
# ClarityHub V1 Acceptance Record

This record is the manual execution artifact for `docs/V1_ACCEPTANCE_RUNBOOK.md`. It is intentionally not marked accepted until each pass/fail field is filled with real iPhone or simulator evidence.

## Release Candidate

```text
Candidate commit: {{CandidateCommit}}
Date: {{GeneratedAt}}
Tester:
Device or simulator:
iOS version:
Apple ID / iCloud state:
HealthKit data state:
Google OAuth client ID available: yes/no
Cal AI writes nutrition to Apple Health: yes/no/unknown
```

## Automated Evidence

```text
Source command: .\scripts\v1-local-status.ps1
Copy from section: Acceptance record auto-fill
{{AutoFill}}
```

## Clean Install Pass

```text
Light mode empty states pass/fail:
Dark mode empty states pass/fail:
Notes:
Screenshots captured:
```

## Core Data Entry Pass

```text
Goals pass/fail:
Habits pass/fail:
Lists/projects/tasks pass/fail:
Review pass/fail:
Nutrition pass/fail:
Notes:
Screenshots captured:
```

## Today Operating Pass

```text
Today pass/fail:
Dense data pass/fail:
Long text pass/fail:
Notes:
Screenshots captured:
```

## Integration Pass

```text
HealthKit pass/fail:
Notifications pass/fail:
Google Calendar pass/fail:
Nutrition integration pass/fail:
Notes:
Screenshots captured:
```

## Persistence And Sync Pass

```text
Relaunch persistence pass/fail:
Private CloudKit sync pass/fail/not available:
Notes:
Screenshots captured:
```

## Defect Log

| ID | Area | Severity | Finding | Evidence | V1 decision |
| --- | --- | --- | --- | --- | --- |
| A-001 |  |  |  |  | fix/defer |

## Acceptance Decision

```text
Accepted for V1: no
Reason: Manual iPhone/simulator acceptance has not been executed yet.
Reviewer:
Date:
```
'@

$record = $recordTemplate.
    Replace("{{CandidateCommit}}", $candidateCommit).
    Replace("{{GeneratedAt}}", $generatedAt).
    Replace("{{AutoFill}}", $autoFill)

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    Write-Output $record
} else {
    if ([System.IO.Path]::IsPathRooted($OutputPath)) {
        $resolvedOutputPath = $OutputPath
    } else {
        $resolvedOutputPath = Join-Path (Get-RepositoryRoot) $OutputPath
    }

    $outputDirectory = Split-Path -Parent $resolvedOutputPath
    if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
        New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
    }

    Set-Content -LiteralPath $resolvedOutputPath -Value $record -Encoding utf8
    Write-Output "Wrote $resolvedOutputPath"
}
