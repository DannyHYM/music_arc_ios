#!/usr/bin/env bash
#
# Captures a screenshot of every product screen into docs/ui/ using the app's DEBUG-only
# screenshot gallery (see MusicArc/App/ScreenshotGallery.swift). Each screen is rendered by
# the real views with fixed fake data, so the images match the shipping UI.
#
# Usage:
#   scripts/capture_ui_screenshots.sh              # build, install, capture all screens
#   SKIP_BUILD=1 scripts/capture_ui_screenshots.sh # reuse the last build
#   SIM_DEVICE="iPhone 17 Pro Max" scripts/capture_ui_screenshots.sh
#
# Requires Xcode with an iOS simulator matching SIM_DEVICE (default "iPhone 17 Pro").

set -euo pipefail
cd "$(dirname "$0")/.."

SIM_DEVICE="${SIM_DEVICE:-iPhone 17 Pro}"
OUT_DIR="${OUT_DIR:-docs/ui}"
SETTLE_SECONDS="${SETTLE_SECONDS:-3}"
# Pixel width to store. The simulator captures at 3x (1206 px); 2x keeps the repo small.
# Set SCREENSHOT_WIDTH=0 to keep the native capture.
SCREENSHOT_WIDTH="${SCREENSHOT_WIDTH:-804}"
BUNDLE_ID="com.musicarc.app"
DERIVED_DATA=".build/ScreenshotDerivedData"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/MusicArc.app"

# Keep in sync with ScreenshotGallery.screenNames.
SCREENS=(
  welcome welcome-empty
  clinician-pin clinician-setup
  calibration-intro calibration-raise calibration-done
  game-countdown game-active game-rest game-paused game-finished
  summary history
  tree-oak tree-round tree-bushy tree-pine tree-acacia
)

UDID=$(xcrun simctl list devices available | grep "^ *$SIM_DEVICE (" | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
if [[ -z "$UDID" ]]; then
  echo "No available simulator named '$SIM_DEVICE'. Run: xcrun simctl list devices available" >&2
  exit 1
fi

echo "Using $SIM_DEVICE ($UDID)"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null

if [[ -z "${SKIP_BUILD:-}" ]]; then
  echo "Building MusicArc (Debug) for the simulator…"
  xcodebuild -project MusicArc.xcodeproj -scheme MusicArc -configuration Debug \
    -destination "id=$UDID" -derivedDataPath "$DERIVED_DATA" build -quiet
fi

xcrun simctl install "$UDID" "$APP_PATH"

# Apple's conventional clean status bar for screenshots.
xcrun simctl status_bar "$UDID" override \
  --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

mkdir -p "$OUT_DIR"
for screen in "${SCREENS[@]}"; do
  SIMCTL_CHILD_MUSICARC_SCREENSHOT="$screen" \
    xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" >/dev/null
  sleep "$SETTLE_SECONDS"
  xcrun simctl io "$UDID" screenshot --type png "$OUT_DIR/$screen.png" 2>/dev/null
  if [[ "$SCREENSHOT_WIDTH" != "0" ]]; then
    sips --resampleWidth "$SCREENSHOT_WIDTH" "$OUT_DIR/$screen.png" >/dev/null
  fi
  # sips writes weakly compressed PNGs. zopflipng roughly halves them losslessly but takes
  # ~25 s per file, so it is opt-in: OPTIMIZE_PNG=1 (recommended before committing).
  if [[ -n "${OPTIMIZE_PNG:-}" ]] && command -v zopflipng >/dev/null; then
    zopflipng -y "$OUT_DIR/$screen.png" "$OUT_DIR/$screen.png" >/dev/null 2>&1
  fi
  echo "  captured $screen"
done

xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl status_bar "$UDID" clear
echo "Done: ${#SCREENS[@]} screenshots in $OUT_DIR/"
