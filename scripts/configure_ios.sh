#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INFO_PLIST="$REPO_ROOT/app/ios/Runner/Info.plist"

if [[ ! -f "$INFO_PLIST" ]]; then
  echo "iOS project not generated: $INFO_PLIST" >&2
  exit 1
fi

/usr/libexec/PlistBuddy -c "Add :NSLocalNetworkUsageDescription string O aplicativo precisa acessar o servidor local para exibir os dados dos sensores." "$INFO_PLIST" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :NSLocalNetworkUsageDescription O aplicativo precisa acessar o servidor local para exibir os dados dos sensores." "$INFO_PLIST"

/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Monitor de Ruído" "$INFO_PLIST" 2>/dev/null || true

echo "iOS local-network permissions configured."
