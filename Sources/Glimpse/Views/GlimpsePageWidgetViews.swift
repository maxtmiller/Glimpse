import AppKit
import ServiceManagement
import SwiftUI

struct GlimpseHomeWidgetView: View {
    let layout: PanelLayout
    let isExpanded: Bool
    let presentationProgress: CGFloat
    @Binding var selectedPage: GlimpsePage
    @StateObject private var batteryMonitor = BatteryMonitor()
    @State private var isSettingsButtonHovered = false
    @State private var isQuitButtonHovered = false

    var body: some View {
        GlimpseWidgetChrome(
            layout: layout,
            isExpanded: isExpanded,
            presentationProgress: presentationProgress,
            leading: {
                HStack(spacing: 10) {
                    GlimpseSummaryHeader(
                        icon: "square.grid.2x2.fill",
                        title: "Home",
                        subtitle: "Widgets",
                        accent: Color.cyan,
                        showsSubtitle: isExpanded
                    )

                    if isExpanded {
                        Spacer(minLength: 0)

                        GlimpseNavigationButton(
                            systemName: "power",
                            title: "Quit Glimpse",
                            isHovered: $isQuitButtonHovered
                        ) {
                            NSApp.terminate(nil)
                        }
                        .offset(x: -4)
                    }
                }
            },
            trailing: {
                HStack(spacing: 10) {
                    if isExpanded {
                        GlimpseNavigationButton(
                            systemName: "gearshape.fill",
                            title: "Settings",
                            isHovered: $isSettingsButtonHovered
                        ) {
                            withAnimation(GlimpseMotion.pageTransitionAnimation) {
                                selectedPage = .settings
                            }
                        }
                        .offset(x: 4)

                        Spacer(minLength: 0)
                    } else {
                        BatteryIndicator(reading: batteryMonitor.reading)
                    }
                }
                .padding(.trailing, 4)
            },
                expanded: {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .bottom) {
                        GlimpseHeader(
                            title: "Your widgets",
                            subtitle: "Choose an app to take over the panel."
                        )

                        Spacer(minLength: 0)

                        Text("\(GlimpsePage.widgetPages.count) APPS")
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
                        ForEach(GlimpsePage.widgetPages) { page in
                            HomeAppTile(page: page, isSelected: selectedPage == page) {
                                withAnimation(GlimpseMotion.pageTransitionAnimation) {
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
    let page: GlimpsePage
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
        switch reading.percentage {
        case 0...10: return .red
        case 11...20: return .orange
        case 21...50: return .yellow
        default: return .green
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            HStack(spacing: 1.5) {
                ZStack {
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

                    if reading?.isCharging == true {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.45), radius: 1)
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
        .help(reading.map {
            "Battery: \($0.percentage)% · \($0.isCharging ? "Charging" : ($0.isPluggedIn ? "Plugged in" : "Not charging"))"
        } ?? "Battery unavailable")
    }
}

struct GlimpsePlaceholderWidgetView: View {
    let page: GlimpsePage
    let layout: PanelLayout
    let isExpanded: Bool
    let presentationProgress: CGFloat
    @Binding var selectedPage: GlimpsePage
    let details: [String]
    @State private var isHomeButtonHovered = false
    @State private var isSettingsButtonHovered = false

    var body: some View {
        GlimpseWidgetChrome(
            layout: layout,
            isExpanded: isExpanded,
            presentationProgress: presentationProgress,
            leading: {
                HStack(spacing: 10) {
                    GlimpseSummaryHeader(
                        icon: page.symbol,
                        title: page.title,
                        subtitle: page.subtitle,
                        accent: page.accent,
                        showsSubtitle: isExpanded
                    )

                    if isExpanded {
                        Spacer(minLength: 0)

                        GlimpseNavigationButton(
                            systemName: "house.fill",
                            title: "Home",
                            isHovered: $isHomeButtonHovered
                        ) {
                            withAnimation(GlimpseMotion.pageTransitionAnimation) {
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
                        GlimpseNavigationButton(
                            systemName: "gearshape.fill",
                            title: "Settings",
                            isHovered: $isSettingsButtonHovered
                        ) {
                            withAnimation(GlimpseMotion.pageTransitionAnimation) {
                                selectedPage = .settings
                            }
                        }
                        .offset(x: 4)

                        Spacer(minLength: 0)
                    }

                    HStack(spacing: 5) {
                        GlimpseSummaryBadge(text: badgeOne)
                        GlimpseSummaryBadge(text: badgeTwo)
                    }
                }
                .padding(.trailing, 4)
            },
            expanded: {
                VStack(alignment: .leading, spacing: 10) {
                    GlimpseHeader(title: page.title, subtitle: page.subtitle)

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
        default: return page.title
        }
    }

    private var badgeTwo: String {
        switch page {
        case .markets: return "MSFT"
        default: return "More"
        }
    }

}

struct GlimpseSettingsWidgetView: View {
    let layout: PanelLayout
    let isExpanded: Bool
    let presentationProgress: CGFloat
    @Binding var selectedPage: GlimpsePage
    let previousPage: GlimpsePage
    @State private var isHomeButtonHovered = false
    @State private var isBackButtonHovered = false
    @AppStorage("glimpse.defaultPage") private var defaultPageRawValue = GlimpsePage.home.rawValue
    @AppStorage("glimpse.panelAppearance") private var panelAppearanceRawValue = PanelAppearance.solid.rawValue
    @AppStorage("glimpse.expandBehavior") private var expandBehaviorRawValue = GlimpseExpandBehavior.hover.rawValue
    @State private var launchesAtLogin = false
    @State private var showingResetConfirmation = false
    @State private var settingsMessage: String?

    var body: some View {
        GlimpseWidgetChrome(
            layout: layout,
            isExpanded: isExpanded,
            presentationProgress: presentationProgress,
            leading: {
                HStack(spacing: 10) {
                    GlimpseSummaryHeader(
                        icon: "gearshape.fill",
                        title: "Settings",
                        subtitle: "Prefs",
                        accent: Color.white.opacity(0.9),
                        showsSubtitle: isExpanded
                    )

                    if isExpanded {
                        Spacer(minLength: 0)

                        GlimpseNavigationButton(
                            systemName: "house.fill",
                            title: "Home",
                            isHovered: $isHomeButtonHovered
                        ) {
                            withAnimation(GlimpseMotion.pageTransitionAnimation) {
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
                        GlimpseNavigationButton(
                            systemName: "arrow.left",
                            title: "Back",
                            isHovered: $isBackButtonHovered
                        ) {
                            withAnimation(GlimpseMotion.pageTransitionAnimation) {
                                selectedPage = previousPage
                            }
                        }
                        .offset(x: 4)

                        Spacer(minLength: 0)
                    }

                    HStack(spacing: 5) {
                        GlimpseSummaryBadge(text: selectedExpandBehavior.title)
                        GlimpseSummaryBadge(text: "v\(appVersion)")
                    }
                }
                .padding(.trailing, 4)
            },
            expanded: {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ],
                            spacing: 10
                        ) {
                            settingsToggleRow(
                                title: "Launch at login",
                                detail: "Open Glimpse when you sign in",
                                isOn: $launchesAtLogin,
                                action: setLaunchAtLogin
                            )

                            settingsPickerRow(title: "Default page", detail: "Shown after the first launch") {
                                Picker("Default page", selection: $defaultPageRawValue) {
                                    ForEach(GlimpsePage.startupPages) { page in
                                        Text(page.title).tag(page.rawValue)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 120)
                            }

                            settingsPickerRow(title: "Panel appearance", detail: "Background style") {
                                Picker("Panel appearance", selection: $panelAppearanceRawValue) {
                                    ForEach(PanelAppearance.allCases) { appearance in
                                        Text(appearance.title).tag(appearance.rawValue)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 120)
                            }

                            settingsPickerRow(title: "Expand behavior", detail: "Hover or click to open") {
                                Picker("Expand behavior", selection: $expandBehaviorRawValue) {
                                    ForEach(GlimpseExpandBehavior.allCases) { behavior in
                                        Text(behavior.title).tag(behavior.rawValue)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 120)
                            }

                            settingsActionRow(title: "Diagnostics", detail: "View app and system information") {
                                showDiagnostics()
                            }

                            settingsActionRow(title: "Reset settings", detail: "Restore the default preferences", isDestructive: true) {
                                showingResetConfirmation = true
                            }
                        }

                        HStack {
                            Text("Version")
                                .foregroundStyle(.white.opacity(0.52))
                            Spacer()
                            Text(appVersion)
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        )
        .task { launchesAtLogin = loginItemIsEnabled }
        .alert("Reset settings?", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive, action: resetSettings)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This restores the default page, theme, and launch-at-login setting.")
        }
        .alert("Settings", isPresented: Binding(
            get: { settingsMessage != nil },
            set: { if !$0 { settingsMessage = nil } }
        )) {
            Button("OK", role: .cancel) { settingsMessage = nil }
        } message: {
            Text(settingsMessage ?? "")
        }
    }

    private var selectedExpandBehavior: GlimpseExpandBehavior {
        GlimpseExpandBehavior(rawValue: expandBehaviorRawValue) ?? .hover
    }

    private var usesGlassAppearance: Bool {
        PanelAppearance(rawValue: panelAppearanceRawValue) == .glass
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version ?? "Development"
    }

    private var loginItemIsEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    private var diagnosticsText: String {
        "Glimpse \(appVersion)\nmacOS \(ProcessInfo.processInfo.operatingSystemVersionString)\nStartup page: Home\nLaunch at login: \(launchItemStatus)"
    }

    private var launchItemStatus: String {
        switch SMAppService.mainApp.status {
        case .enabled: return "Enabled"
        case .requiresApproval: return "Requires approval"
        case .notRegistered: return "Disabled"
        case .notFound: return "Unavailable"
        @unknown default: return "Unknown"
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchesAtLogin = loginItemIsEnabled
        } catch {
            launchesAtLogin = loginItemIsEnabled
            settingsMessage = "Could not update Launch at login: \(error.localizedDescription)"
        }
    }

    private func resetSettings() {
        defaultPageRawValue = GlimpsePage.home.rawValue
        panelAppearanceRawValue = PanelAppearance.solid.rawValue
        expandBehaviorRawValue = GlimpseExpandBehavior.hover.rawValue
        setLaunchAtLogin(false)
    }

    private func showDiagnostics() {
        let alert = NSAlert()
        alert.messageText = "Diagnostics"
        alert.informativeText = diagnosticsText
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Done")

        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let alertFrame = alert.window.frame
            let visibleFrame = screen.visibleFrame
            alert.window.setFrameOrigin(NSPoint(
                x: visibleFrame.midX - alertFrame.width / 2,
                y: visibleFrame.midY - alertFrame.height / 2
            ))
        }

        // SwiftUI alerts attach to the glimpse panel. A native modal alert is
        // explicitly centered on the main display instead of appearing over the glimpse.
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @ViewBuilder
    private func settingsToggleRow(title: String, detail: String, isOn: Binding<Bool>, action: @escaping (Bool) -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(.white)
                Text(detail).foregroundStyle(.white.opacity(0.48))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .onChange(of: isOn.wrappedValue, perform: action)
        }
        .font(.system(size: 10, weight: .medium, design: .rounded))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(usesGlassAppearance ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color(red: 0.16, green: 0.17, blue: 0.19)))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(usesGlassAppearance ? Color.white.opacity(0.28) : Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func settingsPickerRow<Control: View>(title: String, detail: String, @ViewBuilder control: () -> Control) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(.white)
                Text(detail).foregroundStyle(.white.opacity(0.48))
            }
            Spacer()
            control()
        }
        .font(.system(size: 10, weight: .medium, design: .rounded))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(usesGlassAppearance ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color(red: 0.16, green: 0.17, blue: 0.19)))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(usesGlassAppearance ? Color.white.opacity(0.28) : Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func settingsActionRow(title: String, detail: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(isDestructive ? .red.opacity(0.9) : .white)
                    Text(detail).foregroundStyle(.white.opacity(0.48))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.38))
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(usesGlassAppearance ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(Color(red: 0.16, green: 0.17, blue: 0.19)))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(usesGlassAppearance ? Color.white.opacity(0.28) : Color.white.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(InteractiveButtonStyle())
    }
}

enum PanelAppearance: String, CaseIterable, Identifiable {
    case solid
    case balanced
    case glass

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var baseColor: Color {
        switch self {
        case .solid: return Color.black
        case .balanced: return Color.black.opacity(0.72)
        case .glass: return Color.black.opacity(0.45)
        }
    }

    var materialOpacity: Double {
        switch self {
        case .solid: return 0
        case .balanced: return 0.35
        case .glass: return 0.70
        }
    }
}

enum GlimpseExpandBehavior: String, CaseIterable, Identifiable {
    case hover
    case click

    var id: String { rawValue }

    var title: String { rawValue.capitalized }
}
