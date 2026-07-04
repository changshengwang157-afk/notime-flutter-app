#!/usr/bin/env bash
# Build Ad Hoc IPA for direct iPhone install (no TestFlight).
# Run on macOS only — requires Xcode + Apple Developer account.
#
# Before building:
# 1. Register each tester iPhone UDID in Apple Developer → Devices
# 2. Open ios/Runner.xcworkspace → Signing & Capabilities → select Team
# 3. Copy GoogleService-Info.plist into ios/Runner/ (for push)
#
# Usage:
#   chmod +x scripts/build-ipa-adhoc.sh
#   ./scripts/build-ipa-adhoc.sh
#
# Output: build/ios/ipa/*.ipa
# Share via Diawi / InstallOnAir, or install with Xcode → Devices.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

API_BASE="${NOTIME_API_BASE:-https://heynotime.com}"
USE_MOCK="${USE_MOCK_DATA:-false}"

echo "==> flutter pub get"
flutter pub get

echo "==> pod install"
cd ios
pod install
cd ..

echo "==> Building Ad Hoc IPA (v$(grep '^version:' pubspec.yaml))"
flutter build ipa \
  --dart-define="NOTIME_API_BASE=${API_BASE}" \
  --dart-define="USE_MOCK_DATA=${USE_MOCK}" \
  --export-options-plist=ios/ExportOptions-ad-hoc.plist

IPA="$(ls -1 build/ios/ipa/*.ipa 2>/dev/null | head -1)"
if [[ -z "${IPA}" ]]; then
  echo "ERROR: IPA not found under build/ios/ipa/"
  exit 1
fi

echo ""
echo "OK: ${IPA}"
echo ""
echo "Next steps:"
echo "  1. Upload to https://www.diawi.com/ (or similar)"
echo "  2. Send the link to testers — open in Safari on iPhone"
echo "  3. Settings → General → VPN & Device Management → Trust developer (if asked)"
