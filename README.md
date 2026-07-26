# Notch

Basic macOS notch-style weather panel built with SwiftUI and AppKit.

## What it does

- Shows a floating panel centered near the top of your main display
- Uses a static sample weather card so you can preview the layout immediately
- Expands on hover to show extra weather details
- Pulls live location and weather data from a public weather API after you approve location access

## Run it

Requirements:

- macOS 13 or newer
- Xcode 15+ or the macOS Swift toolchain
- A real macOS app bundle if you want the location prompt to appear reliably

From the repository root:

```bash
swift run Notch
```

That launches the panel directly.

If `swift run` reports a toolchain or SDK mismatch, open the package in Xcode instead and press Run. That is the normal path for macOS app previewing and avoids command-line toolchain issues.

To bundle and launch a real `.app` with the location usage strings included:

```bash
./scripts/bundle-macos-app.sh
```

That creates `.build/Notch.app` and opens it.

If the app has not been granted location access yet, click the cloud icon to request access again. If you denied access previously, macOS will send you to System Settings so you can re-enable it there.

## Preview in Xcode

1. Open the repository in Xcode by opening `Package.swift`.
2. Open `Sources/Notch/NotchView.swift`.
3. Use the SwiftUI preview canvas on the `#Preview` block.

## Notes

- The live weather data comes from Open-Meteo, so no WeatherKit entitlement is required.
- The bundle script packages the executable and usage strings so the location prompt works from a real `.app`.
