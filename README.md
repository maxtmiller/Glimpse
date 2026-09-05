# Perch

![Swift](https://img.shields.io/badge/Swift-F05138?style=flat&logo=swift&logoColor=white) ![SwiftUI](https://img.shields.io/badge/SwiftUI-007AFF?style=flat&logo=swift&logoColor=white) ![macOS](https://img.shields.io/badge/macOS-13%2B-000000?style=flat&logo=apple&logoColor=white)

**A glanceable macOS information and control panel that lives at the top of your screen.**

---

## Preview



## Features

* **Floating Panel:** Keeps Weather, Markets, Playing, and Meetings available near the top of your main display.
* **Local Weather:** Shows temperature, feels-like temperature, humidity, rain chance, wind, daily high/low, and hourly forecasts using Open-Meteo.
* **Market Data:** Displays live quotes and intraday charts from Yahoo Finance, with sample data available as a fallback.
* **Media Controls:** Shows Music and Spotify playback, including the source app and playback controls.
* **Meeting Controls:** Provides microphone mute, speaker deafen, microphone activity, and camera status controls.
* **System Awareness:** Shows the frontmost app and lets you select audio devices.

## Setup

### 1. Download Perch

Perch requires macOS 13 or newer. Download the latest `Perch.dmg` from the [GitHub Releases page](../../releases).

### 2. Install the App

* Open the downloaded DMG.
* Drag `Perch.app` into your **Applications** folder.

### 3. Open Perch

The current release is unsigned, so macOS may show an unidentified-developer warning the first time:

* Open **Applications** in Finder.
* Control-click `Perch.app` and choose **Open**.
* Confirm the macOS security prompt.

This confirmation is normally required only on the first launch.

> 💡 **Tip:** Perch may request location, microphone, camera, and media-control permissions. Approve the permissions needed for the widgets you want to use. If location access was denied, re-enable it under **System Settings → Privacy & Security → Location Services**.

## Development

Open `Package.swift` in Xcode and press **Run**, or run the executable directly:

```bash
swift run Perch
```

Developer release and DMG packaging instructions are kept in [`AGENTS.md`](AGENTS.md).
