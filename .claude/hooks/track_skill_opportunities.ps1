$ErrorActionPreference = "Stop"

$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

try {
  $inputData = $raw | ConvertFrom-Json
} catch {
  exit 0
}

$command = ""
if ($inputData.tool_input -and $inputData.tool_input.command) {
  $command = [string]$inputData.tool_input.command
}

if ([string]::IsNullOrWhiteSpace($command)) { exit 0 }

function Redact-Command {
  param([Parameter(Mandatory = $true)][string]$Value)

  $redacted = $Value
  $redacted = $redacted -replace '(?i)\b([A-Z0-9_]*(SECRET|TOKEN|KEY|PASSWORD)[A-Z0-9_]*=)("[^"]*"|''[^'']*''|\S+)', '$1<redacted>'
  $redacted = $redacted -replace '(?i)(//registry\.npmjs\.org/:_authToken\s+)("[^"]*"|''[^'']*''|\S+)', '$1<redacted>'
  $redacted = $redacted -replace '(?i)(//registry\.npmjs\.org/:_authToken=)("[^"]*"|''[^'']*''|\S+)', '$1<redacted>'
  $redacted = $redacted -replace '(?i)(--?(api[-_]?key|token|password|passwd|secret|client[-_]?secret|access[-_]?token)(=|\s+))("[^"]*"|''[^'']*''|\S+)', '$1<redacted>'
  $redacted = $redacted -replace '(?i)\b(api[-_]?key|token|password|passwd|secret|client[-_]?secret|access[-_]?token)=("[^"]*"|''[^'']*''|\S+)', '$1=<redacted>'
  $redacted = $redacted -replace '(?i)(Authorization:\s*Bearer\s+)[A-Za-z0-9._~+/=-]+', '$1<redacted>'
  $redacted = $redacted -replace '\b(gho|ghp|github_pat|sk-[A-Za-z0-9]{8})[A-Za-z0-9_=\-]{12,}\b', '<redacted-token>'
  $redacted = $redacted -replace '(?i)\b[A-Za-z0-9_-]*(SECRET|TOKEN|PASSWORD|KEY)[A-Za-z0-9_-]{6,}\b', '<redacted-token>'
  $redacted = $redacted -replace '\b[A-Za-z0-9+/]{32,}={0,2}\b', '<redacted-blob>'
  return $redacted
}

$redactedCommand = Redact-Command -Value $command
$normalized = $redactedCommand.Trim()
$normalized = $normalized -replace '\s+', ' '
$normalized = $normalized -replace '"[^"]{12,}"', '"<arg>"'
$normalized = $normalized -replace "'[^']{12,}'", "'<arg>'"
$normalized = $normalized -replace '[A-Za-z]:\\[^\s]+', '<path>'
$normalized = $normalized -replace '\b\d{4,}\b', '<num>'

$ignored = @(
  'git status',
  'git diff',
  'git log',
  'Get-ChildItem',
  'Get-Content'
)

foreach ($prefix in $ignored) {
  if ($normalized.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    exit 0
  }
}

$project = $env:CLAUDE_PROJECT_DIR
if ([string]::IsNullOrWhiteSpace($project) -and $inputData.cwd) {
  $project = [string]$inputData.cwd
}
if ([string]::IsNullOrWhiteSpace($project)) {
  $project = (Get-Location).Path
}

$stateDir = Join-Path $project ".claude/state"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
$path = Join-Path $stateDir "skill-opportunities.json"

$state = @{
  updatedAt = (Get-Date).ToString("o")
  commands = @()
}

if (Test-Path -LiteralPath $path) {
  try {
    $existing = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    if ($existing.commands) {
      $state.commands = @($existing.commands)
    }
  } catch {
    $state.commands = @()
  }
}

$match = $null
foreach ($item in $state.commands) {
  if ($item.normalized -eq $normalized) {
    $match = $item
    break
  }
}

if ($match) {
  $match.count = [int]$match.count + 1
  $match.lastSeen = (Get-Date).ToString("o")
  $match.latestExample = $redactedCommand
} else {
  $state.commands += [pscustomobject]@{
    normalized = $normalized
    count = 1
    firstSeen = (Get-Date).ToString("o")
    lastSeen = (Get-Date).ToString("o")
    latestExample = $redactedCommand
    status = "observing"
  }
}

foreach ($item in $state.commands) {
  if ([int]$item.count -ge 3 -and $item.status -eq "observing") {
    $item.status = "candidate"
  }
}

$state.updatedAt = (Get-Date).ToString("o")
$state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $path -Encoding UTF8
exit 0
