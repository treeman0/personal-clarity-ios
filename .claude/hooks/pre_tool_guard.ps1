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

$blocked = @(
  @{ Pattern = '(?i)\brm\s+-[a-z]*(rf|fr)[a-z]*\s+(/|~|\$HOME|\*)'; Reason = 'Recursive deletion of a broad path is blocked.' },
  @{ Pattern = '(?i)\bRemove-Item\b.*\b-Recurse\b.*\b-Force\b.*(\s[A-Z]:\\|\s\\|\s\*)'; Reason = 'Forced recursive deletion of a broad path is blocked.' },
  @{ Pattern = '(?i)\bgit\s+reset\s+--hard\b'; Reason = 'git reset --hard is blocked by project policy.' },
  @{ Pattern = '(?i)\bgit\s+clean\s+-[a-z]*[fdx][a-z]*\b'; Reason = 'git clean with destructive flags is blocked by project policy.' },
  @{ Pattern = '(?i)\bterraform\s+(apply|destroy)\b'; Reason = 'Terraform state-changing commands require explicit human approval outside the loop.' },
  @{ Pattern = '(?i)\bkubectl\s+delete\b'; Reason = 'Kubernetes delete commands require explicit human approval outside the loop.' },
  @{ Pattern = '(?i)\bdocker\s+system\s+prune\b'; Reason = 'Docker system prune is blocked by project policy.' },
  @{ Pattern = '(?i)\b(powershell|pwsh)(\.exe)?\b.*\s-e(nc|ncodedcommand)?\b'; Reason = 'Encoded PowerShell commands are blocked by project policy.' },
  @{ Pattern = '(?i)\b(curl|curl\.exe|wget|Invoke-WebRequest|Invoke-RestMethod|iwr|irm)\b.*\|\s*(sh|bash|pwsh|powershell|powershell\.exe|iex|Invoke-Expression)'; Reason = 'Piping downloaded content into an interpreter is blocked.' }
)

foreach ($rule in $blocked) {
  if ($command -match $rule.Pattern) {
    $out = @{
      hookSpecificOutput = @{
        hookEventName = "PreToolUse"
        permissionDecision = "deny"
        permissionDecisionReason = $rule.Reason
      }
    }
    $out | ConvertTo-Json -Depth 5 -Compress
    exit 0
  }
}

exit 0

