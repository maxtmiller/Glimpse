import SwiftUI

struct InteractiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? 0.04 : 0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct NotchNavigationButton: View {
    let systemName: String
    let title: String
    @Binding var isHovered: Bool
    let action: () -> Void
    private let hoverFill = LinearGradient(
        colors: [Color.cyan.opacity(0.34), Color.blue.opacity(0.22)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isHovered ? AnyShapeStyle(hoverFill) : AnyShapeStyle(Color.black.opacity(0.94)))
                    .overlay(
                        Circle()
                            .stroke(isHovered ? Color.white.opacity(0.34) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: isHovered ? Color.cyan.opacity(0.20) : .black.opacity(0.20), radius: isHovered ? 4 : 2, y: 1)

                Image(systemName: systemName)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(isHovered ? Color.white : .white.opacity(0.92))
            }
            .frame(width: 24, height: 24)
        }
        .buttonStyle(InteractiveButtonStyle())
        .onHover { isHovered = $0 }
        .help(title)
    }
}

struct NotchSummaryBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.88))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.10))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

struct NotchHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

struct NotchSummaryHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    var showsSubtitle: Bool = true
    var iconAction: (() -> Void)? = nil
    var iconHelp: String? = nil
    @State private var isIconHovered = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Group {
                let iconView = ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.78), accent.opacity(0.48)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(isIconHovered ? Color.white.opacity(0.34) : Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.22), radius: 3, y: 1)
                        .scaleEffect(isIconHovered ? 1.04 : 1)

                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }

                if let iconAction {
                    Button(action: iconAction) {
                        iconView
                    }
                    .buttonStyle(InteractiveButtonStyle())
                    .onHover { isIconHovered = $0 }
                    .help(iconHelp ?? title)
                } else {
                    iconView
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if showsSubtitle {
                    Text(subtitle)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                }
            }
        }
        .padding(.leading, 4)
    }
}

struct NotchTile: View {
    let page: NotchPage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(page.accent.opacity(isSelected ? 0.34 : 0.20))
                        Image(systemName: page.symbol)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(page.accent)
                    }
                    .frame(width: 24, height: 24)

                    Spacer(minLength: 0)
                }

                Text(page.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(page.subtitle)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(9)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.09))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? page.accent.opacity(0.55) : Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.28 : 0.20), radius: 3, y: 1)
        }
        .buttonStyle(InteractiveButtonStyle())
    }
}

struct NotchRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))

            Spacer(minLength: 0)

            Text(value)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct NotchWidgetChrome<Leading: View, Trailing: View, Expanded: View>: View {
    let layout: PanelLayout
    let isExpanded: Bool
    let presentationProgress: CGFloat
    let leading: () -> Leading
    let trailing: () -> Trailing
    let expanded: () -> Expanded

    init(
        layout: PanelLayout,
        isExpanded: Bool,
        presentationProgress: CGFloat,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing,
        @ViewBuilder expanded: @escaping () -> Expanded
    ) {
        self.layout = layout
        self.isExpanded = isExpanded
        self.presentationProgress = presentationProgress
        self.leading = leading
        self.trailing = trailing
        self.expanded = expanded
    }

    var body: some View {
        let shellWidth = isExpanded ? layout.expandedWidth : layout.collapsedWidth
        let shellHeight = isExpanded ? layout.topBarHeight + layout.expandedBodyHeight : collapsedShellHeight
        let topReveal = revealProgress(
            presentationProgress,
            start: isExpanded ? 0.06 : 0.14,
            end: isExpanded ? 0.42 : 0.72
        )
        let sideWidth = max((shellWidth - NotchGeometry.width) / 2, 0)
        let lateralOffset = isExpanded ? 0 : 14 * revealProgress(presentationProgress, start: 0.12, end: 0.68)
        let leadingAlignment: Alignment = isExpanded ? .leading : .trailing
        let trailingAlignment: Alignment = isExpanded ? .trailing : .leading

        return ZStack(alignment: .top) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    leading()
                        .frame(width: sideWidth, alignment: leadingAlignment)
                        .offset(x: -lateralOffset)

                    Color.clear
                        .frame(width: NotchGeometry.width)

                    trailing()
                        .frame(width: sideWidth, alignment: trailingAlignment)
                        .offset(x: lateralOffset)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .frame(height: layout.topBarHeight - 16, alignment: .center)
                .opacity(topReveal)
                .offset(y: (1 - topReveal) * -2)

                expanded()
                    .frame(height: isExpanded ? layout.expandedBodyHeight : 0, alignment: .top)
                    .opacity(isExpanded ? 1 : 0)
                    .clipped()
            }
            .frame(width: shellWidth, height: shellHeight, alignment: .top)
        }
        .frame(width: shellWidth, height: shellHeight, alignment: .top)
    }

    private var collapsedShellHeight: CGFloat {
        max(layout.topBarHeight - 4, 56)
    }

    private func revealProgress(_ progress: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
        guard end > start else { return progress >= end ? 1 : 0 }
        let clamped = max(0, min(1, (progress - start) / (end - start)))
        return clamped * clamped * (3 - 2 * clamped)
    }
}
