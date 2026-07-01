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

$testPatterns = @(
  '(?i)\bnpm\s+(run\s+)?test\b',
  '(?i)\bpnpm\s+(run\s+)?test\b',
  '(?i)\byarn\s+test\b',
  '(?i)\bpytest\b',
  '(?i)\bpython\s+-m\s+pytest\b',
  '(?i)\bdotnet\s+test\b',
  '(?i)\bgo\s+test\b',
  '(?i)\bcargo\s+test\b',
  '(?i)\bmvn\s+test\b',
  '(?i)\bgradle\s+test\b',
  '(?i)\bmake\s+test\b'
)

$looksLikeTest = $false
foreach ($pattern in $testPatterns) {
  if ($command -match $pattern) {
    $looksLikeTest = $true
    break
  }
}

if (-not $looksLikeTest) { exit 0 }

$exitCode = $null
if ($inputData.tool_response) {
  if ($null -ne $inputData.tool_response.exit_code) { $exitCode = [int]$inputData.tool_response.exit_code }
  elseif ($null -ne $inputData.tool_response.exitCode) { $exitCode = [int]$inputData.tool_response.exitCode }
}

if ($null -eq $exitCode -or $exitCode -ne 0) { exit 0 }

$project = $env:CLAUDE_PROJECT_DIR
if ([string]::IsNullOrWhiteSpace($project) -and $inputData.cwd) {
  $project = [string]$inputData.cwd
}
if ([string]::IsNullOrWhiteSpace($project)) {
  $project = (Get-Location).Path
}

$stateDir = Join-Path $project ".claude/state"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

$verification = @{
  verified = $true
  command = $command
  timestamp = (Get-Date).ToString("o")
  note = "Marked verified because a recognized test command reported exit code 0 in hook input."
}

$verification | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stateDir "last-verification.json") -Encoding UTF8
$needsPath = Join-Path $stateDir "needs-verification.json"
if (Test-Path -LiteralPath $needsPath) {
  Remove-Item -LiteralPath $needsPath -Force
}

exit 0

