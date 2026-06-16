#!/usr/bin/env bash

set -euo pipefail

DEVICE_PROFILE="${DEVICE_PROFILE:-iphone69}"
FRAMES="${FRAMES:-01 02 03}"

case "$DEVICE_PROFILE" in
    iphone69)
        SIM_NAME="iPhone 17 Pro Max"
        DEVICE_FOLDER="iphone69"
        ;;
    ipad13)
        SIM_NAME="iPad Pro 13-inch (M5)"
        DEVICE_FOLDER="ipad13"
        ;;
    *)
        echo "unknown DEVICE_PROFILE='$DEVICE_PROFILE' (expected iphone69 or ipad13)" >&2
        exit 1
        ;;
esac

BUNDLE_ID="com.ken0nek.LinkClean"
# Post Phase-2 monorepo absorb: this resolves to apps/ios/LinkClean/ (the iOS
# workspace root), not the repo root.
IOS_WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIRECTORY="$IOS_WORKSPACE_ROOT/screenshots/raw/en-US/$DEVICE_FOLDER"

UDID="$(
    xcrun simctl list devices booted \
        | grep "$SIM_NAME" \
        | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' \
        | head -1
)"

if [[ -z "${UDID:-}" ]]; then
    echo "no booted simulator matching '$SIM_NAME'" >&2
    echo "boot one with: xcrun simctl boot '$SIM_NAME'" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIRECTORY"

clear_status_bar() {
    xcrun simctl status_bar "$UDID" clear >/dev/null 2>&1 || true
}
trap clear_status_bar EXIT

if [[ "$DEVICE_PROFILE" == "ipad13" ]]; then
    xcrun simctl status_bar "$UDID" override \
        --time "9:41" \
        --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode notSupported \
        --batteryState charged --batteryLevel 100 >/dev/null
else
    xcrun simctl status_bar "$UDID" override \
        --time "9:41" \
        --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --operatorName "" \
        --batteryState charged --batteryLevel 100 >/dev/null
fi

xcrun simctl ui "$UDID" appearance light

frame_enabled() {
    [[ " $FRAMES " == *" $1 "* ]]
}

capture() {
    local output_name="$1"
    shift

    xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$UDID" "$BUNDLE_ID" \
        -screenshotMode \
        -AppleLanguages "(en)" \
        -AppleLocale "en_US" \
        -screenshotFixtures "$REPOSITORY_ROOT/Screenshots/fixtures/history" \
        "$@" >/dev/null
    # 5s rather than 3: the first launch right after a fresh install can take
    # >3s to render, which captures the blank launch screen.
    sleep 5
    xcrun simctl io "$UDID" screenshot "$OUTPUT_DIRECTORY/$output_name"
    echo "wrote $OUTPUT_DIRECTORY/$output_name"
}

if frame_enabled "01"; then
    capture "01_home.png" -seedSampleURL
fi

if frame_enabled "02"; then
    capture "02_history.png" -seedHistory -tab-history
fi

if frame_enabled "03"; then
    capture "03_parameters.png" -tab-settings -push-parameters
fi

echo "raw English screenshots captured for $DEVICE_PROFILE"
