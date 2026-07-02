#!/usr/bin/env bash
set -euo pipefail

expected_container="iCloud.com.treeman0.ClarityHub"
entitlements="Sources/ClarityHubApp/ClarityHub.entitlements"
model_factory="Sources/ClarityHubApp/Persistence/ClarityHubModelContainerFactory.swift"
project_config="project.yml"

python_bin="python3"
if ! command -v "$python_bin" >/dev/null 2>&1; then
  python_bin="python"
fi

read_plist_value() {
  "$python_bin" - "$entitlements" "$1" "$2" <<'PY'
import plistlib
import sys

path, key, index = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "rb") as file:
    value = plistlib.load(file)[key]

if index != "":
    value = value[int(index)]

if isinstance(value, bool):
    print(str(value).lower())
else:
    print(value)
PY
}

actual_container=$(read_plist_value "com.apple.developer.icloud-container-identifiers" "0")
if [[ "$actual_container" != "$expected_container" ]]; then
  echo "Expected iCloud container $expected_container, found $actual_container" >&2
  exit 1
fi

cloudkit_service=$(read_plist_value "com.apple.developer.icloud-services" "0")
if [[ "$cloudkit_service" != "CloudKit" ]]; then
  echo "Expected CloudKit iCloud service, found $cloudkit_service" >&2
  exit 1
fi

healthkit_enabled=$(read_plist_value "com.apple.developer.healthkit" "")
if [[ "$healthkit_enabled" != "true" ]]; then
  echo "Expected HealthKit entitlement to be enabled" >&2
  exit 1
fi

grep -F "CODE_SIGN_ENTITLEMENTS: Sources/ClarityHubApp/ClarityHub.entitlements" "$project_config" >/dev/null
grep -F ".private(\"$expected_container\")" "$model_factory" >/dev/null

echo "Release configuration verified."
