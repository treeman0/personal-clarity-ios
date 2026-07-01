param(
  [string]$TargetPath = ".",

  [string]$Stamp,

  [switch]$DryRun,

  [switch]$Force
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path -LiteralPath $TargetPath).Path
$base = Join-Path $root "wiki/inbox/replaced-by-install"

if (-not (Test-Path -LiteralPath $base)) {
  throw "No preserved replaced files found at $base"
}

if ([string]::IsNullOrWhiteSpace($Stamp)) {
  $stampDir = Get-ChildItem -LiteralPath $base -Directory |
    Sort-Object Name -Descending |
    Select-Object -First 1
} else {
  $stampDir = Get-Item -LiteralPath (Join-Path $base $Stamp)
}

if (-not $stampDir) {
  throw "No preserved-doc timestamp directory found."
}

$files = Get-ChildItem -LiteralPath $stampDir.FullName -Recurse -File
if (-not $files) {
  Write-Host "No files to restore from $($stampDir.FullName)"
  exit 0
}

Write-Host "Restore source: $($stampDir.FullName)"
Write-Host "Target root: $root"

foreach ($file in $files) {
  $relative = $file.FullName.Substring($stampDir.FullName.Length).TrimStart('\', '/')
  $target = Join-Path $root $relative
  $exists = Test-Path -LiteralPath $target
  $action = if ($exists) { if ($Force) { "overwrite" } else { "skip-existing" } } else { "restore" }
  Write-Host ("- {0}: {1}" -f $action, $relative)

  if ($DryRun -or ($exists -and -not $Force)) {
    continue
  }

  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
  Copy-Item -LiteralPath $file.FullName -Destination $target -Force
  $sourceItem = Get-Item -LiteralPath $file.FullName
  $targetItem = Get-Item -LiteralPath $target
  $targetItem.LastWriteTimeUtc = $sourceItem.LastWriteTimeUtc
}

if ($DryRun) {
  Write-Host "Dry run only. Re-run without -DryRun to restore."
}

