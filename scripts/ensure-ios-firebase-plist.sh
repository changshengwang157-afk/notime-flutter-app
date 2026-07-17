#!/usr/bin/env bash
# Run before `flutter build ipa` if GoogleService-Info.plist is missing locally.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/ios/Runner/GoogleService-Info.plist"
SRC="$ROOT/ios/Runner/GoogleService-Info-backup.plist"

if [[ -f "$DEST" ]]; then
  echo "OK: GoogleService-Info.plist already present"
  exit 0
fi

if [[ ! -f "$SRC" ]]; then
  echo "ERROR: Missing $SRC — download from Firebase Console first." >&2
  exit 1
fi

cp "$SRC" "$DEST"
echo "Copied GoogleService-Info-backup.plist -> GoogleService-Info.plist"
