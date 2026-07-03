param(
    [string] $Path = "docs\V1_ACCEPTANCE_RECORD.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-Failure {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    $script:failures.Add($Message) | Out-Null
}

function Get-FieldValue {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,
        [Parameter(Mandatory = $true)]
        [string] $Field
    )

    $escapedField = [regex]::Escape($Field)
    $match = [regex]::Match($Content, "(?m)^$escapedField\s*(.*)$")
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups[1].Value.Trim()
}

function Test-FilledField {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,
        [Parameter(Mandatory = $true)]
        [string] $Field,
        [string[]] $InvalidValues = @("")
    )

    $value = Get-FieldValue -Content $Content -Field $Field
    if ($null -eq $value) {
        Add-Failure "Missing field: $Field"
        return
    }

    if ($InvalidValues -contains $value) {
        Add-Failure "Unfilled field: $Field"
    }
}

function Test-AllFieldOccurrencesFilled {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,
        [Parameter(Mandatory = $true)]
        [string] $Field
    )

    $escapedField = [regex]::Escape($Field)
    $matches = [regex]::Matches($Content, "(?m)^$escapedField\s*(.*)$")
    if ($matches.Count -eq 0) {
        Add-Failure "Missing field: $Field"
        return
    }

    foreach ($match in $matches) {
        if ([string]::IsNullOrWhiteSpace($match.Groups[1].Value.Trim())) {
            Add-Failure "Unfilled field: $Field"
        }
    }
}

function Test-AllFieldOccurrencesAvoidValues {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,
        [Parameter(Mandatory = $true)]
        [string] $Field,
        [Parameter(Mandatory = $true)]
        [string[]] $InvalidValues
    )

    $escapedField = [regex]::Escape($Field)
    $matches = [regex]::Matches($Content, "(?m)^$escapedField\s*(.*)$")
    foreach ($match in $matches) {
        $value = $match.Groups[1].Value.Trim().ToLowerInvariant()
        if ($InvalidValues -contains $value) {
            Add-Failure "Field '$Field' must capture evidence, not '$value'."
        }
    }
}

function Test-PassFailField {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,
        [Parameter(Mandatory = $true)]
        [string] $Field,
        [switch] $AllowNotAvailable
    )

    $value = Get-FieldValue -Content $Content -Field $Field
    if ($null -eq $value) {
        Add-Failure "Missing pass/fail field: $Field"
        return
    }

    $validValues = @("pass", "fail")
    if ($AllowNotAvailable) {
        $validValues += "not available"
    }

    if ($validValues -notcontains $value.ToLowerInvariant()) {
        Add-Failure "Field '$Field' must be one of: $($validValues -join ', ')"
    }
}

function Test-ChoiceField {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,
        [Parameter(Mandatory = $true)]
        [string] $Field,
        [Parameter(Mandatory = $true)]
        [string[]] $ValidValues
    )

    $value = Get-FieldValue -Content $Content -Field $Field
    if ($null -eq $value) {
        Add-Failure "Missing choice field: $Field"
        return
    }

    $normalizedValue = $value.ToLowerInvariant()
    $normalizedValidValues = $ValidValues | ForEach-Object { $_.ToLowerInvariant() }
    if ($normalizedValidValues -notcontains $normalizedValue) {
        Add-Failure "Field '$Field' must be one of: $($ValidValues -join ', ')"
    }
}

function Test-Contains {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,
        [Parameter(Mandatory = $true)]
        [string] $Needle,
        [Parameter(Mandatory = $true)]
        [string] $FailureMessage
    )

    if (-not $Content.Contains($Needle)) {
        Add-Failure $FailureMessage
    }
}

function Test-FieldMatches {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,
        [Parameter(Mandatory = $true)]
        [string] $Field,
        [Parameter(Mandatory = $true)]
        [string] $Pattern,
        [Parameter(Mandatory = $true)]
        [string] $FailureMessage
    )

    $value = Get-FieldValue -Content $Content -Field $Field
    if ($null -eq $value -or $value -notmatch $Pattern) {
        Add-Failure $FailureMessage
    }
}

function Test-FieldDoesNotMatch {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,
        [Parameter(Mandatory = $true)]
        [string] $Field,
        [Parameter(Mandatory = $true)]
        [string] $Pattern,
        [Parameter(Mandatory = $true)]
        [string] $FailureMessage
    )

    $value = Get-FieldValue -Content $Content -Field $Field
    if ($null -ne $value -and $value -match $Pattern) {
        Add-Failure $FailureMessage
    }
}

