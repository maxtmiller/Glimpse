# Space Overlay Findings

## Problem

The notch panel must remain anchored to the physical MacBook display while switching macOS Spaces. Standard AppKit Space behavior caused duplicate panel representations during horizontal desktop swipes: one copy animated out of the previous Space while another animated into the next Space.

## Important Observations

- `.canJoinAllSpaces` makes a normal AppKit window appear in every Space, but WindowServer may render duplicate transition representations during a horizontal swipe.
- `.stationary` does not bypass Space composition. It primarily affects Mission Control behavior.
- `.transient` avoids some Space behavior but hides the panel during upward Mission Control swipes, so it is not suitable here.
- Repositioning the window on `activeSpaceDidChangeNotification` can worsen the transition by forcing another Space/window ordering operation.
- Repeatedly resetting the frame on a timer does not solve compositor-level duplication.
- Calling `makeKey()` or activating the application is undesirable for a persistent overlay because it can associate the panel with the active Space.
- The panel should be non-key, non-main, non-movable, and use a nonactivating panel style.

## Working Solution

Use the `SkyLightWindow` package and delegate the panel to SkyLight after it is ordered:

```swift
panel.orderFrontRegardless()
panel.enableSkyLight()
```

`NotchPanel.enableSkyLight()` calls `SkyLightOperator.shared.delegateWindow(self)`.

This moves the window into SkyLight-managed system-level positioning instead of relying solely on AppKit's per-Space window membership.

## Required Configuration

`Package.swift` depends on:

```swift
.package(url: "https://github.com/Lakr233/SkyLightWindow", from: "1.0.0")
```

The panel uses:

```swift
level = .screenSaver
isMovable = false
isMovableByWindowBackground = false
isReleasedWhenClosed = false
collectionBehavior = [
    .canJoinAllSpaces,
    .canJoinAllApplications,
    .stationary,
    .fullScreenAuxiliary,
    .ignoresCycle
]
```

It overrides `canBecomeKey` and `canBecomeMain` to return `false`.

The app uses accessory activation policy:

```swift
NSApp.setActivationPolicy(.accessory)
```

## Do Not Regress

- Do not replace SkyLight delegation with only `.canJoinAllSpaces`.
- Do not use `.transient`; it hides during Mission Control.
- Do not add an active-Space observer that calls `makeKey()`, repeatedly orders the panel, or continuously resets its frame.
- Do not restore `NSApp.activate(ignoringOtherApps: true)` for this overlay.
- Keep SwiftPM target argument ordering valid: target `dependencies` must appear before `path`.

## Reference

The working approach was based on Boring Notch's `BoringNotchSkyLightWindow.swift` and the `SkyLightWindow` package:

- https://github.com/TheBoredTeam/boring.notch/blob/main/boringNotch/components/Notch/BoringNotchSkyLightWindow.swift
- https://github.com/Lakr233/SkyLightWindow

