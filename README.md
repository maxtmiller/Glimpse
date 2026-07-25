# Notch Weather

Basic macOS notch-style weather panel built with SwiftUI and AppKit.

## What it does

- Shows a floating panel centered near the top of your main display
- Uses a static sample weather card so you can preview the layout immediately
- Expands on hover to show extra weather details

## Run it

Requirements:

- macOS 13 or newer
- Xcode 15+ or the macOS Swift toolchain

From the repository root:

```bash
swift run NotchWeather
```

That launches the panel directly.

If `swift run` reports a toolchain or SDK mismatch, open the package in Xcode instead and press Run. That is the normal path for macOS app previewing and avoids command-line toolchain issues.

## Preview in Xcode

1. Open the repository in Xcode by opening `Package.swift`.
2. Open `Sources/NotchWeather/NotchWeatherView.swift`.
3. Use the SwiftUI preview canvas on the `#Preview` block.

## Notes

- The weather data is hardcoded sample data for now.
- If you want, I can wire this to a live weather API next.
