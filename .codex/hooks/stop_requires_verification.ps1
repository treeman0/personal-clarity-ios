. (Join-Path $PSScriptRoot "loop_config.ps1")

$hookInput = Get-CodexHookInput
$root = Get-ProjectRoot -InputData $hookInput.Data
$config = Get-LoopConfig -Root $root
$stateDir = Get-StateDir -Root $root
$blockReasons = @()

if (Get-LoopBool -Config $config -Names @("loop.verificationGate", "verificationGate") -Default $true) {
  $needsPath = Join-Path $stateDir "needs-verification.json"
  if (Test-Path -LiteralPath $needsPath) {
    $needs = Get-Item -LiteralPath $needsPath
    $verifiedPath = Join-Path $stateDir "last-verification.json"
    $waiverPath = Join-Path $stateDir "verification-waiver.md"

    $verifiedFresh = (Test-Path -LiteralPath $verifiedPath) -and ((Get-Item -LiteralPath $verifiedPath).LastWriteTimeUtc -gt $needs.LastWriteTimeUtc)
    $waiverFresh = (Test-Path -LiteralPath $waiverPath) -and ((Get-Item -LiteralPath $waiverPath).LastWriteTimeUtc -gt $needs.LastWriteTimeUtc)

    if (-not ($verifiedFresh -or $waiverFresh)) {
      $blockReasons += "Recent Codex edits have not been verified. Run focused tests or write .claude/state/verification-waiver.md with a concrete manual verification note."
    }
  }
}

$wikiMemory = Get-LoopBool -Config $config -Names @("loop.wikiMemory", "wikiMemory") -Default $true
$wikiGate = Get-LoopBool -Config $config -Names @("loop.wikiGate", "wikiGate") -Default $true
if ($wikiMemory -and $wikiGate) {
  $wikiNeedsPath = Join-Path $stateDir "needs-wiki-review.json"
  if (Test-Path -LiteralPath $wikiNeedsPath) {
    $wikiNeeds = Get-Item -LiteralPath $wikiNeedsPath
    $wikiUpdatedPath = Join-Path $stateDir "last-wiki-update.json"
    $wikiWaiverPath = Join-Path $stateDir "wiki-review-waiver.md"

    $wikiUpdatedFresh = (Test-Path -LiteralPath $wikiUpdatedPath) -and ((Get-Item -LiteralPath $wikiUpdatedPath).LastWriteTimeUtc -gt $wikiNeeds.LastWriteTimeUtc)
    $wikiWaiverFresh = (Test-Path -LiteralPath $wikiWaiverPath) -and ((Get-Item -LiteralPath $wikiWaiverPath).LastWriteTimeUtc -gt $wikiNeeds.LastWriteTimeUtc)

    if (-not ($wikiUpdatedFresh -or $wikiWaiverFresh)) {
      $blockReasons += "Recent Codex edits have not had a wiki review. Update wiki/ with durable knowledge, or write .claude/state/wiki-review-waiver.md explaining why no wiki update is needed."
    }
  }
}

if ($blockReasons.Count -eq 0) { exit 0 }

$out = @{
  decision = "block"
  reason = ($blockReasons -join " ")
}

$out | ConvertTo-Json -Depth 5 -Compress
exit 0
