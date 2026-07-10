#!/usr/bin/env bash
set -euo pipefail

device_id=""
team_id=""
evidence_path=""

usage() {
  cat <<'EOF'
Usage: bash scripts/install_v2_local_device.sh --device-id ID --team-id ID [--evidence-path PATH]

Builds, signs, installs, and launches the no-cost ClarityHubLocal target on a connected iPhone.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device-id)
      device_id="${2:-}"
      shift 2
      ;;
    --team-id)
      team_id="${2:-}"
      shift 2
      ;;
    --evidence-path)
      evidence_path="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$device_id" || -z "$team_id" ]]; then
  usage >&2
  exit 2
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer requires macOS with Xcode." >&2
  exit 1
fi

for command in xcodebuild xcrun xcodegen git python3; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command not found: $command" >&2
    exit 1
  fi
done

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

sha=$(git rev-parse HEAD)
short_sha=$(git rev-parse --short HEAD)
if [[ -z "$evidence_path" ]]; then
  evidence_path="$root/docs/evidence/v2-local-device-$short_sha.log"
elif [[ "$evidence_path" != /* ]]; then
  evidence_path="$root/$evidence_path"
fi
mkdir -p "$(dirname "$evidence_path")"
exec > >(tee "$evidence_path") 2>&1

echo "ClarityHub V2 Local device installation"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Candidate commit: $sha"
echo "Device ID: $device_id"
echo "Personal Team ID: $team_id"
echo "Bundle ID: com.treeman0.ClarityHub.Personal"

status=$(git status --porcelain -- . \
  ':(exclude)docs/V1_ACCEPTANCE_RECORD.md' \
  ':(exclude)docs/V2_LOCAL_ACCEPTANCE_RECORD.md' \
  ':(exclude)docs/evidence/**')
if [[ -n "$status" ]]; then
  echo "Refusing device evidence from a dirty candidate:" >&2
  echo "$status" >&2
  exit 1
fi

upstream=$(git rev-parse '@{upstream}' 2>/dev/null || true)
if [[ -z "$upstream" || "$upstream" != "$sha" ]]; then
  echo "Refusing device evidence until HEAD is pushed to its upstream branch." >&2
  echo "HEAD: $sha" >&2
  echo "Upstream: ${upstream:-not configured}" >&2
  exit 1
fi

echo "Local/remote status: clean and synced at $sha"
bash scripts/verify-v2-config.sh
xcodebuild -version
xcrun devicectl device info details --device "$device_id"
xcodegen generate

derived_data=$(mktemp -d "${TMPDIR:-/tmp}/clarityhub-v2-local.XXXXXX")
trap 'rm -rf "$derived_data"' EXIT

xcodebuild build \
  -project ClarityHub.xcodeproj \
  -scheme ClarityHubLocal \
  -configuration Debug \
  -destination "id=$device_id" \
  -derivedDataPath "$derived_data" \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="$team_id"

app_path="$derived_data/Build/Products/Debug-iphoneos/ClarityHubLocal.app"
if [[ ! -d "$app_path" ]]; then
  echo "Built app was not found at $app_path" >&2
  exit 1
fi

xcrun devicectl device install app "$app_path" --device "$device_id"
xcrun devicectl device process launch --device "$device_id" com.treeman0.ClarityHub.Personal

echo "Local build pass/fail: pass"
echo "Install and launch pass/fail: pass"
echo "Evidence log: $evidence_path"
echo "Complete docs/V2_LOCAL_ACCEPTANCE.md on the unlocked iPhone before accepting V2 Local."
