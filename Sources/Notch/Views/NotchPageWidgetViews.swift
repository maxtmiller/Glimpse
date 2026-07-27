import SwiftUI

struct NotchHomeWidgetView: View {
    let layout: PanelLayout
    let isExpanded: Bool
    let presentationProgress: CGFloat
    @Binding var selectedPage: NotchPage
    @StateObject private var batteryMonitor = BatteryMonitor()

    var body: some View {
        NotchWidgetChrome(
            layout: layout,
            isExpanded: isExpanded,
            presentationProgress: presentationProgress,
            leading: {
                NotchSummaryHeader(
                    icon: "square.grid.2x2.fill",
                    title: "Home",
                    subtitle: "Widgets",
                    accent: Color.cyan,
                    showsSubtitle: isExpanded
                )
            },
            trailing: {
                HStack(spacing: 5) {
                    if !isExpanded {
                        BatteryIndicator(reading: batteryMonitor.reading)
                    }
                }
                .padding(.trailing, 4)
            },
                expanded: {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .bottom) {
                        NotchHeader(
                            title: "Your widgets",
                            subtitle: "Choose an app to take over the panel."
                        )

                        Spacer(minLength: 0)

                        Text("5 APPS")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                            .tracking(0.8)
                    }

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(NotchPage.allCases.filter { $0 != .home }) { page in
                            HomeAppTile(page: page, isSelected: selectedPage == page) {
                                withAnimation(NotchMotion.pageTransitionAnimation) {
                                    selectedPage = page
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        )
    }
}

private struct HomeAppTile: View {
    let page: NotchPage
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [page.accent.opacity(isHovered ? 0.48 : 0.30), page.accent.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: page.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 34, height: 34)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(page.accent.opacity(isHovered ? 0.64 : 0.22), lineWidth: 1)
                )
                .shadow(color: page.accent.opacity(isHovered ? 0.22 : 0.08), radius: isHovered ? 10 : 4, y: 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(page.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(page.subtitle)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.54))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(isHovered ? 0.92 : 0.34))
                    .offset(x: isHovered ? 2 : 0, y: isHovered ? -2 : 0)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.075))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? page.accent.opacity(0.72) : Color.white.opacity(isHovered ? 0.24 : 0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isHovered ? 0.34 : 0.18), radius: isHovered ? 12 : 5, y: isHovered ? 5 : 2)
            .scaleEffect(isHovered ? 1.018 : 1)
            .animation(.easeOut(duration: 0.18), value: isHovered)
        }
        .buttonStyle(InteractiveButtonStyle())
        .onHover { isHovered = $0 }
    }
}

private struct BatteryIndicator: View {
    let reading: BatteryReading?

    private var fillColor: Color {
        guard let reading else { return .white.opacity(0.45) }
        if reading.percentage <= 20 && !reading.isCharging { return .red }
        return reading.isCharging ? .green : .white.opacity(0.88)
    }

    var body: some View {
        HStack(spacing: 5) {
            HStack(spacing: 1.5) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)

                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(fillColor)
                            .frame(width: proxy.size.width * CGFloat(reading?.percentage ?? 0) / 100)
                            .padding(1.5)
                    }
                }
                .frame(width: 25, height: 13)

                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.72))
                    .frame(width: 2, height: 5)
            }

            Text(reading.map { "\($0.percentage)%" } ?? "—")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .monospacedDigit()
        }
        .help(reading.map { "Battery: \($0.percentage)%" } ?? "Battery unavailable")
    }
}

struct NotchPlaceholderWidgetView: View {
    let page: NotchPage
    let layout: PanelLayout
    let isExpanded: Bool
    let presentationProgress: CGFloat
    @Binding var selectedPage: NotchPage
    let details: [String]
    @State private var isHomeButtonHovered = false
    @State private var isSettingsButtonHovered = false

