# Perch

Glanceable macOS information and control panel built with SwiftUI and AppKit.

## What it does

- Shows a floating panel centered near the top of your main display
- Opens to a home page with Weather, Markets, Playing, and Meetings widgets
- Loads market quotes and intraday chart data from Yahoo Finance without an API key; keeps sample data as a fallback
- Expands on hover to show extra market or weather details
- Pulls live location and weather data from Open-Meteo after you approve location access
- Shows current temperature, feels-like temperature, humidity, rain chance, wind, daily high/low, and an hourly forecast graph
- Supports one-, three-, seven-, and sixteen-day weather forecast ranges; the graph can show temperature, feels-like temperature, humidity, rain chance, or wind
- Shows live playback from Music or Spotify, including the source app and playback controls
- Provides a Meetings widget for default microphone mute and speaker deafen controls, microphone activity, and camera status
- Shows the frontmost app and selectable audio devices

## Run it

Requirements:

- macOS 13 or newer
- Xcode 15+ or the macOS Swift toolchain
- A real macOS app bundle if you want the location prompt to appear reliably

From a fresh clone:

```bash
git clone https://github.com/YOUR_USERNAME/Perch.git
cd Perch
```

Swift Package Manager will resolve the `SkyLightWindow` dependency automatically. To run the executable directly from source:

```bash
swift run Perch
```

That launches the panel directly.

If `swift run` reports a toolchain or SDK mismatch, open the package in Xcode instead and press Run. That is the normal path for macOS app previewing and avoids command-line toolchain issues.

To bundle and launch a real `.app` with the location usage strings included:

```bash
CONFIGURATION=release ./scripts/bundle-macos-app.sh
```

That creates `.build/Perch.app` and opens it. To install it locally, drag the app into `/Applications`.

The bundler converts `Assets/perch-icon.png` into the app’s `AppIcon.icns` automatically. The source icon should remain a square PNG; the current 1000×1000 RGBA asset is supported.

To create a shareable DMG without signing or notarization:

```bash
mkdir -p .build/Perch-dmg
cp -R .build/Perch.app .build/Perch-dmg/
ln -s /Applications .build/Perch-dmg/Applications
hdiutil create -volname "Perch" -srcfolder .build/Perch-dmg -ov -format UDZO Perch.dmg
```

Unsigned builds may trigger an “unidentified developer” warning. Users can Control-click the app, choose **Open**, and confirm the warning.

If the app has not been granted location access yet, click the cloud icon to request access again. If you denied access previously, macOS will send you to System Settings so you can re-enable it there.

The Playing widget reads Music and Spotify through macOS Apple Events. The first time you use it, macOS may ask you to allow Perch to control the selected media app. Use the bundled `.app` flow above so the permission description is available.

## Preview in Xcode

1. Open the repository in Xcode by opening `Package.swift`.
2. Open `Sources/Perch/PerchView.swift`.
3. Use the SwiftUI preview canvas on the `#Preview` block.

## Notes

- The live weather data comes from Open-Meteo, so no WeatherKit entitlement is required. Weather uses hourly precipitation probability for the Rain metric; Open-Meteo also provides rain and total precipitation amounts if more detailed precipitation reporting is added later.
- Weather refreshes automatically every 10 minutes and can be refreshed manually from the weather icon.
- Market data is fetched from Yahoo Finance every 60 seconds. Yahoo data can be delayed depending on the exchange, and its public endpoints are intended for personal use.
- The bundle script packages the executable and usage strings so the location prompt works from a real `.app`.
