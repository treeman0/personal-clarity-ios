$ErrorActionPreference = "Stop"

function Get-CodexHookInput {
  $raw = [Console]::In.ReadToEnd()
  $data = $null
  if (-not [string]::IsNullOrWhiteSpace($raw)) {
    try {
      $data = $raw | ConvertFrom-Json
    } catch {
      $data = $null
    }
  }

  [pscustomobject]@{
    Raw = $raw
    Data = $data
  }
}

function Get-ProjectRoot {
  param([object]$InputData)

  if ($InputData -and $InputData.cwd) {
    return [string]$InputData.cwd
  }

  try {
    $gitRoot = (& git rev-parse --show-toplevel 2>$null)
    if (-not [string]::IsNullOrWhiteSpace($gitRoot)) {
      return [string]$gitRoot
    }
  } catch {
  }

  return (Get-Location).Path
}

function Get-PathValue {
  param(
    [object]$Object,
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if ($null -eq $Object) { return $null }
  $current = $Object
  foreach ($part in ($Path -split '\.')) {
    if ($null -eq $current) { return $null }
    $property = $current.PSObject.Properties[$part]
    if ($null -eq $property) { return $null }
    $current = $property.Value
  }
  return $current
}

function Get-LoopConfig {
  param([Parameter(Mandatory = $true)][string]$Root)

  $configPath = Join-Path $Root ".claude-loop.json"
  if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    return $null
  }

  try {
    return (Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json)
  } catch {
    return $null
  }
}

function Get-LoopBool {
  param(
    [object]$Config,
    [Parameter(Mandatory = $true)]
    [string[]]$Names,
    [Parameter(Mandatory = $true)]
    [bool]$Default
  )

  foreach ($name in $Names) {
    $value = Get-PathValue -Object $Config -Path $name
    if ($null -ne $value) {
      if ($value -is [bool]) { return $value }
      try { return [bool]::Parse([string]$value) } catch { return $Default }
    }
  }

  return $Default
}

function Get-StateDir {
  param([Parameter(Mandatory = $true)][string]$Root)

  $stateDir = Join-Path $Root ".claude/state"
  New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
  return $stateDir
}

function Get-ToolCommand {
  param([object]$InputData)

  if ($InputData -and $InputData.tool_input -and $InputData.tool_input.command) {
    return [string]$InputData.tool_input.command
  }
  return ""
}

function Get-ToolPaths {
  param([object]$InputData)

  $paths = @()
  if ($InputData -and $InputData.tool_input) {
    foreach ($name in @("file_path", "path")) {
      if ($InputData.tool_input.PSObject.Properties.Name -contains $name) {
        $paths += [string]$InputData.tool_input.$name
      }
    }
  }
  return $paths
}
