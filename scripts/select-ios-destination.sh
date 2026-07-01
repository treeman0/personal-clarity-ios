#!/usr/bin/env bash
set -euo pipefail

if xcrun simctl list devices available | grep -q "iPhone 16"; then
  echo "platform=iOS Simulator,name=iPhone 16"
elif xcrun simctl list devices available | grep -q "iPhone 15"; then
  echo "platform=iOS Simulator,name=iPhone 15"
else
  echo "generic/platform=iOS Simulator"
fi

