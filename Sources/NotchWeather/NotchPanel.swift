import AppKit

final class NotchPanel: NSPanel {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask = [.borderless, .nonactivatingPanel], backing bufferingType: NSWindow.BackingStoreType = .buffered, defer flag: Bool = false) {
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)

        isFloatingPanel = true
        level = .statusBar
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        hidesOnDeactivate = false
        ignoresMouseEvents = false
        animationBehavior = .none
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
