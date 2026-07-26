import AppKit
import SwiftUI

struct NotchView: View {
    private enum DisplayState {
        case hidden
        case collapsed
        case expanded
    }

    let snapshot: WeatherSnapshot
    let layout: PanelLayout
    let onHoverChanged: (Bool) -> Void
    let onLocationRequest: () -> Void

    @State private var displayState: DisplayState = .hidden
    @State private var selectedPage: NotchPage = .weather
    @State private var temperatureUnit: TemperatureUnit = .fahrenheit
    @State private var selectedGraphMetric: GraphMetric?
    @State private var suppressHoverUntil: Date?
    @State private var renderedState: DisplayState = .hidden
    @State private var presentationProgress: CGFloat = 0
    @State private var pendingHiddenResetToken = UUID()

    var body: some View {
        ZStack(alignment: .top) {
            hiddenToggleLayer
                .opacity(max(0, 1 - presentationProgress))
                .scaleEffect(1 - (0.03 * presentationProgress), anchor: .center)
                .offset(y: (1 - presentationProgress) * 2)
                .allowsHitTesting(displayState == .hidden)

            visibleShell
                .opacity(presentationProgress)
                .scaleEffect(0.90 + (0.10 * presentationProgress), anchor: .top)
                .offset(y: (1 - presentationProgress) * 4)
                .allowsHitTesting(displayState != .hidden)
        }
        .frame(
            width: layout.expandedWidth,
            height: layout.topBarHeight + layout.expandedBodyHeight,
            alignment: .top
        )
        .ignoresSafeArea()
    }

    private var isExpanded: Bool {
        renderedState == .expanded
    }

    private var visibleShell: some View {
        let shellWidth = isExpanded ? layout.expandedWidth : layout.collapsedWidth
        let shellHeight = isExpanded ? layout.topBarHeight + layout.expandedBodyHeight : collapsedShellHeight

        return ZStack(alignment: .top) {
            islandBackground
                .frame(width: shellWidth, height: shellHeight, alignment: .top)

            notchToggleButton
                .frame(width: shellWidth, height: shellHeight, alignment: .top)

            selectedWidgetView
                .frame(width: shellWidth, height: shellHeight, alignment: .top)

            hoverTrackingLayer
                .frame(width: shellWidth, height: shellHeight, alignment: .top)
        }
        .frame(width: shellWidth, height: shellHeight, alignment: .top)
    }

    @ViewBuilder
    private var selectedWidgetView: some View {
        ZStack {
            switch selectedPage {
            case .home:
                NotchHomeWidgetView(
                    layout: layout,
                    isExpanded: isExpanded,
                    presentationProgress: presentationProgress,
                    selectedPage: $selectedPage
                )
                .transition(pageSwapTransition)
            case .weather:
                WeatherWidgetView(
                    snapshot: snapshot,
                    layout: layout,
                    isExpanded: isExpanded,
                    presentationProgress: presentationProgress,
                    selectedPage: $selectedPage,
                    temperatureUnit: $temperatureUnit,
                    selectedGraphMetric: $selectedGraphMetric,
                    onLocationRequest: onLocationRequest
                )
                .transition(pageSwapTransition)
            case .stocks:
                NotchPlaceholderWidgetView(
                    page: .stocks,
                    layout: layout,
                    isExpanded: isExpanded,
                    presentationProgress: presentationProgress,
                    selectedPage: $selectedPage,
                    details: [
                        "Price change by symbol",
                        "Mini portfolio allocation strip",
                        "News movers and alerts"
                    ]
                )
                .transition(pageSwapTransition)
            case .tokenSpend:
                NotchPlaceholderWidgetView(
                    page: .tokenSpend,
                    layout: layout,
                    isExpanded: isExpanded,
                    presentationProgress: presentationProgress,
                    selectedPage: $selectedPage,
                    details: [
                        "Daily Anthropic spend",
                        "Model mix by project",
                        "Budget thresholds and alerts"
                    ]
                )
                .transition(pageSwapTransition)
            case .settings:
                NotchSettingsWidgetView(
                    layout: layout,
                    isExpanded: isExpanded,
                    presentationProgress: presentationProgress,
                    selectedPage: $selectedPage
                )
                .transition(pageSwapTransition)
            }
        }
        .animation(NotchMotion.pageTransitionAnimation, value: selectedPage)
    }

