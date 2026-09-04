import SwiftUI

enum TemperatureUnit {
    case fahrenheit
    case celsius

    var displaySymbol: String {
        switch self {
        case .fahrenheit: return "F"
        case .celsius: return "C"
        }
    }

    var windSpeedUnit: String {
        switch self {
        case .fahrenheit: return "mph"
        case .celsius: return "km/h"
        }
    }

    var toggled: TemperatureUnit {
        switch self {
        case .fahrenheit: return .celsius
        case .celsius: return .fahrenheit
        }
    }
}

enum GraphMetric: Hashable {
    case temperature
    case feelsLike
    case humidity
    case rain
    case wind

    var title: String {
        switch self {
        case .temperature: return "Temperature"
        case .feelsLike: return "Feels like"
        case .humidity: return "Humidity"
        case .rain: return "Rain"
        case .wind: return "Wind"
        }
    }

    var accentColor: Color {
        switch self {
        case .temperature: return Color.cyan
        case .feelsLike: return Color.blue
        case .humidity: return Color.cyan.opacity(0.92)
        case .rain: return Color.green.opacity(0.88)
        case .wind: return Color.blue.opacity(0.88)
        }
    }
}

struct WeatherWidgetView: View {
    let snapshot: WeatherSnapshot
    let layout: PanelLayout
    let isExpanded: Bool
    let presentationProgress: CGFloat
    @Binding var selectedPage: PerchPage
    @Binding var temperatureUnit: TemperatureUnit
    @Binding var forecastRange: WeatherForecastRange
    @Binding var selectedGraphMetric: GraphMetric?
    let onLocationRequest: () -> Void

    @State private var isLocationButtonHovered = false
    @State private var isUnitButtonHovered = false
    @State private var isForecastRangeButtonHovered = false
    @State private var hoveredMetric: GraphMetric?
    @State private var isRetryButtonHovered = false
    @State private var isHomeButtonHovered = false
    @State private var isSettingsButtonHovered = false

    var body: some View {
        PerchWidgetChrome(
            layout: layout,
            isExpanded: isExpanded,
            presentationProgress: presentationProgress,
            leading: {
                HStack(alignment: .center, spacing: 10) {
                    PerchSummaryHeader(
                        icon: snapshot.hasLiveData ? snapshot.symbol : "cloud.fill",
                        title: "Weather",
                        subtitle: "Current conditions",
                        accent: Color.orange,
                        showsSubtitle: isExpanded,
                        iconAction: onLocationRequest,
                        iconHelp: snapshot.hasLiveData ? "Refresh weather" : "Enable location services"
                    )

                    /*
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
                                        .stroke(isLocationButtonHovered ? Color.white.opacity(0.42) : Color.white.opacity(0.30), lineWidth: 1)
                                )
                                .shadow(color: isLocationButtonHovered ? Color.cyan.opacity(0.24) : .black.opacity(0.28), radius: isLocationButtonHovered ? 5 : 3, y: 1)
                                .scaleEffect(isLocationButtonHovered ? 1.04 : 1)

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
                    */

                    if isExpanded {
                        Spacer(minLength: 0)

                        PerchNavigationButton(
                            systemName: "house.fill",
                            title: "Home",
                            isHovered: $isHomeButtonHovered
                        ) {
                            withAnimation(PerchMotion.pageTransitionAnimation) {
                                selectedPage = .home
                            }
                        }
                        .offset(x: -4)
                    }
                }
                .padding(.leading, 4)
            },
            trailing: {
                HStack(spacing: isExpanded ? 10 : 4) {
                    if isExpanded {
                        PerchNavigationButton(
                            systemName: "gearshape.fill",
                            title: "Settings",
                            isHovered: $isSettingsButtonHovered
                        ) {
                            withAnimation(PerchMotion.pageTransitionAnimation) {
                                selectedPage = .settings
                            }
                        }
                        .offset(x: 4)

                        Spacer(minLength: 0)
                    }

                    temperatureChip
                    if !isExpanded {
                        collapsedHumidity
                    }
                    if isExpanded {
                        unitToggleButton
                        forecastRangeButton
                    }
                }
                .padding(.trailing, 4)
                .offset(x: isExpanded ? 0 : -9)
            },
            expanded: {
                perchWeatherExpandedView
            }
        )
    }

