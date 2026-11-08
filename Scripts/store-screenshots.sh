#!/bin/zsh
#
# store-screenshots.sh
# ManualShelf
#
# Captures the App Store screenshots (SPEC-005) on one simulator in English and German.
# Usage: Scripts/store-screenshots.sh <simulator-udid> <output-folder> [derived-data-path]
# Writes <output-folder>/<en|de>/*.png. Build first with:
#   xcodebuild build-for-testing -scheme ManualShelf -destination 'generic/platform=iOS Simulator' -derivedDataPath <path>
# The simulator is rebooted per language (system language and locale for the status bar), never erased.

set -eu

DEVICE="$1"
OUTPUT="$2"
DERIVED_DATA="${3:-build/DerivedData}"
STATUS_BAR_TIME="9:41"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GLOBAL_PREFERENCES="$HOME/Library/Developer/CoreSimulator/Devices/$DEVICE/data/Library/Preferences/.GlobalPreferences.plist"

for language in en de; do
    locale="en_US"
    [ "$language" = "de" ] && locale="de_DE"

    xcrun simctl shutdown "$DEVICE" 2>/dev/null || true
    defaults write "$GLOBAL_PREFERENCES" AppleLanguages -array "$language"
    defaults write "$GLOBAL_PREFERENCES" AppleLocale -string "$locale"
    xcrun simctl boot "$DEVICE"
    xcrun simctl bootstatus "$DEVICE" >/dev/null
    xcrun simctl ui "$DEVICE" appearance light
    xcrun simctl status_bar "$DEVICE" override --time "$STATUS_BAR_TIME" \
        --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4

    mkdir -p "$OUTPUT/$language"
    TEST_RUNNER_SHOT_LANG="$language" TEST_RUNNER_SHOT_DIR="$OUTPUT/$language" \
        xcodebuild test-without-building -project "$PROJECT_ROOT/ManualShelf.xcodeproj" -scheme ManualShelf \
        -destination "id=$DEVICE" -derivedDataPath "$DERIVED_DATA" -parallel-testing-enabled NO \
        -only-testing:ManualShelfUITests/StoreScreenshotUITests > "$OUTPUT/$language/xcodebuild.log" 2>&1
    rm "$OUTPUT/$language/xcodebuild.log"
    echo "$language: $(ls "$OUTPUT/$language" | tr '\n' ' ')"
done
