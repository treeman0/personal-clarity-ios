. (Join-Path $PSScriptRoot "loop_config.ps1")

$hookInput = Get-CodexHookInput
$root = Get-ProjectRoot -InputData $hookInput.Data
$config = Get-LoopConfig -Root $root
$stateDir = Get-StateDir -Root $root
$command = Get-ToolCommand -InputData $hookInput.Data

if (-not [string]::IsNullOrWhiteSpace($command) -and (Get-LoopBool -Config $config -Names @("loop.verificationGate", "verificationGate") -Default $true)) {
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

  if ($looksLikeTest) {
    $exitCode = $null
    if ($hookInput.Data -and $hookInput.Data.tool_response) {
      if ($null -ne $hookInput.Data.tool_response.exit_code) { $exitCode = [int]$hookInput.Data.tool_response.exit_code }
      elseif ($null -ne $hookInput.Data.tool_response.exitCode) { $exitCode = [int]$hookInput.Data.tool_response.exitCode }
    }

    if ($null -ne $exitCode -and $exitCode -eq 0) {
      $verification = @{
        verified = $true
        command = $command
        timestamp = (Get-Date).ToString("o")
        runtime = "codex"
        note = "Marked verified because a recognized test command reported exit code 0 in hook input."
      }
      $verification | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stateDir "last-verification.json") -Encoding UTF8
      $needsPath = Join-Path $stateDir "needs-verification.json"
      if (Test-Path -LiteralPath $needsPath) {
        Remove-Item -LiteralPath $needsPath -Force
      }
    }
  }
}

if (Get-LoopBool -Config $config -Names @("loop.skillTracking", "skillTracking") -Default $true) {
  $tracker = Join-Path $root ".claude/hooks/track_skill_opportunities.ps1"
  if (Test-Path -LiteralPath $tracker -PathType Leaf) {
    $temp = Join-Path ([IO.Path]::GetTempPath()) ("codex-hook-" + [guid]::NewGuid().ToString("N") + ".json")
    try {
      Set-Content -LiteralPath $temp -Value $hookInput.Raw -Encoding UTF8
      Get-Content -LiteralPath $temp -Raw | powershell -NoProfile -ExecutionPolicy Bypass -File $tracker
    } finally {
      if (Test-Path -LiteralPath $temp) {
        Remove-Item -LiteralPath $temp -Force
      }
    }
  }
}

exit 0
