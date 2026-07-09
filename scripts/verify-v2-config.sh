#!/usr/bin/env bash
set -euo pipefail

bash scripts/verify-release-config.sh

python_bin="python3"
if ! command -v "$python_bin" >/dev/null 2>&1; then
  python_bin="python"
fi

"$python_bin" - <<'PY'
import plistlib

with open("Sources/ClarityHubLocal/ClarityHubLocal.entitlements", "rb") as file:
    entitlements = plistlib.load(file)

expected = {"com.apple.developer.healthkit": True}
if entitlements != expected:
    raise SystemExit(f"Local entitlements must contain only HealthKit; found {entitlements}")

with open("Sources/ClarityHubLocal/Info.plist", "rb") as file:
    info = plistlib.load(file)

if "UIBackgroundModes" in info:
    raise SystemExit("Local Info.plist must not declare remote-notification background mode")
if "NSHealthUpdateUsageDescription" in info:
    raise SystemExit("Local mode must remain read-only for HealthKit")

schemes = info["CFBundleURLTypes"][0]["CFBundleURLSchemes"]
if schemes != ["com.treeman0.ClarityHub.Personal"]:
    raise SystemExit(f"Unexpected Local OAuth callback schemes: {schemes}")
PY

grep -F "PRODUCT_BUNDLE_IDENTIFIER: com.treeman0.ClarityHub.Personal" project.yml >/dev/null
grep -F "CODE_SIGN_ENTITLEMENTS: Sources/ClarityHubLocal/ClarityHubLocal.entitlements" project.yml >/dev/null
grep -F 'SWIFT_ACTIVE_COMPILATION_CONDITIONS: "$(inherited) CLARITYHUB_LOCAL"' project.yml >/dev/null
grep -F "ClarityHubLocalAppTests:" project.yml >/dev/null
grep -F "return .disabled" Sources/ClarityHubApp/Configuration/ClarityHubBuildConfiguration.swift >/dev/null

echo "V2 Cloud and Local configurations verified."
