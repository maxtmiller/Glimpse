import AppKit
import SkyLightWindow

final class PerchPanel: NSPanel {
    private var isSkyLightEnabled = false

    override init(
        contentRect: NSRect, 
        styleMask style: NSWindow.StyleMask = [.borderless, .nonactivatingPanel, .fullSizeContentView], 
        backing bufferingType: NSWindow.BackingStoreType = .buffered, 
        defer flag: Bool = false
    ) {
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
        
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        
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

    // PREVENTS macOS FROM SHIFTING THE PANEL DOWN FROM y = 0
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }

    func enableSkyLight() {
        guard !isSkyLightEnabled else { return }
        SkyLightOperator.shared.delegateWindow(self)
        isSkyLightEnabled = true
    }
}