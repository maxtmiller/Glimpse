import AppKit
import SwiftUI

struct NotchWeatherView: View {
    private struct InteractiveButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .brightness(configuration.isPressed ? 0.04 : 0)
                .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
        }
    }

    private enum TemperatureUnit {
        case fahrenheit
        case celsius

        var displaySymbol: String {
            switch self {
            case .fahrenheit: return "F"
            case .celsius: return "C"
            }
        }

        var toggled: TemperatureUnit {
            switch self {
            case .fahrenheit: return .celsius
            case .celsius: return .fahrenheit
            }
        }
    }

    private enum GraphMetric: Hashable {
        case temperature
        case feelsLike
        case humidity
        case wind

        var title: String {
            switch self {
            case .temperature: return "Temperature"
            case .feelsLike: return "Feels like"
            case .humidity: return "Humidity"
            case .wind: return "Wind (mph)"
            }
        }

        var accentColor: Color {
            switch self {
            case .temperature: return Color.cyan
            case .feelsLike: return Color.blue
            case .humidity: return Color.cyan.opacity(0.92)
            case .wind: return Color.blue.opacity(0.88)
            }
        }
    }

    let snapshot: WeatherSnapshot
    let layout: PanelLayout
    let onHoverChanged: (Bool) -> Void
    let onLocationRequest: () -> Void

    @State private var isExpanded = false
    @State private var temperatureUnit: TemperatureUnit = .fahrenheit
    @State private var selectedGraphMetric: GraphMetric?
    @State private var isLocationButtonHovered = false
    @State private var isUnitButtonHovered = false
    @State private var hoveredMetric: GraphMetric?
    @State private var isRetryButtonHovered = false

    var body: some View {
        let shellWidth = isExpanded ? layout.expandedWidth : layout.collapsedWidth
        let shellHeight = isExpanded ? layout.topBarHeight + layout.expandedBodyHeight : collapsedShellHeight
        let interactionHeight = layout.topBarHeight + layout.expandedBodyHeight

        ZStack {
            hoverTrackingLayer

            islandBackground
                .frame(width: shellWidth, height: shellHeight, alignment: .top)

            VStack(spacing: 0) {
                topRow

                bodyContent
                    .frame(height: isExpanded ? layout.expandedBodyHeight : 0, alignment: .top)
                    .opacity(isExpanded ? 1 : 0)
                    .clipped()
            }
            .frame(width: shellWidth, height: shellHeight, alignment: .top)
        }
        .frame(width: layout.expandedWidth, height: interactionHeight, alignment: .top)
        .ignoresSafeArea()
    }

    private var hoverTrackingLayer: some View {
        HoverTrackingView(
            trackingFrame: isExpanded
                ? NSRect(x: 0, y: 0, width: layout.expandedWidth, height: layout.topBarHeight + layout.expandedBodyHeight)
                : NSRect(x: 0, y: 0, width: layout.collapsedWidth, height: collapsedShellHeight),
            onHoverChanged: { hovering in
                if hovering {
                    setExpanded(true)
                } else {
                    setExpanded(false)
                }
            }
        )
        .frame(
            width: isExpanded ? layout.expandedWidth : layout.collapsedWidth,
            height: isExpanded ? layout.topBarHeight + layout.expandedBodyHeight : collapsedShellHeight,
            alignment: .top
        )
        .allowsHitTesting(false)
    }

    private func setExpanded(_ expanded: Bool) {
        guard isExpanded != expanded else { return }
        withAnimation(.easeInOut(duration: NotchMotion.hoverAnimationDuration)) {
            isExpanded = expanded
        }
        onHoverChanged(expanded)
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

    private var topRow: some View {
        let currentWidth = isExpanded ? layout.expandedWidth : layout.collapsedWidth
        let sideWidth = max((currentWidth - NotchGeometry.width) / 2, 0)
        let horizontalInset: CGFloat = isExpanded ? 10 : 10
        let leadingAlignment: Alignment = isExpanded ? .leading : .trailing
        let trailingAlignment: Alignment = isExpanded ? .trailing : .leading

        return HStack(spacing: 0) {
            leadingSummary
                .frame(width: sideWidth, alignment: leadingAlignment)
                .offset(x: isExpanded ? 0 : -14)

            Color.clear
                .frame(width: NotchGeometry.width)

            trailingSummary
                .frame(width: sideWidth, alignment: trailingAlignment)
                .offset(x: isExpanded ? 0 : 14)
        }
        .padding(.horizontal, horizontalInset)
        .padding(.vertical, 4)
        .frame(height: layout.topBarHeight - 16, alignment: .center)
    }

    private var bodyContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.city)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(snapshot.condition)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    metricPill(
                        metric: .feelsLike,
                        title: "Feels like",
                        value: displayMetricValue(convertedTemperature(snapshot.feelsLike), suffix: "°"),
                        width: 84
                    )
                    metricPill(metric: .humidity, title: "Humidity", value: displayMetricValue(snapshot.humidity, suffix: "%"), width: 76)
                    metricPill(metric: .wind, title: "Wind", value: displayMetricValue(snapshot.wind, suffix: " mph"), width: 72)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .trailing, spacing: 2) {
                    statText(title: "High", value: displayMetricValue(convertedTemperature(snapshot.high), suffix: "°"))
                    statText(title: "Low", value: displayMetricValue(convertedTemperature(snapshot.low), suffix: "°"))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            forecastGraph
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var leadingSummary: some View {
        let isHovered = isLocationButtonHovered

        return HStack(alignment: .center, spacing: 10) {
            Button(action: onLocationRequest) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: snapshot.hasLiveData
                                    ? [Color.orange, Color.yellow.opacity(0.88)]
                                    : [Color.blue.opacity(0.72), Color.cyan.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(isHovered ? Color.white.opacity(0.42) : Color.white.opacity(0.30), lineWidth: 1)
                        )
                        .shadow(color: isHovered ? Color.cyan.opacity(0.24) : .black.opacity(0.28), radius: isHovered ? 5 : 3, y: 1)
                        .scaleEffect(isHovered ? 1.04 : 1)

                    Image(systemName: snapshot.hasLiveData ? snapshot.symbol : "cloud.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(InteractiveButtonStyle())
            .onHover { isLocationButtonHovered = $0 }
            .help(snapshot.hasLiveData ? "Refresh location" : "Enable location services")

            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.displayLocationLabel)
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.leading, 4)
    }

    private var trailingSummary: some View {
        HStack(spacing: 10) {
            temperatureChip
            unitToggleButton
        }
        .padding(.trailing, 4)
    }

    private var temperatureChip: some View {
        HStack(spacing: 2) {
            Text(displayMetricValue(temperatureDisplay(snapshot.temperature)))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            if snapshot.hasLiveData {
                Text("°\(temperatureUnit.displaySymbol)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.white.opacity(0.08), in: Capsule())
    }

    private func displayMetricValue(_ value: Int, suffix: String = "") -> String {
        guard snapshot.hasLiveData else { return "-" }
        return "\(value)\(suffix)"
    }

    private func displayMetricValue(_ value: String) -> String {
        guard snapshot.hasLiveData else { return "-" }
        return value
    }

    private var unitToggleButton: some View {
        let isHovered = isUnitButtonHovered

        return Button {
            withAnimation(.easeInOut(duration: NotchMotion.hoverAnimationDuration)) {
                temperatureUnit = temperatureUnit.toggled
            }
        } label: {
            Text(temperatureUnit.toggled.displaySymbol)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(
                    Capsule(style: .continuous)
                        .fill(isHovered ? Color.white.opacity(0.22) : Color.white.opacity(0.15))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isHovered ? Color.white.opacity(0.42) : Color.white.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: isHovered ? Color.cyan.opacity(0.16) : .black.opacity(0.22), radius: isHovered ? 5 : 3, y: 1)
                .scaleEffect(isHovered ? 1.04 : 1)
        }
        .buttonStyle(InteractiveButtonStyle())
        .onHover { isUnitButtonHovered = $0 }
        .help("Switch to \(temperatureUnit.toggled.displaySymbol)")
    }

    private func metricPill(metric: GraphMetric, title: String, value: String, width: CGFloat) -> some View {
        let isSelected = selectedGraphMetric == metric
        let isHovered = hoveredMetric == metric

        return Button {
            withAnimation(.easeInOut(duration: NotchMotion.hoverAnimationDuration)) {
                selectedGraphMetric = (selectedGraphMetric == metric) ? nil : metric
            }
        } label: {
            MetricPillLabel(
                title: title,
                value: value,
                width: width,
                isSelected: isSelected,
                isHovered: isHovered
            )
        }
        .buttonStyle(InteractiveButtonStyle())
        .onHover { hovering in
            hoveredMetric = hovering ? metric : (hoveredMetric == metric ? nil : hoveredMetric)
        }
    }

    private func statText(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
    }

    private var forecastGraph: some View {
        VStack(alignment: .leading, spacing: 6) {
            if snapshot.hasLiveData {
                Text(selectedGraphMetric?.title ?? GraphMetric.temperature.title)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))

                TimelineView(.periodic(from: Date(), by: 60)) { timeline in
                    GeometryReader { geometry in
                        let metric = selectedGraphMetric ?? .temperature
                        let values = graphSeries(for: metric)
                        let points = graphPoints(in: geometry.size, values: values)

                        ZStack {
                            if points.count > 1 {
                                Path { path in
                                    path.move(to: points[0])
                                    for point in points.dropFirst() {
                                        path.addLine(to: point)
                                    }
                                }
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            (selectedGraphMetric?.accentColor ?? Color.cyan).opacity(0.95),
                                            Color.white.opacity(0.72)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                                )

                                Path { path in
                                    guard let first = points.first, let last = points.last else { return }
                                    path.move(to: CGPoint(x: first.x, y: geometry.size.height - 6))
                                    path.addLine(to: first)
                                    for point in points.dropFirst() {
                                        path.addLine(to: point)
                                    }
                                    path.addLine(to: CGPoint(x: last.x, y: geometry.size.height - 6))
                                    path.closeSubpath()
                                }
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            (selectedGraphMetric?.accentColor ?? Color.cyan).opacity(0.22),
                                            (selectedGraphMetric?.accentColor ?? Color.cyan).opacity(0.06),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }

                            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                                let isCurrentHour = isCurrentHour(snapshot.hourly[index], at: timeline.date)

                                VStack(spacing: 3) {
                                    Text(graphValueLabel(values[index], metric: metric, hour: snapshot.hourly[index]))
                                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                        .foregroundStyle(isCurrentHour ? Color.red.opacity(0.95) : Color.white.opacity(0.78))
                                        .contentTransition(.numericText())

                                    Circle()
                                        .fill(isCurrentHour ? Color.red : Color.white)
                                        .frame(width: 5, height: 5)
                                        .shadow(color: isCurrentHour ? Color.red.opacity(0.35) : .black.opacity(0.18), radius: 2, y: 1)
                                }
                                .position(x: point.x, y: point.y - 6)
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: timeline.date)
                }
                .frame(height: 72)

                HStack(spacing: 0) {
                    ForEach(snapshot.hourly) { hour in
                        Group {
                            if shouldShowGraphTimeLabel(at: hour.hour, total: snapshot.hourly.count) {
                                Text(hour.hour)
                                    .font(.system(size: 10.0, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.58))
                                    .fixedSize(horizontal: true, vertical: false)
                            } else {
                                Color.clear
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                let isHovered = isRetryButtonHovered

                VStack(spacing: 10) {
                    Button(action: onLocationRequest) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.72), Color.cyan.opacity(0.55)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .stroke(isHovered ? Color.white.opacity(0.42) : Color.white.opacity(0.30), lineWidth: 1)
                                )
                                .shadow(color: isHovered ? Color.cyan.opacity(0.24) : .black.opacity(0.28), radius: isHovered ? 5 : 3, y: 1)
                                .scaleEffect(isHovered ? 1.04 : 1)

                            Image(systemName: "cloud.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(InteractiveButtonStyle())
                    .onHover { isRetryButtonHovered = $0 }

                    Text("Enable location services")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))

                    Text("Tap the cloud to request access")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 4)
            }
        }
    }

    private func graphSeries(for metric: GraphMetric) -> [Double] {
        return snapshot.hourly.map { hour in
            let temp = Double(convertedTemperature(hour.temperature))
            switch metric {
            case .temperature:
                return temp
            case .feelsLike:
                return Double(convertedTemperature(hour.feelsLike))
            case .humidity:
                return Double(hour.humidity)
            case .wind:
                return Double(hour.wind)
            }
        }
    }

    private func isCurrentHour(_ hour: WeatherSnapshot.HourlyForecast, at date: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = currentTimeZone()
        return calendar.isDate(hour.date, equalTo: date, toGranularity: .hour)
    }

    private func currentTimeZone() -> TimeZone {
        TimeZone(identifier: snapshot.timeZoneIdentifier) ?? .current
    }

    private func graphPoints(in size: CGSize, values: [Double]) -> [CGPoint] {
        guard !values.isEmpty else { return [] }

        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let span = max(maxValue - minValue, 1)

        let horizontalInset: CGFloat = 8
        let topInset: CGFloat = 10
        let bottomInset: CGFloat = 14
        let width = max(size.width - horizontalInset * 2, 1)
        let height = max(size.height - topInset - bottomInset, 1)
        let step = values.count > 1 ? width / CGFloat(values.count - 1) : 0

        return values.enumerated().map { index, value in
            let x = horizontalInset + CGFloat(index) * step
            let normalized = CGFloat(value - minValue) / CGFloat(span)
            let y = topInset + (1 - normalized) * height
            return CGPoint(x: x, y: y)
        }
    }

    private func graphValueLabel(_ value: Double, metric: GraphMetric, hour: WeatherSnapshot.HourlyForecast) -> String {
        let rounded = Int(value.rounded())
        switch metric {
        case .temperature, .feelsLike:
            return "\(rounded)°"
        case .humidity:
            return "\(rounded)%"
        case .wind:
            return "\(rounded) \(windArrow(for: hour.windDirectionDegrees))"
        }
    }

    private func windArrow(for degrees: Int) -> String {
        let normalized = ((degrees % 360) + 360) % 360
        switch normalized {
        case 23..<68:
            return "↗"
        case 68..<113:
            return "→"
        case 113..<158:
            return "↘"
        case 158..<203:
            return "↓"
        case 203..<248:
            return "↙"
        case 248..<293:
            return "←"
        case 293..<338:
            return "↖"
        default:
            return "↑"
        }
    }

    private func shouldShowGraphTimeLabel(at hourLabel: String, total: Int) -> Bool {
        guard total > 0 else { return false }

        if hourLabel == snapshot.hourly.first?.hour || hourLabel == snapshot.hourly.last?.hour {
            return true
        }

        return snapshot.hourly.firstIndex(where: { $0.hour == hourLabel }).map { $0 % 4 == 0 } ?? false
    }

    private func temperatureDisplay(_ value: Int) -> String {
        switch temperatureUnit {
        case .fahrenheit:
            return "\(value)"
        case .celsius:
            let converted = Int(((Double(value) - 32.0) * 5.0 / 9.0).rounded())
            return "\(converted)"
        }
    }

    private func convertedTemperature(_ value: Int) -> Int {
        switch temperatureUnit {
        case .fahrenheit:
            return value
        case .celsius:
            return Int(((Double(value) - 32.0) * 5.0 / 9.0).rounded())
        }
    }

    private var collapsedShellHeight: CGFloat {
        max(layout.topBarHeight - 4, 56)
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

private struct MetricPillLabel: View {
    let title: String
    let value: String
    let width: CGFloat
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        return content
    }

    private var content: some View {
        let titleColor = isSelected ? Color.white.opacity(0.86) : Color.white.opacity(0.55)
        let fillColor = isSelected ? Color.cyan.opacity(0.28) : isHovered ? Color.white.opacity(0.18) : Color.white.opacity(0.13)
        let strokeColor = isSelected ? Color.cyan.opacity(0.56) : isHovered ? Color.white.opacity(0.34) : Color.white.opacity(0.20)
        let shadowColor = isSelected ? Color.cyan.opacity(0.22) : isHovered ? Color.black.opacity(0.24) : Color.black.opacity(0.20)

        return pillStack(titleColor: titleColor)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(
                color: shadowColor,
                radius: isHovered ? 4 : 3,
                y: 1
            )
            .scaleEffect(isHovered ? 1.03 : 1)
    }

    private func pillStack(titleColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9.2, weight: .medium, design: .rounded))
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            pillValue
        }
    }

    private var pillValue: some View {
        Text(value)
            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .contentTransition(.numericText())
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
        nsView.frame = trackingFrame
        nsView.needsLayout = true
        nsView.needsDisplay = true
    }
}

private final class HoverTrackingNSView: NSView {
    var onHoverChanged: ((Bool) -> Void)?
    private var isInside = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = false
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        trackingAreas.forEach { removeTrackingArea($0) }

        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeAlways,
            .inVisibleRect
        ]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        guard !isInside else { return }
        isInside = true
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        guard isInside else { return }
        isInside = false
        onHoverChanged?(false)
    }
}

#if DEBUG
struct NotchWeatherView_Previews: PreviewProvider {
    static var previews: some View {
        NotchWeatherView(
            snapshot: .sample,
            layout: .from(screen: NSScreen.main ?? NSScreen.screens.first),
            onHoverChanged: { _ in },
            onLocationRequest: { }
        )
        .frame(width: 680, height: 220)
        .background(Color.black)
    }
}
#endif
