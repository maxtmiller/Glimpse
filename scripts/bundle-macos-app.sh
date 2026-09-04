#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Notch"
CONFIGURATION="${CONFIGURATION:-debug}"
APP_VERSION="${APP_VERSION:-1.0.5}"
APP_BUILD="${APP_BUILD:-105}"
APP_COPYRIGHT="${APP_COPYRIGHT:-Copyright © 2026 Maximilian Miller}"
BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
BUILD_DIR="$ROOT_DIR/.build/$CONFIGURATION"
APP_BUNDLE="$ROOT_DIR/.build/$APP_NAME.app"
EXECUTABLE="$BUILD_DIR/$APP_NAME"
ICON_SOURCE="$ROOT_DIR/Assets/notch-icon.png"
ICONSET_DIR="$ROOT_DIR/.build/Notch.iconset"

swift build -c "$CONFIGURATION" --product "$APP_NAME"

rm -rf "$APP_BUNDLE"
rm -rf "$ICONSET_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$ICONSET_DIR"

cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

if [[ ! -f "$ICON_SOURCE" ]]; then
    echo "Missing app icon: $ICON_SOURCE" >&2
    exit 1
fi

for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$ICON_SOURCE" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
    doubled=$((size * 2))
    sips -z "$doubled" "$doubled" "$ICON_SOURCE" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil --convert icns "$ICONSET_DIR" --output "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET_DIR"

cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
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
    <key>CFBundleGetInfoString</key>
    <string>Notch — glanceable information and controls for macOS</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$APP_BUILD</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHumanReadableCopyright</key>
    <string>$APP_COPYRIGHT</string>
    <key>NotchBuildDate</key>
    <string>$BUILD_DATE</string>
    <key>NSLocationUsageDescription</key>
    <string>Notch uses your location to show local weather and forecast data.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Notch uses your location to show local weather and forecast data.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Notch uses Apple Events to read and control playback in supported media apps.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Notch uses the microphone level to show meeting audio activity.</string>
    <key>NSCameraUsageDescription</key>
    <string>Notch checks whether the camera is currently in use during meetings.</string>
</dict>
</plist>
EOF

open "$APP_BUNDLE"
printf 'Bundled app at %s\n' "$APP_BUNDLE"