    var body: some View {
        NotchWidgetChrome(
            layout: layout,
            isExpanded: isExpanded,
            presentationProgress: presentationProgress,
            leading: {
                HStack(spacing: 10) {
                    NotchSummaryHeader(
                        icon: page.symbol,
                        title: page.title,
                        subtitle: page.subtitle,
                        accent: page.accent,
                        showsSubtitle: isExpanded
                    )

                    if isExpanded {
                        Spacer(minLength: 0)

                        NotchNavigationButton(
                            systemName: "house.fill",
                            title: "Home",
                            isHovered: $isHomeButtonHovered
                        ) {
                            withAnimation(NotchMotion.pageTransitionAnimation) {
                                selectedPage = .home
                            }
                        }
                        .offset(x: -4)
                    }
                }
            },
            trailing: {
                HStack(spacing: 10) {
                    if isExpanded {
                        NotchNavigationButton(
                            systemName: "gearshape.fill",
                            title: "Settings",
                            isHovered: $isSettingsButtonHovered
                        ) {
                            withAnimation(NotchMotion.pageTransitionAnimation) {
                                selectedPage = .settings
                            }
                        }
                        .offset(x: 4)

                        Spacer(minLength: 0)
                    }

                    HStack(spacing: 5) {
                        NotchSummaryBadge(text: badgeOne)
                        NotchSummaryBadge(text: badgeTwo)
                    }
                }
                .padding(.trailing, 4)
            },
            expanded: {
                VStack(alignment: .leading, spacing: 10) {
                    NotchHeader(title: page.title, subtitle: page.subtitle)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(details, id: \.self) { detail in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.white.opacity(0.22))
                                    .frame(width: 6, height: 6)
                                Text(detail)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.74))
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        )
    }

    private var badgeOne: String {
        switch page {
        case .markets: return "AAPL"
        case .tokenSpend: return "Anthropic"
        default: return page.title
        }
    }

    private var badgeTwo: String {
        switch page {
        case .markets: return "MSFT"
        case .tokenSpend: return "Today"
        default: return "More"
        }
    }

}

struct NotchSettingsWidgetView: View {
    let layout: PanelLayout
    let isExpanded: Bool
    let presentationProgress: CGFloat
    @Binding var selectedPage: NotchPage
    @State private var isHomeButtonHovered = false
    @State private var isSettingsButtonHovered = false

    var body: some View {
        NotchWidgetChrome(
            layout: layout,
            isExpanded: isExpanded,
            presentationProgress: presentationProgress,
            leading: {
                HStack(spacing: 10) {
                    NotchSummaryHeader(
                        icon: "gearshape.fill",
                        title: "Settings",
                        subtitle: "Prefs",
                        accent: Color.white.opacity(0.9),
                        showsSubtitle: isExpanded
                    )

                    if isExpanded {
                        Spacer(minLength: 0)

                        NotchNavigationButton(
                            systemName: "house.fill",
                            title: "Home",
                            isHovered: $isHomeButtonHovered
                        ) {
                            withAnimation(NotchMotion.pageTransitionAnimation) {
                                selectedPage = .home
                            }
                        }
                        .offset(x: -4)
                    }
                }
            },
            trailing: {
                HStack(spacing: 10) {
                    if isExpanded {
                        NotchNavigationButton(
                            systemName: "gearshape.fill",
                            title: "Settings",
                            isHovered: $isSettingsButtonHovered
                        ) {
                            withAnimation(NotchMotion.pageTransitionAnimation) {
                                selectedPage = .settings
                            }
                        }
                        .offset(x: 4)

                        Spacer(minLength: 0)
                    }

                    HStack(spacing: 5) {
                        NotchSummaryBadge(text: "Panel")
                        NotchSummaryBadge(text: "Theme")
                    }
                }
                .padding(.trailing, 4)
            },
            expanded: {
                VStack(alignment: .leading, spacing: 10) {
                    NotchHeader(
                        title: "Settings",
                        subtitle: "Scaffold for panel controls and preferences."
                    )

                    VStack(spacing: 8) {
                        NotchRow(title: "Launch at login", value: "Soon")
                        NotchRow(title: "Compact mode", value: "Soon")
                        NotchRow(title: "Default widget", value: selectedPage == .home ? "Home" : selectedPage.title)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        )
    }
}
