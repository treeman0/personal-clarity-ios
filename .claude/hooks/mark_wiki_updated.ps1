$ErrorActionPreference = "Stop"

$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

try {
  $inputData = $raw | ConvertFrom-Json
} catch {
  exit 0
}

$project = $env:CLAUDE_PROJECT_DIR
if ([string]::IsNullOrWhiteSpace($project) -and $inputData.cwd) {
  $project = [string]$inputData.cwd
}
if ([string]::IsNullOrWhiteSpace($project)) {
  $project = (Get-Location).Path
}

$candidatePaths = @()
if ($inputData.tool_input) {
  foreach ($name in @("file_path", "path")) {
    if ($inputData.tool_input.PSObject.Properties.Name -contains $name) {
      $candidatePaths += [string]$inputData.tool_input.$name
    }
  }
}

$joinedPaths = ($candidatePaths -join "`n").Replace("/", "\")
if ($joinedPaths -notmatch '(^|\\)wiki\\') {
  exit 0
}

$stateDir = Join-Path $project ".claude/state"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

$updated = @{
  wikiUpdated = $true
  timestamp = (Get-Date).ToString("o")
  note = "Marked updated because a wiki/ file was edited."
}

$updated | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stateDir "last-wiki-update.json") -Encoding UTF8
$needsPath = Join-Path $stateDir "needs-wiki-review.json"
if (Test-Path -LiteralPath $needsPath) {
  Remove-Item -LiteralPath $needsPath -Force
}

exit 0

