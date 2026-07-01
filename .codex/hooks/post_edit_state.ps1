. (Join-Path $PSScriptRoot "loop_config.ps1")

$hookInput = Get-CodexHookInput
$root = Get-ProjectRoot -InputData $hookInput.Data
$config = Get-LoopConfig -Root $root
$stateDir = Get-StateDir -Root $root

if (Get-LoopBool -Config $config -Names @("loop.verificationGate", "verificationGate") -Default $true) {
  $marker = @{
    needsVerification = $true
    reason = "Codex edited or wrote files after the latest verification."
    timestamp = (Get-Date).ToString("o")
    runtime = "codex"
  }
  $marker | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stateDir "needs-verification.json") -Encoding UTF8
}

$wikiMemory = Get-LoopBool -Config $config -Names @("loop.wikiMemory", "wikiMemory") -Default $true
$wikiGate = Get-LoopBool -Config $config -Names @("loop.wikiGate", "wikiGate") -Default $true
if (-not ($wikiMemory -and $wikiGate)) { exit 0 }

$paths = Get-ToolPaths -InputData $hookInput.Data
$joinedPaths = ($paths -join "`n").Replace("/", "\")

if (-not [string]::IsNullOrWhiteSpace($joinedPaths)) {
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
}

$marker = @{
  needsWikiReview = $true
  reason = "Codex edited non-wiki files. Review whether durable project knowledge should be added to wiki/ before stopping."
  timestamp = (Get-Date).ToString("o")
  runtime = "codex"
}

$marker | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stateDir "needs-wiki-review.json") -Encoding UTF8
exit 0
