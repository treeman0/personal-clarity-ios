#!/usr/bin/env bash
set -euo pipefail

expected_container="iCloud.com.treeman0.ClarityHub"
entitlements="Sources/ClarityHubApp/ClarityHub.entitlements"
info_plist="Sources/ClarityHubApp/Info.plist"
privacy_manifest="Sources/ClarityHubApp/PrivacyInfo.xcprivacy"
model_factory="Sources/ClarityHubApp/Persistence/ClarityHubModelContainerFactory.swift"
project_config="project.yml"
ios_ci_workflow=".github/workflows/ios-ci.yml"
codeql_workflow=".github/workflows/codeql.yml"
expected_google_callback_scheme="com.treeman0.ClarityHub"

python_bin="python3"
if ! command -v "$python_bin" >/dev/null 2>&1; then
  python_bin="python"
fi

read_plist_value() {
  "$python_bin" - "$1" "$2" "$3" <<'PY'
import plistlib
import sys

path, key, index = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "rb") as file:
    value = plistlib.load(file)[key]

if index != "":
    for part in index.split("."):
        if isinstance(value, list):
            value = value[int(part)]
        else:
            value = value[part]

if isinstance(value, bool):
    print(str(value).lower())
else:
    print(value)
PY
}

actual_container=$(read_plist_value "$entitlements" "com.apple.developer.icloud-container-identifiers" "0")
if [[ "$actual_container" != "$expected_container" ]]; then
  echo "Expected iCloud container $expected_container, found $actual_container" >&2
  exit 1
fi

cloudkit_service=$(read_plist_value "$entitlements" "com.apple.developer.icloud-services" "0")
if [[ "$cloudkit_service" != "CloudKit" ]]; then
  echo "Expected CloudKit iCloud service, found $cloudkit_service" >&2
  exit 1
fi

healthkit_enabled=$(read_plist_value "$entitlements" "com.apple.developer.healthkit" "")
if [[ "$healthkit_enabled" != "true" ]]; then
  echo "Expected HealthKit entitlement to be enabled" >&2
  exit 1
fi

google_callback_scheme=$(read_plist_value "$info_plist" "CFBundleURLTypes" "0.CFBundleURLSchemes.0")
if [[ "$google_callback_scheme" != "$expected_google_callback_scheme" ]]; then
  echo "Expected Google callback scheme $expected_google_callback_scheme, found $google_callback_scheme" >&2
  exit 1
fi

grep -F "NSHealthShareUsageDescription" "$info_plist" >/dev/null
if grep -F "NSHealthUpdateUsageDescription" "$info_plist" >/dev/null; then
  echo "V1 should not declare HealthKit write usage because it only reads authorized Health data" >&2
  exit 1
fi

remote_notification_mode=$(read_plist_value "$info_plist" "UIBackgroundModes" "0")
if [[ "$remote_notification_mode" != "remote-notification" ]]; then
  echo "Expected remote-notification background mode, found $remote_notification_mode" >&2
  exit 1
fi

"$python_bin" - "$privacy_manifest" <<'PY'
import plistlib
import sys

path = sys.argv[1]
with open(path, "rb") as file:
    manifest = plistlib.load(file)

if manifest.get("NSPrivacyTracking") is not False:
    raise SystemExit("Expected privacy manifest to declare no tracking")

expected_types = {
    "NSPrivacyCollectedDataTypeHealth",
    "NSPrivacyCollectedDataTypeFitness",
    "NSPrivacyCollectedDataTypeOtherUserContent",
    "NSPrivacyCollectedDataTypeProductInteraction",
}
collected_types = manifest.get("NSPrivacyCollectedDataTypes", [])
actual_types = {entry.get("NSPrivacyCollectedDataType") for entry in collected_types}
missing = expected_types - actual_types
if missing:
    raise SystemExit(f"Privacy manifest missing collected data types: {sorted(missing)}")

for entry in collected_types:
    if entry.get("NSPrivacyCollectedDataTypeTracking") is not False:
        raise SystemExit("Expected collected data types to declare no tracking")
    purposes = entry.get("NSPrivacyCollectedDataTypePurposes")
    if purposes != ["NSPrivacyCollectedDataTypePurposeAppFunctionality"]:
        raise SystemExit("Expected collected data types to be used only for app functionality")
PY

grep -F "CODE_SIGN_ENTITLEMENTS: Sources/ClarityHubApp/ClarityHub.entitlements" "$project_config" >/dev/null
grep -F "ClarityHubUITests:" "$project_config" >/dev/null
grep -F "Tests/ClarityHubUITests" "$project_config" >/dev/null
grep -F ".private(\"$expected_container\")" "$model_factory" >/dev/null
grep -F "actions/checkout@v7" "$ios_ci_workflow" >/dev/null
grep -F "actions/checkout@v7" "$codeql_workflow" >/dev/null
grep -F "actions/upload-artifact@v7" "$ios_ci_workflow" >/dev/null
grep -F "TestResults/ClarityHub.xcresult" "$ios_ci_workflow" >/dev/null
grep -F "github/codeql-action/init@v4" "$codeql_workflow" >/dev/null
grep -F "github/codeql-action/analyze@v4" "$codeql_workflow" >/dev/null

echo "Release configuration verified."