function Test-CandidateEvidenceConsistency {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content
    )

    $candidateValue = Get-FieldValue -Content $Content -Field "Candidate commit:"
    if ([string]::IsNullOrWhiteSpace($candidateValue)) {
        return
    }

    $candidateSha = ($candidateValue -split "\s+")[0]
    if ($candidateSha -notmatch "^[0-9a-fA-F]{7,40}$") {
        Add-Failure "Candidate commit must start with a 7-40 character Git SHA."
        return
    }

    foreach ($field in @(
        "Local/remote status:",
        "Current release-candidate GitHub Actions runs:",
        "iOS CI:",
        "CodeQL:",
        "Result bundle artifact:"
    )) {
        $value = Get-FieldValue -Content $Content -Field $field
        if ($null -eq $value -or -not $value.Contains($candidateSha)) {
            Add-Failure "Field '$field' must reference candidate commit $candidateSha."
        }
    }
}

function Test-DefectLog {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content
    )

    if ($Content.Contains("| A-001 |  |  |  |  | fix/defer |")) {
        Add-Failure "Defect log still contains the placeholder A-001 row."
        return
    }

    $defectRows = ($Content -split "`r?`n") | Where-Object {
        $_ -match '^\|\s*A-\d+\s*\|' -and $_ -notmatch '\|\s*---'
    }

    foreach ($row in $defectRows) {
        $columns = $row.Trim("|").Split("|") | ForEach-Object { $_.Trim() }
        if ($columns.Count -lt 6) {
            Add-Failure "Malformed defect row: $row"
            continue
        }

        foreach ($index in 0..4) {
            if ([string]::IsNullOrWhiteSpace($columns[$index])) {
                Add-Failure "Defect row has an empty required cell: $row"
                break
            }
        }

        $decision = $columns[5].ToLowerInvariant()
        if ($decision -ne "fixed" -and $decision -ne "deferred outside v1") {
            Add-Failure "Defect decision must be 'fixed' or 'deferred outside V1': $row"
        }
    }
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$recordPath = if ([System.IO.Path]::IsPathRooted($Path)) {
    $Path
} else {
    Join-Path $root $Path
}

if (-not (Test-Path -LiteralPath $recordPath)) {
    throw "Acceptance record not found: $recordPath"
}

$content = Get-Content -LiteralPath $recordPath -Raw
$script:failures = [System.Collections.Generic.List[string]]::new()

$requiredFields = @(
    "Candidate commit:",
    "Date:",
    "Tester:",
    "Device or simulator:",
    "iOS version:",
    "Apple ID / iCloud state:",
    "HealthKit data state:",
    "Google OAuth client ID available:",
    "Cal AI writes nutrition to Apple Health:",
    "Local/remote status:",
    "Loop status:",
    "Release verifier:",
    "Current release-candidate GitHub Actions runs:",
    "iOS CI:",
    "CodeQL:",
    "Result bundle artifact:",
    "Repository visibility:",
    "GitHub security features:",
    "Open security alerts:",
    "Additional automated coverage:",
    "Reason:",
    "Reviewer:"
)

foreach ($field in $requiredFields) {
    Test-FilledField -Content $content -Field $field
}

Test-FilledField -Content $content -Field "Candidate commit:" -InvalidValues @("run .\scripts\v1-local-status.ps1 and copy Local HEAD")
Test-ChoiceField -Content $content -Field "Google OAuth client ID available:" -ValidValues @("yes", "no")
Test-ChoiceField -Content $content -Field "Cal AI writes nutrition to Apple Health:" -ValidValues @("yes", "no", "unknown")
Test-CandidateEvidenceConsistency -Content $content

foreach ($field in @("Date:", "Notes:", "Screenshots captured:")) {
    Test-AllFieldOccurrencesFilled -Content $content -Field $field
}
Test-AllFieldOccurrencesAvoidValues -Content $content -Field "Screenshots captured:" -InvalidValues @("no", "none", "n/a", "na", "not captured", "todo", "tbd")

