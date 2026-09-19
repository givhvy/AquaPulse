#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
KEY="$HOME/.appstoreconnect/private_keys/AuthKey_8VGXL54C7K.p8"
ISSUE=3ea3181b-b9ea-4a12-a4cd-f385eb4c679b
rm -rf build/archive.xcarchive build/export
xcodebuild archive \
  -project AquaPulse.xcodeproj \
  -scheme AquaPulse \
  -archivePath build/archive.xcarchive \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY" \
  -authenticationKeyID 8VGXL54C7K \
  -authenticationKeyIssuerID "$ISSUE"
xcodebuild -exportArchive \
  -archivePath build/archive.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY" \
  -authenticationKeyID 8VGXL54C7K \
  -authenticationKeyIssuerID "$ISSUE"
echo "If export says Error Downloading App Information, create the iOS app in App Store Connect first:"
echo "  Name AquaPulse · bundle global.huy.AquaPulse · SKU aquapulse-ios · English (US)"
