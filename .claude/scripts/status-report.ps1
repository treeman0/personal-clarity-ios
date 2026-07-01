param(
  [string]$TargetPath = "."
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path -LiteralPath $TargetPath).Path
$stateDir = Join-Path $root ".claude/state"
$settingsPath = Join-Path $root ".claude/settings.json"
$configPath = Join-Path $root ".claude-loop.json"

function Test-JsonPath {
  param([string]$Path)
  return (Test-Path -LiteralPath $Path -PathType Leaf)
}

function Count-Files {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return 0 }
  return @(Get-ChildItem -LiteralPath $Path -Recurse -File).Count
}

function Get-ConfigValue {
  param(
    [object]$Config,
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [string]$Default = "unknown"
  )

  if ($null -eq $Config) { return $Default }
  $current = $Config
  foreach ($part in ($Path -split '\.')) {
    if ($null -eq $current) { return $Default }
    $property = $current.PSObject.Properties[$part]
    if ($null -eq $property) { return $Default }
    $current = $property.Value
  }
  if ($null -eq $current) { return $Default }
  return [string]$current
}

$pendingVerification = Test-JsonPath (Join-Path $stateDir "needs-verification.json")
$pendingWikiReview = Test-JsonPath (Join-Path $stateDir "needs-wiki-review.json")
$verificationWaiver = Test-JsonPath (Join-Path $stateDir "verification-waiver.md")
$wikiWaiver = Test-JsonPath (Join-Path $stateDir "wiki-review-waiver.md")

$skillCandidateCount = 0
$skillStatePath = Join-Path $stateDir "skill-opportunities.json"
if (Test-Path -LiteralPath $skillStatePath) {
  try {
    $skillState = Get-Content -LiteralPath $skillStatePath -Raw | ConvertFrom-Json
    $skillCandidateCount = @($skillState.commands | Where-Object { $_.status -eq "candidate" }).Count
  } catch {
    $skillCandidateCount = -1
  }
}

$preservedFileRoot = Join-Path $root "wiki/inbox/replaced-by-install"
$preservedFileCount = Count-Files -Path $preservedFileRoot
$proposalCount = Count-Files -Path (Join-Path $root ".claude/skills/_proposals")

$migrationIndex = Test-JsonPath (Join-Path $root "wiki/sources/migrated-markdown-index.md")
$replacedIndex = Test-JsonPath (Join-Path $root "wiki/sources/replaced-markdown-index.md")
$linkSuggestions = Test-JsonPath (Join-Path $root "wiki/sources/link-rewrite-suggestions.md")

$wikiGate = "unknown"
$skillTracking = "unknown"
$configProfile = "missing"
$configKitVersion = "unknown"
$configMarkdownMigration = "unknown"
$configForceRequiresIntent = "unknown"
$configClaudeRuntime = "unknown"
$configCodexRuntime = "unknown"
$configTdd = "unknown"
$configVerificationGate = "unknown"
$configWikiMemory = "unknown"
$configWikiGate = "unknown"
$configSkillTracking = "unknown"
$configCodeReview = "unknown"
$configSafetyGuard = "unknown"
$configStatusReport = "unknown"
if (Test-Path -LiteralPath $settingsPath) {
  $settingsText = Get-Content -LiteralPath $settingsPath -Raw
  $wikiGate = if ($settingsText -match "mark_wiki_review_needed.ps1") { "enabled" } else { "disabled" }
  $skillTracking = if ($settingsText -match "track_skill_opportunities.ps1") { "enabled" } else { "disabled" }
}
if (Test-Path -LiteralPath $configPath) {
  try {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    $configProfile = if ($config.profile) { [string]$config.profile } else { "unspecified" }
    $configKitVersion = if ($config.kitVersion) { [string]$config.kitVersion } else { "unspecified" }
    $configMarkdownMigration = if ($config.markdownMigration) { [string]$config.markdownMigration } else { Get-ConfigValue -Config $config -Path "migration.markdown" -Default "unspecified" }
    $configForceRequiresIntent = if ($null -ne $config.forceRequiresIntent) { [string]$config.forceRequiresIntent } else { Get-ConfigValue -Config $config -Path "safety.forceRequiresIntent" -Default "unspecified" }
    $configClaudeRuntime = Get-ConfigValue -Config $config -Path "runtimes.claudeCode" -Default "unspecified"
    $configCodexRuntime = Get-ConfigValue -Config $config -Path "runtimes.codex" -Default "unspecified"
    $configTdd = Get-ConfigValue -Config $config -Path "loop.tdd" -Default "unspecified"
    $configVerificationGate = Get-ConfigValue -Config $config -Path "loop.verificationGate" -Default "unspecified"
    $configWikiMemory = Get-ConfigValue -Config $config -Path "loop.wikiMemory" -Default "unspecified"
    $configWikiGate = Get-ConfigValue -Config $config -Path "loop.wikiGate" -Default "unspecified"
    $configSkillTracking = Get-ConfigValue -Config $config -Path "loop.skillTracking" -Default "unspecified"
    $configCodeReview = Get-ConfigValue -Config $config -Path "loop.codeReview" -Default "unspecified"
    $configSafetyGuard = Get-ConfigValue -Config $config -Path "loop.safetyGuard" -Default "unspecified"
    $configStatusReport = Get-ConfigValue -Config $config -Path "loop.statusReport" -Default "unspecified"
  } catch {
    $configProfile = "invalid-json"
    $configKitVersion = "invalid-json"
    $configMarkdownMigration = "invalid-json"
    $configForceRequiresIntent = "invalid-json"
    $configClaudeRuntime = "invalid-json"
    $configCodexRuntime = "invalid-json"
    $configTdd = "invalid-json"
    $configVerificationGate = "invalid-json"
    $configWikiMemory = "invalid-json"
    $configWikiGate = "invalid-json"
    $configSkillTracking = "invalid-json"
    $configCodeReview = "invalid-json"
    $configSafetyGuard = "invalid-json"
    $configStatusReport = "invalid-json"
  }
}