    private var hiddenToggleLayer: some View {
        notchToggleButton
            .allowsHitTesting(displayState == .hidden)
    }

    private var notchToggleButton: some View {
        Button(action: toggleCollapsedVisibility) {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(.black.opacity(0.16))
                .frame(width: NotchGeometry.width, height: max(layout.topBarHeight - 16, 28), alignment: .center)
                .shadow(color: .black.opacity(0.22), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var hoverTrackingLayer: some View {
        HoverTrackingView(
            trackingFrame: isExpanded
                ? NSRect(x: 0, y: 0, width: layout.expandedWidth, height: layout.topBarHeight + layout.expandedBodyHeight)
                : NSRect(x: 0, y: 0, width: layout.collapsedWidth, height: collapsedShellHeight),
            onHoverChanged: { hovering in
                handleHoverChange(hovering)
            }
        )
        .allowsHitTesting(false)
    }

    private func handleHoverChange(_ hovering: Bool) {
        guard displayState != .hidden else { return }

        if let suppressHoverUntil, suppressHoverUntil > Date() {
            return
        }

        if hovering {
            setDisplayState(.expanded)
        } else {
            setDisplayState(.collapsed)
        }
    }

    private func toggleCollapsedVisibility() {
        switch displayState {
        case .hidden:
            suppressHoverUntil = Date().addingTimeInterval(0.18)
            setDisplayState(.collapsed)
        case .collapsed, .expanded:
            setDisplayState(.hidden)
        }
    }

    private func setDisplayState(_ state: DisplayState) {
        guard displayState != state else { return }
        pendingHiddenResetToken = UUID()
        if state == .hidden {
            suppressHoverUntil = nil
        }

        if state == .hidden {
            let resetToken = pendingHiddenResetToken
            withAnimation(.easeInOut(duration: NotchMotion.hoverAnimationDuration)) {
                presentationProgress = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + NotchMotion.hoverAnimationDuration) {
                guard pendingHiddenResetToken == resetToken else { return }
                renderedState = .hidden
            }
        } else {
            withAnimation(.easeInOut(duration: NotchMotion.hoverAnimationDuration)) {
                renderedState = state
                presentationProgress = 1
            }
        }

        withAnimation(.easeInOut(duration: NotchMotion.hoverAnimationDuration)) {
            displayState = state
        }
        NotificationCenter.default.post(
            name: .notchPresentationStateDidChange,
            object: nil,
            userInfo: ["state": presentationStateName(for: state)]
        )
        onHoverChanged(state == .expanded)
    }

    private func presentationStateName(for state: DisplayState) -> String {
        switch state {
        case .hidden:
            return "hidden"
        case .collapsed:
            return "collapsed"
        case .expanded:
            return "expanded"
        }
    }

    private var islandBackground: some View {
        IslandShellShape(
            bottomCornerRadius: 22,
            notchWidth: NotchGeometry.width,
            notchDepth: NotchGeometry.height,
            notchTopCornerRadius: NotchGeometry.topCornerRadius,
            notchBottomCornerRadius: NotchGeometry.lowerCornerRadius
        )
        .fill(Color.black.opacity(0.96), style: FillStyle(eoFill: true))
        .overlay(
            IslandShellShape(
                bottomCornerRadius: 22,
                notchWidth: NotchGeometry.width,
                notchDepth: NotchGeometry.height,
                notchTopCornerRadius: NotchGeometry.topCornerRadius,
                notchBottomCornerRadius: NotchGeometry.lowerCornerRadius
            )
            .fill(.ultraThinMaterial, style: FillStyle(eoFill: true))
            .opacity(0.12)
        )
        .overlay(nativeBevel)
    }

    private var collapsedShellHeight: CGFloat {
        max(layout.topBarHeight - 4, 56)
    }

    private var pageSwapTransition: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.985, anchor: .center))
    }