Test-Contains -Content $content -Needle "Loop status: clean" -FailureMessage "Loop status must be clean."
Test-Contains -Content $content -Needle "Release verifier: Release configuration verified." -FailureMessage "Release verifier must pass."
Test-FieldMatches -Content $content -Field "Local/remote status:" -Pattern "## main\.\.\.origin/main" -FailureMessage "Local/remote status must show main tracking origin/main."
Test-FieldDoesNotMatch -Content $content -Field "Local/remote status:" -Pattern "(^|\s)(M|A|D|R|C|U|\?\?)\s|ahead|behind|diverged" -FailureMessage "Local/remote status must be clean and synced before final acceptance."
Test-FieldMatches -Content $content -Field "Current release-candidate GitHub Actions runs:" -Pattern "iOS CI .*completed/success" -FailureMessage "Current release-candidate runs must include successful iOS CI for the candidate commit."
Test-FieldMatches -Content $content -Field "Current release-candidate GitHub Actions runs:" -Pattern "CodeQL .*completed/success" -FailureMessage "Current release-candidate runs must include successful CodeQL for the candidate commit."
Test-FieldDoesNotMatch -Content $content -Field "Current release-candidate GitHub Actions runs:" -Pattern "failure|cancelled|timed_out|action_required|startup_failure|stale|skipped|in_progress|queued|requested|waiting|pending|not found|no runs found|gh unavailable" -FailureMessage "Current release-candidate runs must not contain missing, pending, or failed workflow evidence."
Test-FieldMatches -Content $content -Field "iOS CI:" -Pattern "^run \d+,? completed/success,? " -FailureMessage "iOS CI field must identify a successful run for the candidate commit."
Test-FieldMatches -Content $content -Field "CodeQL:" -Pattern "^run \d+,? completed/success,? " -FailureMessage "CodeQL field must identify a successful run for the candidate commit."
Test-FieldMatches -Content $content -Field "Result bundle artifact:" -Pattern "^clarityhub-xcresult-" -FailureMessage "Result bundle artifact must name the retained iOS CI result artifact."
Test-FieldDoesNotMatch -Content $content -Field "Result bundle artifact:" -Pattern "not found|expired=True|gh unavailable" -FailureMessage "Result bundle artifact must be present and unexpired."
Test-FieldMatches -Content $content -Field "Repository visibility:" -Pattern "visibility=PUBLIC" -FailureMessage "Repository visibility must be public for the current CI workaround."
Test-FieldMatches -Content $content -Field "Repository visibility:" -Pattern "isPrivate=False" -FailureMessage "Repository visibility must report isPrivate=False."
Test-FieldMatches -Content $content -Field "GitHub security features:" -Pattern '"secret_scanning":\{"status":"enabled"\}' -FailureMessage "Secret scanning must be enabled."
Test-FieldMatches -Content $content -Field "GitHub security features:" -Pattern '"secret_scanning_push_protection":\{"status":"enabled"\}' -FailureMessage "Secret scanning push protection must be enabled."
Test-Contains -Content $content -Needle "Open security alerts: code_scanning_alerts=0, secret_scanning_alerts=0, dependabot_alerts=0" -FailureMessage "Open security alerts must all be zero."

$passFailFields = @(
    "Light mode empty states pass/fail:",
    "Dark mode empty states pass/fail:",
    "Goals pass/fail:",
    "Habits pass/fail:",
    "Lists/projects/tasks pass/fail:",
    "Review pass/fail:",
    "Nutrition pass/fail:",
    "Today pass/fail:",
    "Dense data pass/fail:",
    "Long text pass/fail:",
    "HealthKit pass/fail:",
    "Notifications pass/fail:",
    "Google Calendar pass/fail:",
    "Nutrition integration pass/fail:",
    "Relaunch persistence pass/fail:"
)

foreach ($field in $passFailFields) {
    Test-PassFailField -Content $content -Field $field
}

Test-PassFailField -Content $content -Field "Private CloudKit sync pass/fail/not available:"
Test-DefectLog -Content $content

$acceptedValue = Get-FieldValue -Content $content -Field "Accepted for V1:"
if ($acceptedValue -ne "yes") {
    Add-Failure "Accepted for V1 must be yes."
}

$reasonValue = Get-FieldValue -Content $content -Field "Reason:"
if ($reasonValue -match "not been executed|not executed|pending|todo|tbd") {
    Add-Failure "Acceptance decision reason still describes incomplete manual acceptance."
}

if ($script:failures.Count -gt 0) {
    Write-Output "V1 acceptance record is incomplete:"
    foreach ($failure in $script:failures) {
        Write-Output "- $failure"
    }
    exit 1
}

Write-Output "V1 acceptance record is complete."
