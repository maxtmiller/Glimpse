import AppKit
import SwiftUI

enum NotchGeometry {
    static let width: CGFloat = 205
    static let height: CGFloat = 34
    static let lowerCornerRadius: CGFloat = 8
    static let topCornerRadius: CGFloat = 0
}

enum NotchMotion {
    static let hoverAnimationDuration: Double = 0.34
    static let pageTransitionAnimation = Animation.spring(response: 0.38, dampingFraction: 0.9, blendDuration: 0.06)
    static let presentationAnimation = Animation.spring(response: 0.46, dampingFraction: 0.86, blendDuration: 0.08)
}

struct PanelLayout {
    let topBarHeight: CGFloat
    let collapsedWidth: CGFloat
    let expandedWidth: CGFloat
    let collapsedBodyHeight: CGFloat
    let expandedBodyHeight: CGFloat

    static func from(screen: NSScreen?) -> PanelLayout {
        guard let screen else {
            return PanelLayout(
                topBarHeight: 60,
                collapsedWidth: 480,
                expandedWidth: 640,
                collapsedBodyHeight: 0,
                expandedBodyHeight: 190
            )
        }

        let hasNotch = screen.safeAreaInsets.top > 0
        let topBarHeight = hasNotch ? max(NotchGeometry.height + 16, 60) : 60
        let collapsedWidth = min(max(440, NotchGeometry.width + 260), screen.frame.width - 24)
        let expandedWidth = min(max(640, NotchGeometry.width + 435), screen.frame.width - 24)

        return PanelLayout(
            topBarHeight: topBarHeight,
            collapsedWidth: collapsedWidth,
            expandedWidth: expandedWidth,
            collapsedBodyHeight: 0,
            expandedBodyHeight: 190
        )
    }
}