    private var nativeBevel: some View {
        IslandShellShape(
            bottomCornerRadius: 22,
            notchWidth: NotchGeometry.width,
            notchDepth: NotchGeometry.height,
            notchTopCornerRadius: NotchGeometry.topCornerRadius,
            notchBottomCornerRadius: NotchGeometry.lowerCornerRadius
        )
        .stroke(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.26),
                    Color.white.opacity(0.08),
                    Color.black.opacity(0.26)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
        )
        .blendMode(.screen)
        .overlay(
            IslandShellShape(
                bottomCornerRadius: 22,
                notchWidth: NotchGeometry.width,
                notchDepth: NotchGeometry.height,
                notchTopCornerRadius: NotchGeometry.topCornerRadius,
                notchBottomCornerRadius: NotchGeometry.lowerCornerRadius
            )
            .stroke(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.25),
                        Color.clear,
                        Color.black.opacity(0.18)
                    ],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                ),
                style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
            )
            .blendMode(.multiply)
        )
    }
}

struct IslandShellShape: Shape {
    let bottomCornerRadius: CGFloat
    let notchWidth: CGFloat
    let notchDepth: CGFloat
    let notchTopCornerRadius: CGFloat
    let notchBottomCornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let bottomRadius = min(bottomCornerRadius, rect.height / 2)
        let topRadius = min(notchTopCornerRadius, notchDepth / 2)
        let lowerRadius = min(notchBottomCornerRadius, notchDepth / 2)
        let notchLeft = rect.midX - notchWidth / 2
        let notchRight = rect.midX + notchWidth / 2
        let notchBottom = rect.minY + notchDepth

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRadius))
        path.addArc(
            center: CGPoint(x: rect.maxX - bottomRadius, y: rect.maxY - bottomRadius),
            radius: bottomRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY - bottomRadius),
            radius: bottomRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()

        path.move(to: CGPoint(x: notchLeft + topRadius, y: rect.minY))
        path.addLine(to: CGPoint(x: notchRight - topRadius, y: rect.minY))
        path.addArc(
            center: CGPoint(x: notchRight - topRadius, y: rect.minY + topRadius),
            radius: topRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(360),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: notchRight, y: notchBottom - lowerRadius))
        path.addArc(
            center: CGPoint(x: notchRight - lowerRadius, y: notchBottom - lowerRadius),
            radius: lowerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: notchLeft + lowerRadius, y: notchBottom))
        path.addArc(
            center: CGPoint(x: notchLeft + lowerRadius, y: notchBottom - lowerRadius),
            radius: lowerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: notchLeft, y: rect.minY + topRadius))
        path.addArc(
            center: CGPoint(x: notchLeft + topRadius, y: rect.minY + topRadius),
            radius: topRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

private struct HoverTrackingView: NSViewRepresentable {
    let trackingFrame: NSRect
    let onHoverChanged: (Bool) -> Void

    func makeNSView(context: Context) -> HoverTrackingNSView {
        let view = HoverTrackingNSView()
        view.onHoverChanged = onHoverChanged
        view.frame = trackingFrame
        return view
    }

    func updateNSView(_ nsView: HoverTrackingNSView, context: Context) {
        nsView.onHoverChanged = onHoverChanged
        if nsView.frame != trackingFrame {
            nsView.frame = trackingFrame
        }
    }
}

private final class HoverTrackingNSView: NSView {
    var onHoverChanged: ((Bool) -> Void)?
    private var isHovering = false

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }

        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeInKeyWindow,
            .inVisibleRect
        ]
        addTrackingArea(NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) {
        guard !isHovering else { return }
        isHovering = true
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        guard isHovering else { return }
        isHovering = false
        onHoverChanged?(false)
    }
}
