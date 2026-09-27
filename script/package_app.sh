#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

APP_NAME="EdgeDeck"

# Sürüm açıkça verilmelidir (CI'da git etiketinden gelir): EDGEDECK_VERSION=1.2.0 ./script/package_app.sh
if [[ -z "${EDGEDECK_VERSION:-}" ]]; then
    echo "error: EDGEDECK_VERSION is not set (example: EDGEDECK_VERSION=1.0.0 ./script/package_app.sh)" >&2
    exit 1
fi
BUILD_DIR="${ROOT_DIR}/build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
ENTITLEMENTS="${BUILD_DIR}/entitlements.plist"

echo "==> Building ${APP_NAME} in release configuration..."
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/${APP_NAME}"

echo "==> Creating macOS App Bundle structure..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

echo "==> Copying binary..."
cp "${BIN_PATH}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

echo "==> Copying AppIcon.icns..."
if [[ -f "${ROOT_DIR}/AppIcon.icns" ]]; then
    cp "${ROOT_DIR}/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

echo "==> Copying Info.plist..."
cp "${ROOT_DIR}/script/Info.plist" "${CONTENTS_DIR}/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${EDGEDECK_VERSION}" "${CONTENTS_DIR}/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${EDGEDECK_VERSION}" "${CONTENTS_DIR}/Info.plist"

echo "==> Writing hardened runtime entitlements..."
cat << 'EOF' > "${ENTITLEMENTS}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Detecting Apple Developer ID signing identity..."
DEV_ID="$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -n 1 | awk -F '"' '{print $2}' || true)"

if [[ -n "${DEV_ID}" ]]; then
    echo "==> Found Apple Developer ID identity: ${DEV_ID}"
    SIGN_IDENTITY="${DEV_ID}"
    CODESIGN_FLAGS=(--options runtime --timestamp)
elif [[ -n "${CI:-}" ]]; then
    # CI kullanıcıya dağıtılacak paket üretir; imzasız bir DMG asla yayınlanmamalı
    echo "error: no 'Developer ID Application' identity in the keychain; check the MACOS_CERTIFICATE_P12_BASE64 secret" >&2
    exit 1
else
    echo "==> Using Ad-Hoc / Local Developer signature..."
    SIGN_IDENTITY="-"
    CODESIGN_FLAGS=()
fi

echo "==> Codesigning bundle..."
codesign --force --deep --sign "${SIGN_IDENTITY}" "${CODESIGN_FLAGS[@]}" --entitlements "${ENTITLEMENTS}" "${APP_BUNDLE}"

echo "==> Packaging DMG installer..."
DMG_PATH="${BUILD_DIR}/${APP_NAME}-${EDGEDECK_VERSION}.dmg"
rm -f "${DMG_PATH}"

DMG_STAGE="/tmp/edgedeck_dmg_stage"
rm -rf "${DMG_STAGE}"
mkdir -p "${DMG_STAGE}"
cp -R "${APP_BUNDLE}" "${DMG_STAGE}/"
ln -s /Applications "${DMG_STAGE}/Applications"

hdiutil create -volname "${APP_NAME}" -srcfolder "${DMG_STAGE}" -ov -format UDZO "${DMG_PATH}"
rm -rf "${DMG_STAGE}"

if [[ -n "${DEV_ID}" ]]; then
    echo "==> Codesigning DMG installer with Apple Developer ID..."
    codesign --force --sign "${SIGN_IDENTITY}" "${CODESIGN_FLAGS[@]}" "${DMG_PATH}"
fi

if [[ -n "${APPLE_NOTARY_PROFILE:-}" ]]; then
    echo "==> Submitting to Apple Notary Service using profile: ${APPLE_NOTARY_PROFILE}..."
    xcrun notarytool submit "${DMG_PATH}" --keychain-profile "${APPLE_NOTARY_PROFILE}" --wait
    echo "==> Stapling notarization ticket to DMG..."
    xcrun stapler staple "${DMG_PATH}"
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
    echo "==> Submitting to Apple Notary Service..."
    xcrun notarytool submit "${DMG_PATH}" --apple-id "${APPLE_ID}" --password "${APPLE_APP_SPECIFIC_PASSWORD}" --team-id "${APPLE_TEAM_ID}" --wait
    echo "==> Stapling notarization ticket to DMG..."
    xcrun stapler staple "${DMG_PATH}"
elif [[ -n "${CI:-}" ]]; then
    echo "error: notarization credentials missing in CI; set APPLE_ID, APPLE_APP_SPECIFIC_PASSWORD and APPLE_TEAM_ID secrets" >&2
    exit 1
else
    echo "==> (Notarization skipped: set APPLE_NOTARY_PROFILE or APPLE_ID credentials to enable automated Apple Notary submission)"
fi

echo "==> Build and Packaging complete!"
echo "    App Bundle: ${APP_BUNDLE}"
echo "    DMG Installer: ${DMG_PATH}"
