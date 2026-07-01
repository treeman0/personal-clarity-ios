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
if ($joinedPaths -match '(^|\\)wiki\\' -or $joinedPaths -match '(^|\\)\.claude\\state\\') {
  exit 0
}

$lowSignalPatterns = @(
  '(^|\\)\.gitignore$',
  '(^|\\)\.gitattributes$',
  '(^|\\)package-lock\.json$',
  '(^|\\)pnpm-lock\.yaml$',
  '(^|\\)yarn\.lock$',
  '(^|\\)poetry\.lock$',
  '(^|\\)Cargo\.lock$',
  '(^|\\)go\.sum$',
  '\.log$',
  '\.tmp$',
  '\.bak$'
)

foreach ($pattern in $lowSignalPatterns) {
  if ($joinedPaths -match $pattern) {
    exit 0
  }
}

$stateDir = Join-Path $project ".claude/state"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

$marker = @{
  needsWikiReview = $true
  reason = "A non-wiki file was edited. Review whether durable project knowledge should be added to wiki/ before stopping."
  timestamp = (Get-Date).ToString("o")
}

$marker | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stateDir "needs-wiki-review.json") -Encoding UTF8
exit 0