    private var perchWeatherExpandedView: some View {
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
                    metricPill(metric: .rain, title: "Rain", value: displayMetricValue(snapshot.rainChance, suffix: "%"), width: 62)
                    metricPill(
                        metric: .wind,
                        title: "Wind",
                        value: displayMetricValue(convertedWind(snapshot.wind), suffix: " \(temperatureUnit.windSpeedUnit)"),
                        width: 72
                    )
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
        .padding(.top, 8)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
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

    private var collapsedHumidity: some View {
        HStack(spacing: 4) {
            Image(systemName: "drop.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.cyan.opacity(0.82))

            Text(displayMetricValue(snapshot.humidity, suffix: "%"))
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(.white.opacity(0.06), in: Capsule())
    }

    private var unitToggleButton: some View {
        let isHovered = isUnitButtonHovered

        return Button {
            withAnimation(.easeInOut(duration: PerchMotion.hoverAnimationDuration)) {
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

    private var forecastRangeButton: some View {
        let isHovered = isForecastRangeButtonHovered

        return Button {
            withAnimation(.easeInOut(duration: PerchMotion.hoverAnimationDuration)) {
                forecastRange = forecastRange.next
            }
        } label: {
            Text(forecastRange.shortTitle)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 30, height: 26)
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
        .onHover { isForecastRangeButtonHovered = $0 }
        .help("Forecast range: \(forecastRange.apiDays) day\(forecastRange.apiDays == 1 ? "" : "s"). Click to change.")
    }

    private func metricPill(metric: GraphMetric, title: String, value: String, width: CGFloat) -> some View {
        let isSelected = selectedGraphMetric == metric
        let isHovered = hoveredMetric == metric

        return Button {
            withAnimation(.easeInOut(duration: PerchMotion.hoverAnimationDuration)) {
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
                Text(graphTitle)
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
                                let isCurrentHour = isCurrentHour(graphHours[index], at: timeline.date)
                                let shouldShowValueLabel = shouldShowGraphValueLabel(total: values.count)

                                VStack(spacing: 3) {
                                    Text(graphValueLabel(values[index], metric: metric, hour: graphHours[index]))
                                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                        .foregroundStyle(isCurrentHour ? Color.red.opacity(0.95) : Color.white.opacity(0.78))
                                        .opacity(shouldShowValueLabel ? 1 : 0)
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
                    ForEach(Array(graphHours.enumerated()), id: \.element.id) { index, hour in
                        Group {
                            if shouldShowGraphTimeLabel(for: hour, at: index, total: graphHours.count) {
                                Text(graphTimeLabel(for: hour))
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
                /*
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
                */
            }
        }
    }

    private func displayMetricValue(_ value: Int, suffix: String = "") -> String {
        guard snapshot.hasLiveData else { return "-" }
        return "\(value)\(suffix)"
    }

    private func displayMetricValue(_ value: String) -> String {
        guard snapshot.hasLiveData else { return "-" }
        return value
    }

    private func graphSeries(for metric: GraphMetric) -> [Double] {
        graphHours.map { hour in
            let temp = Double(convertedTemperature(hour.temperature))
            switch metric {
            case .temperature:
                return temp
            case .feelsLike:
                return Double(convertedTemperature(hour.feelsLike))
            case .humidity:
                return Double(hour.humidity)
            case .rain:
                return Double(hour.rainChance)
            case .wind:
                return Double(convertedWind(hour.wind))
            }
        }
    }

    private var graphHours: [WeatherSnapshot.HourlyForecast] {
        guard snapshot.hourly.count > 25 else { return snapshot.hourly }

        let step = Int(ceil(Double(snapshot.hourly.count - 1) / 24.0))
        var sampled = snapshot.hourly.enumerated().compactMap { index, hour in
            index % step == 0 ? hour : nil
        }

        if let last = snapshot.hourly.last, sampled.last?.id != last.id {
            sampled.append(last)
        }

        return sampled
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
        case .rain:
            return "\(rounded)%"
        case .wind:
            return "\(rounded) \(windArrow(for: hour.windDirectionDegrees))"
        }
    }

    private var graphTitle: String {
        switch selectedGraphMetric {
        case .rain:
            return "Rain chance"
        case .wind:
            return "Wind (\(temperatureUnit.windSpeedUnit))"
        case .some(let metric):
            return metric.title
        case .none:
            return GraphMetric.temperature.title
        }
    }

    private func convertedWind(_ value: Int) -> Int {
        switch temperatureUnit {
        case .fahrenheit:
            return value
        case .celsius:
            return Int((Double(value) * 1.60934).rounded())
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

    private func shouldShowGraphTimeLabel(for hour: WeatherSnapshot.HourlyForecast, at index: Int, total: Int) -> Bool {
        guard total > 0 else { return false }

        if index == 0 {
            return true
        }

        guard forecastRange != .oneDay,
              let firstDate = graphHours.first?.date else {
            return index % 4 == 0
        }

        if forecastRange == .threeDays && index == total - 1 {
            return true
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = currentTimeZone()
        let isNewDay = !calendar.isDate(hour.date, equalTo: graphHours[index - 1].date, toGranularity: .day)
        let dayOffset = calendar.dateComponents([.day], from: firstDate, to: hour.date).day ?? 0
        let interval: Int
        switch forecastRange {
        case .threeDays: interval = 1
        case .sevenDays: interval = 2
        case .sixteenDays: interval = 3
        case .oneDay: interval = 1
        }

        let previousDayOffset = calendar.dateComponents([.day], from: firstDate, to: graphHours[index - 1].date).day ?? 0
        return isNewDay && dayOffset > 0 && dayOffset / interval != previousDayOffset / interval
    }

    private func graphTimeLabel(for hour: WeatherSnapshot.HourlyForecast) -> String {
        guard forecastRange != .oneDay else { return hour.hour }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = currentTimeZone()
        formatter.dateFormat = forecastRange == .sixteenDays ? "MMM d" : "EEE"
        let labelDate: Date
        if forecastRange == .threeDays && hour.id == graphHours.last?.id {
            labelDate = calendar(for: hour.date).date(byAdding: .day, value: 1, to: hour.date) ?? hour.date
        } else {
            labelDate = hour.date
        }
        return formatter.string(from: labelDate)
    }

    private func calendar(for date: Date) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = currentTimeZone()
        return calendar
    }

    private func shouldShowGraphValueLabel(total: Int) -> Bool {
        return total > 0
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
}

private struct MetricPillLabel: View {
    let title: String
    let value: String
    let width: CGFloat
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        let titleColor = isSelected ? Color.white.opacity(0.86) : Color.white.opacity(0.55)
        let fillColor = isSelected ? Color.cyan.opacity(0.28) : isHovered ? Color.white.opacity(0.18) : Color.white.opacity(0.13)
        let strokeColor = isSelected ? Color.cyan.opacity(0.56) : isHovered ? Color.white.opacity(0.34) : Color.white.opacity(0.20)
        let shadowColor = isSelected ? Color.cyan.opacity(0.22) : isHovered ? Color.black.opacity(0.24) : Color.black.opacity(0.20)

        return VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9.2, weight: .medium, design: .rounded))
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(value)
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
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
}
