import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NotchPanel?
    private var layout = PanelLayout.from(screen: NSScreen.main)
    private var anchoredFrame: NSRect?
    private var currentState: NotchPresentationState = .hidden
    private var mouseTrackingTimer: Timer?
    private var wasInsideInteractiveRect: Bool?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let anchorScreen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 })
            ?? NSScreen.main
            ?? NSScreen.screens.first
        layout = PanelLayout.from(screen: anchorScreen)
        anchoredFrame = notchFrame(for: anchorScreen, size: fixedPanelSize)

        let rootView = AnyView(NotchRootView(layout: layout))
        let panel = NotchPanel(contentRect: .zero)
        panel.contentView = NSHostingView(rootView: rootView)
        self.panel = panel

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePresentationStateChange(_:)),
            name: .notchPresentationStateDidChange,
            object: nil
        )
        position(panel: panel)
        updateMouseInteraction()

        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.updateMouseInteraction()
        }
        RunLoop.main.add(mouseTrackingTimer!, forMode: .common)

        presentPanel()
    }

    func applicationDidResignActive(_ notification: Notification) {
        guard let panel, currentState != .hidden else { return }
        panel.orderFrontRegardless()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        presentPanel()
    }

    private var fixedPanelSize: NSSize {
        NSSize(width: layout.expandedWidth, height: layout.topBarHeight + layout.expandedBodyHeight)
    }

    private func position(panel: NotchPanel) {
        let frame = anchoredFrame ?? notchFrame(for: NSScreen.main ?? NSScreen.screens.first, size: fixedPanelSize)
        panel.setFrame(frame, display: false)
    }

    private func notchFrame(for screen: NSScreen?, size: NSSize) -> NSRect {
        guard let screen else {
            return NSRect(origin: .zero, size: size)
        }

        let frame = screen.frame
        // Keep a small portion of the panel above the display edge so the
        // notch remains enterable when the cursor approaches from the top.
        let topOverlap: CGFloat = 2
        let x = frame.midX - size.width / 2
        let y = frame.maxY - size.height + topOverlap

        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    @objc private func handlePresentationStateChange(_ notification: Notification) {
        guard let rawState = notification.userInfo?["state"] as? String,
              let state = NotchPresentationState(rawValue: rawState)
        else {
            return
        }

        currentState = state
        presentPanel()
    }

    private func presentPanel() {
        guard let panel else { return }

        position(panel: panel)
        panel.orderFrontRegardless()
        panel.enableSkyLight()
        updateMouseInteraction()
    }

    private func updateMouseInteraction() {
        guard let panel else { return }

        let mouseLocation = NSEvent.mouseLocation
        let isInsideInteractiveRect = interactiveRect(for: currentState, in: panel).contains(mouseLocation)
        let shouldIgnore = !isInsideInteractiveRect

        if wasInsideInteractiveRect != isInsideInteractiveRect {
            wasInsideInteractiveRect = isInsideInteractiveRect
            // Space transitions can move the panel without delivering an
            // AppKit mouseExited event. Keep the SwiftUI hover tracker
            // synchronized with the screen-space hit test.
            if !isInsideInteractiveRect && currentState == .expanded {
                NotificationCenter.default.post(name: .notchMouseExited, object: nil)
            }
        }

        if panel.ignoresMouseEvents != shouldIgnore {
            panel.ignoresMouseEvents = shouldIgnore
        }

        if !shouldIgnore && currentState == .hidden {
            panel.orderFrontRegardless()
        }
    }

    private func interactiveRect(for state: NotchPresentationState, in panel: NSWindow) -> NSRect {
        let frame = panel.frame
        let padding: CGFloat = 2.0 // 2px safety margin on all sides

        switch state {
        case .hidden:
            let handleHeight = max(layout.topBarHeight - 16, 28)
            let rect = NSRect(
                x: frame.midX - NotchGeometry.width / 2,
                y: frame.maxY - handleHeight,
                width: NotchGeometry.width,
                height: handleHeight
            )
            // Inset by negative padding to grow the hit target slightly in all directions
            return rect.insetBy(dx: -padding, dy: -padding)

        case .collapsed:
            let shellHeight = max(layout.topBarHeight - 10, 50)
            let rect = NSRect(
                x: frame.midX - layout.collapsedWidth / 2,
                y: frame.maxY - shellHeight,
                width: layout.collapsedWidth,
                height: shellHeight
            )
            return rect.insetBy(dx: -padding, dy: -padding)

        case .expanded:
            return frame
        }
    }
}

private enum NotchPresentationState: String {
    case hidden
    case collapsed
    case expanded
}

extension Notification.Name {
    static let notchPresentationStateDidChange = Notification.Name("NotchPresentationStateDidChange")
    static let notchMouseExited = Notification.Name("NotchMouseExited")
}
