#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Notch"
CONFIGURATION="${CONFIGURATION:-debug}"
BUILD_DIR="$ROOT_DIR/.build/$CONFIGURATION"
APP_BUNDLE="$ROOT_DIR/.build/$APP_NAME.app"
EXECUTABLE="$BUILD_DIR/$APP_NAME"

swift build -c "$CONFIGURATION" --product "$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"

cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Notch</string>
    <key>CFBundleIdentifier</key>
    <string>com.maxtmiller.Notch</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Notch</string>
    <key>CFBundleDisplayName</key>
    <string>Notch</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSLocationUsageDescription</key>
    <string>Notch uses your location to show local weather and forecast data.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Notch uses your location to show local weather and forecast data.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Notch uses Apple Events to read and control playback in supported media apps.</string>
</dict>
</plist>
EOF

open "$APP_BUNDLE"
printf 'Bundled app at %s\n' "$APP_BUNDLE"
