import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NotchPanel?
    private var layout = PanelLayout.from(screen: NSScreen.main)

    func applicationDidFinishLaunching(_ notification: Notification) {
        layout = PanelLayout.from(screen: NSScreen.main ?? NSScreen.screens.first)

        let snapshot = WeatherSnapshot.sample
        let rootView = NotchWeatherView(snapshot: snapshot, layout: layout) { _ in }

        let panel = NotchPanel(contentRect: .zero)
        panel.contentView = NSHostingView(rootView: rootView)
        self.panel = panel

        position(panel: panel, size: fixedPanelSize)
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private var fixedPanelSize: NSSize {
        NSSize(width: layout.expandedWidth, height: layout.topBarHeight + layout.expandedBodyHeight)
    }

    private func position(panel: NotchPanel, size: NSSize) {
        let screen = panel.screen ?? NSScreen.main ?? NSScreen.screens.first
        let frame = notchFrame(for: screen, size: size)
        panel.setFrame(frame, display: false)
    }

    private func notchFrame(for screen: NSScreen?, size: NSSize) -> NSRect {
        guard let screen else {
            return NSRect(origin: .zero, size: size)
        }

        let frame = screen.frame
        let topOverlap: CGFloat = 2
        let x = frame.midX - size.width / 2
        let y = frame.maxY - size.height + topOverlap

        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }
}
