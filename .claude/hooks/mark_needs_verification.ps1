$ErrorActionPreference = "Stop"

$project = $env:CLAUDE_PROJECT_DIR
if ([string]::IsNullOrWhiteSpace($project)) {
  $raw = [Console]::In.ReadToEnd()
  try {
    $inputData = $raw | ConvertFrom-Json
    $project = [string]$inputData.cwd
  } catch {
    $project = (Get-Location).Path
  }
}

$stateDir = Join-Path $project ".claude/state"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

$marker = @{
  needsVerification = $true
  reason = "A file was edited or written after the latest verification."
  timestamp = (Get-Date).ToString("o")
}

$marker | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stateDir "needs-verification.json") -Encoding UTF8
exit 0