Write-Host "# Claude/Codex Loop Status"
Write-Host ""
Write-Host "Target: $root"
Write-Host ""
Write-Host "## Gates"
Write-Host "- pending verification: $pendingVerification"
Write-Host "- pending wiki review: $pendingWikiReview"
Write-Host "- verification waiver present: $verificationWaiver"
Write-Host "- wiki waiver present: $wikiWaiver"
Write-Host "- wiki gate: $wikiGate"
Write-Host "- skill tracking: $skillTracking"
Write-Host "- config profile: $configProfile"
Write-Host "- config kit version: $configKitVersion"
Write-Host "- config claude runtime: $configClaudeRuntime"
Write-Host "- config codex runtime: $configCodexRuntime"
Write-Host "- config tdd: $configTdd"
Write-Host "- config verification gate: $configVerificationGate"
Write-Host "- config wiki memory: $configWikiMemory"
Write-Host "- config wiki gate: $configWikiGate"
Write-Host "- config skill tracking: $configSkillTracking"
Write-Host "- config code review: $configCodeReview"
Write-Host "- config safety guard: $configSafetyGuard"
Write-Host "- config status report: $configStatusReport"
Write-Host "- config markdown migration: $configMarkdownMigration"
Write-Host "- config force requires intent: $configForceRequiresIntent"
Write-Host ""
Write-Host "## Skill Automation"
Write-Host "- skill candidates: $skillCandidateCount"
Write-Host "- proposed skill files: $proposalCount"
Write-Host ""
Write-Host "## Migration And Recovery"
Write-Host "- preserved replaced files: $preservedFileCount"
Write-Host "- migrated markdown index: $migrationIndex"
Write-Host "- replaced files index: $replacedIndex"
Write-Host "- link rewrite suggestions: $linkSuggestions"
Write-Host ""
Write-Host "## Suggested Next Actions"
if ($pendingVerification) { Write-Host "- Run focused verification or write .claude/state/verification-waiver.md." }
if ($pendingWikiReview) { Write-Host "- Update wiki/ or write .claude/state/wiki-review-waiver.md." }
if ($skillCandidateCount -gt 0) { Write-Host "- Run auto-skill-review for repeated workflow candidates." }
if ($preservedFileCount -gt 0) { Write-Host "- Review preserved files under wiki/inbox/replaced-by-install/." }
if ($linkSuggestions) { Write-Host "- Review wiki/sources/link-rewrite-suggestions.md." }
if (-not ($pendingVerification -or $pendingWikiReview -or $skillCandidateCount -gt 0 -or $preservedFileCount -gt 0 -or $linkSuggestions)) {
  Write-Host "- No immediate maintenance actions detected."
}
