#!/usr/bin/env bash
set -euo pipefail

VERIFY_MODE=false
for arg in "$@"; do
    if [ "$arg" = "--verify" ]; then
        VERIFY_MODE=true
    fi
done

# Stop running EdgeDeck if any
if pgrep -x "EdgeDeck" >/dev/null 2>&1; then
    pkill -x "EdgeDeck" || true
    for _ in {1..20}; do
        if ! pgrep -x "EdgeDeck" >/dev/null 2>&1; then
            break
        fi
        sleep 0.1
    done
fi

# Build product
swift build --product EdgeDeck

BIN_PATH="$(swift build --show-bin-path)/EdgeDeck"
APP_DIR="dist/EdgeDeck.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

# Copy binary
cp "${BIN_PATH}" "${MACOS_DIR}/EdgeDeck"
chmod +x "${MACOS_DIR}/EdgeDeck"

# Info.plist: paketleme betiğiyle aynı kaynak; Bluetooth/Apple Events izin açıklamaları eksik olursa
# macOS uygulamayı TCC ihlaliyle sonlandırır.
cp "script/Info.plist" "${CONTENTS_DIR}/Info.plist"
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Launch app
/usr/bin/open -n "${APP_DIR}"

if [ "${VERIFY_MODE}" = true ]; then
    FOUND=false
    for _ in {1..30}; do
        if pgrep -x "EdgeDeck" >/dev/null 2>&1; then
            FOUND=true
            break
        fi
        sleep 0.1
    done
    if [ "${FOUND}" = true ]; then
        echo "Verification passed: EdgeDeck is running."
        exit 0
    else
        echo "Verification failed: EdgeDeck process not found." >&2
        exit 1
    fi
fi
