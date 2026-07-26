import AppKit
import SkyLightWindow

final class NotchPanel: NSPanel {
    private var isSkyLightEnabled = false

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask = [.borderless, .nonactivatingPanel], backing bufferingType: NSWindow.BackingStoreType = .buffered, defer flag: Bool = false) {
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)

        isFloatingPanel = true
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        isReleasedWhenClosed = false
        hasShadow = false
        hidesOnDeactivate = false
        isMovable = false
        isMovableByWindowBackground = false
        ignoresMouseEvents = false
        animationBehavior = .none
        collectionBehavior = [
            .canJoinAllSpaces,
            .canJoinAllApplications,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func enableSkyLight() {
        guard !isSkyLightEnabled else { return }
        SkyLightOperator.shared.delegateWindow(self)
        isSkyLightEnabled = true
    }
}
