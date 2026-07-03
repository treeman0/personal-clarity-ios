param(
    [string] $Path = "docs\V1_ACCEPTANCE_RECORD.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-FieldValue {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,
        [Parameter(Mandatory = $true)]
        [string] $Field
    )

    $escapedField = [regex]::Escape($Field)
    $match = [regex]::Match($Content, "(?m)^$escapedField[ \t]*(.*)$")
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups[1].Value.Trim()
}

function Get-FieldValues {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,
        [Parameter(Mandatory = $true)]
        [string] $Field
    )

    $escapedField = [regex]::Escape($Field)
    return [regex]::Matches($Content, "(?m)^$escapedField[ \t]*(.*)$") | ForEach-Object {
        $_.Groups[1].Value.Trim()
    }
}

function Add-Gap {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Section,
        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    $script:gaps.Add([pscustomobject]@{
        Section = $Section
        Message = $Message
    }) | Out-Null
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
$script:gaps = [System.Collections.Generic.List[object]]::new()

$preflightFields = @(
    "Tester:",
    "Device or simulator:",
    "iOS version:",
    "Apple ID / iCloud state:",
    "HealthKit data state:"
)

foreach ($field in $preflightFields) {
    $value = Get-FieldValue -Content $content -Field $field
    if ([string]::IsNullOrWhiteSpace($value)) {
        Add-Gap -Section "Preflight" -Message "$field is empty."
    }
}

$googleValue = Get-FieldValue -Content $content -Field "Google OAuth client ID available:"
if ($googleValue -notin @("yes", "no")) {
    Add-Gap -Section "Preflight" -Message "Google OAuth client ID available: must be yes or no."
}

$calAIValue = Get-FieldValue -Content $content -Field "Cal AI writes nutrition to Apple Health:"
if ($calAIValue -notin @("yes", "no", "unknown")) {
    Add-Gap -Section "Preflight" -Message "Cal AI writes nutrition to Apple Health: must be yes, no, or unknown."
}

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
    "Relaunch persistence pass/fail:",
    "Private CloudKit sync pass/fail/not available:"
)

foreach ($field in $passFailFields) {
    $value = Get-FieldValue -Content $content -Field $field
    if ($value -notin @("pass", "fail")) {
        Add-Gap -Section "Manual pass/fail" -Message "$field must be pass or fail."
    }
}

foreach ($field in @("Notes:", "Screenshots captured:")) {
    $values = @(Get-FieldValues -Content $content -Field $field)
    if ($values.Count -eq 0) {
        Add-Gap -Section "Evidence" -Message "$field is missing."
        continue
    }

    $index = 0
    foreach ($value in $values) {
        $index += 1
        if ([string]::IsNullOrWhiteSpace($value)) {
            Add-Gap -Section "Evidence" -Message "$field occurrence $index is empty."
        } elseif ($field -eq "Screenshots captured:" -and $value.ToLowerInvariant() -in @("no", "none", "n/a", "na", "not captured", "todo", "tbd")) {
            Add-Gap -Section "Evidence" -Message "$field occurrence $index must capture screenshot evidence."
        }
    }
}

if ($content.Contains("| A-001 |  |  |  |  | fix/defer |")) {
    Add-Gap -Section "Defects" -Message "Replace or remove the placeholder A-001 defect row."
}

$acceptedValue = Get-FieldValue -Content $content -Field "Accepted for V1:"
if ($acceptedValue -ne "yes") {
    Add-Gap -Section "Decision" -Message "Accepted for V1: must be yes after all evidence is complete."
}

$reviewerValue = Get-FieldValue -Content $content -Field "Reviewer:"
if ([string]::IsNullOrWhiteSpace($reviewerValue)) {
    Add-Gap -Section "Decision" -Message "Reviewer: is empty."
}

Write-Output "V1 acceptance gaps for $recordPath"
Write-Output ""

if ($script:gaps.Count -eq 0) {
    Write-Output "No obvious manual gaps found. Run .\scripts\test-v1-acceptance-record.ps1 -Path $Path for final validation."
    exit 0
}

$script:gaps |
    Group-Object Section |
    ForEach-Object {
        Write-Output "## $($_.Name)"
        foreach ($gap in $_.Group) {
            Write-Output "- $($gap.Message)"
        }
        Write-Output ""
    }

Write-Output "$($script:gaps.Count) gap(s) remain before V1 can be accepted."
exit 1
