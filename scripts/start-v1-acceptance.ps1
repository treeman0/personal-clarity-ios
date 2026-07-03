param(
    [string] $OutputPath = "docs\V1_ACCEPTANCE_RECORD.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$resolvedOutputPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
} else {
    Join-Path $root $OutputPath
}

Push-Location $root
try {
    $gitStatus = (git status --short --branch -- . ':(exclude)docs/V1_ACCEPTANCE_RECORD.md' | Out-String).Trim()
    if ($gitStatus -notmatch "^## main\.\.\.origin/main\s*$") {
        Write-Output "Warning: final V1 acceptance should start from a clean, pushed candidate."
        Write-Output "Current git status excluding docs\V1_ACCEPTANCE_RECORD.md:"
        Write-Output $gitStatus
        Write-Output ""
    }

    & (Join-Path $PSScriptRoot "new-v1-acceptance-record.ps1") -OutputPath $resolvedOutputPath

    Write-Output ""
    Write-Output "Running acceptance validator. It is expected to fail until manual fields are completed."

    $validatorOutput = & (Join-Path $PSScriptRoot "test-v1-acceptance-record.ps1") -Path $resolvedOutputPath 2>&1
    $validatorExitCode = $LASTEXITCODE
    $validatorOutput | Write-Output

    Write-Output ""
    if ($validatorExitCode -eq 0) {
        Write-Output "Acceptance record is complete and valid."
    } else {
        Write-Output "Acceptance record created but not complete yet."
        Write-Output "Next steps:"
        Write-Output "1. If this warning showed a dirty or unpushed worktree, commit/push those changes and rerun this starter before final acceptance."
        Write-Output "2. Execute docs\V1_ACCEPTANCE_RUNBOOK.md on iPhone or iOS Simulator."
        Write-Output "3. Fill every pass/fail, notes, screenshot, defect, reviewer, and decision field in $OutputPath."
        Write-Output "4. Rerun .\scripts\test-v1-acceptance-record.ps1 -Path $OutputPath."
        Write-Output "5. Only call V1 complete after the validator passes, loop status is clean, and the current release-candidate CI is green."
    }
} finally {
    Pop-Location
}

exit 0
