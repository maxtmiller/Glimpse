import Foundation
import SwiftUI

enum MarketQuoteUnit {
    case currency
    case points

    var suffix: String {
        switch self {
        case .currency:
            return ""
        case .points:
            return " pts"
        }
    }
}

enum MarketDisplayCurrency: String, CaseIterable, Identifiable {
    case usd
    case gbp
    case eur
    case jpy
    case cny

    var id: String { rawValue }

    var shortTitle: String {
        rawValue.uppercased()
    }

    var title: String {
        switch self {
        case .usd: return "Dollar"
        case .gbp: return "Pound"
        case .eur: return "Euro"
        case .jpy: return "JPY"
        case .cny: return "CNY"
        }
    }

    var next: MarketDisplayCurrency {
        switch self {
        case .usd: return .gbp
        case .gbp: return .eur
        case .eur: return .jpy
        case .jpy: return .cny
        case .cny: return .usd
        }
    }

    var conversionRateFromUSD: Double {
        switch self {
        case .usd: return 1.0
        case .gbp: return 0.79
        case .eur: return 0.92
        case .jpy: return 156.0
        case .cny: return 7.25
        }
    }

    var currencyCode: String {
        rawValue.uppercased()
    }
}

enum MarketTimeRange: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year
    case allTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        case .allTime: return "All time"
        }
    }

    var shortTitle: String {
        switch self {
        case .day: return "1D"
        case .week: return "1W"
        case .month: return "1M"
        case .year: return "1Y"
        case .allTime: return "All"
        }
    }

    var next: MarketTimeRange {
        switch self {
        case .day: return .week
        case .week: return .month
        case .month: return .year
        case .year: return .allTime
        case .allTime: return .day
        }
    }

    var chartLabels: [String] {
        switch self {
        case .day:
            return ["Open", "Mid", "Now"]
        case .week:
            return ["1W", "3D", "Now"]
        case .month:
            return ["1M", "2W", "Now"]
        case .year:
            return ["1Y", "6M", "Now"]
        case .allTime:
            return ["Start", "Mid", "Now"]
        }
    }
}

struct MarketAsset: Identifiable {
    let id: String
    let symbol: String
    let name: String
    let category: String
    let unit: MarketQuoteUnit
    let price: Double
    let change: Double
    let changePercent: Double
    let dayHigh: Double
    let dayLow: Double
    let volumeLabel: String
    let sparkline: [Double]
    let accent: Color
    let note: String
    let historicalSparklines: [MarketTimeRange: [Double]]

    static let unavailable = MarketAsset(
        id: "unavailable",
        symbol: "—",
        name: "Market data unavailable",
        category: "",
        unit: .currency,
        price: 0,
        change: 0,
        changePercent: 0,
        dayHigh: 0,
        dayLow: 0,
        volumeLabel: "—",
        sparkline: [],
        accent: Color.white.opacity(0.35),
        note: "Market data unavailable",
        historicalSparklines: [:]
    )

    var isPositive: Bool {
        change >= 0
    }

    var priceLabel: String {
        priceLabel(displayCurrency: .usd)
    }

    func priceLabel(displayCurrency: MarketDisplayCurrency) -> String {
        formattedCurrencyValue(price, displayCurrency: displayCurrency)
    }

    var changeLabel: String {
        changeLabel(displayCurrency: .usd)
    }

    func changeLabel(displayCurrency: MarketDisplayCurrency) -> String {
        let sign = change >= 0 ? "+" : "-"
        let changeValue = convertedCurrencyValue(abs(change), displayCurrency: displayCurrency)
            .formatted(.number.precision(.fractionLength(2)))
        let percentValue = abs(changePercent).formatted(.number.precision(.fractionLength(2)))
        return "\(sign)\(changeValue) (\(sign)\(percentValue)%)"
    }

    var highLabel: String {
        highLabel(displayCurrency: .usd)
    }

    func highLabel(displayCurrency: MarketDisplayCurrency) -> String {
        formattedCurrencyValue(dayHigh, displayCurrency: displayCurrency)
    }

    var lowLabel: String {
        lowLabel(displayCurrency: .usd)
    }

    func lowLabel(displayCurrency: MarketDisplayCurrency) -> String {
        formattedCurrencyValue(dayLow, displayCurrency: displayCurrency)
    }

    func rangeMetrics(for range: MarketTimeRange) -> MarketAssetRangeMetrics {
        rangeMetrics(for: range, displayCurrency: .usd)
    }

    func rangeMetrics(for range: MarketTimeRange, displayCurrency: MarketDisplayCurrency) -> MarketAssetRangeMetrics {
        let values = sparkline(for: range)
        let highValue = values.max() ?? dayHigh
        let lowValue = values.min() ?? dayLow

        return MarketAssetRangeMetrics(
            highLabel: formattedValue(highValue, displayCurrency: displayCurrency),
            lowLabel: formattedValue(lowValue, displayCurrency: displayCurrency),
            volumeLabel: volumeLabel
        )
    }

    func performance(for range: MarketTimeRange) -> MarketAssetPerformance {
        performance(for: range, displayCurrency: .usd)
    }

    func performance(for range: MarketTimeRange, displayCurrency: MarketDisplayCurrency) -> MarketAssetPerformance {
        let values = sparkline(for: range)
        let startingPrice = values.first ?? price
        let endingPrice = values.last ?? price
        let adjustedChange = endingPrice - startingPrice
        let adjustedPercent = startingPrice == 0 ? 0 : (adjustedChange / startingPrice) * 100.0

        return MarketAssetPerformance(
            change: convertedCurrencyValue(adjustedChange, displayCurrency: displayCurrency),
            changePercent: adjustedPercent
        )
    }

    func sparkline(for range: MarketTimeRange) -> [Double] {
        historicalSparklines[range] ?? sparkline
    }

    private func formattedValue(_ value: Double, displayCurrency: MarketDisplayCurrency) -> String {
        formattedCurrencyValue(value, displayCurrency: displayCurrency)
    }

    private func formattedCurrencyValue(_ value: Double, displayCurrency: MarketDisplayCurrency) -> String {
        switch unit {
        case .currency:
            return convertedCurrencyValue(value, displayCurrency: displayCurrency)
                .formatted(.currency(code: displayCurrency.currencyCode))
        case .points:
            return convertedCurrencyValue(value, displayCurrency: displayCurrency)
                .formatted(.currency(code: displayCurrency.currencyCode))
        }
    }

    private func convertedCurrencyValue(_ value: Double, displayCurrency: MarketDisplayCurrency) -> Double {
        guard unit == .currency else { return value }
        return value * displayCurrency.conversionRateFromUSD
    }

    private func formattedVolumeLabel(multiplier: Double) -> String {
        let trimmed = volumeLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let unit = trimmed.hasSuffix("B") ? "B" : trimmed.hasSuffix("M") ? "M" : nil
        let numericPart = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "BM"))
        guard let base = Double(numericPart), let unit else { return volumeLabel }

        let baseMillions = unit == "B" ? base * 1000.0 : base
        let adjustedMillions = baseMillions * multiplier

        if adjustedMillions >= 1000 {
            return String(format: "%.1fB", adjustedMillions / 1000.0)
        } else {
            return String(format: "%.1fM", adjustedMillions)
        }
    }
}

struct MarketAssetPerformance {
    let change: Double
    let changePercent: Double

    var isPositive: Bool {
        change >= 0
    }

    var changeLabel: String {
        let sign = change >= 0 ? "+" : "-"
        let changeValue = abs(change).formatted(.number.precision(.fractionLength(2)))
        let percentValue = abs(changePercent).formatted(.number.precision(.fractionLength(2)))
        return "\(sign)\(changeValue) (\(sign)\(percentValue)%)"
    }

    var percentLabel: String {
        let sign = changePercent >= 0 ? "+" : "-"
        return "\(sign)\(abs(changePercent).formatted(.number.precision(.fractionLength(2))))%"
    }
}

struct MarketAssetRangeMetrics {
    let highLabel: String
    let lowLabel: String
    let volumeLabel: String
}

struct MarketSnapshot {
    let updatedAt: Date
    let sourceBadge: String
    let selectedAssetID: String
    let assets: [MarketAsset]

    func asset(id: String) -> MarketAsset? {
        assets.first { $0.id == id }
    }

    func benchmark() -> MarketAsset? {
        asset(id: "sp500")
    }

    static let empty = MarketSnapshot(
        updatedAt: Date(),
        sourceBadge: "—",
        selectedAssetID: "",
        assets: []
    )

    static let marketUniverse: [MarketAsset] = {
        func asset(
            _ id: String,
            symbol: String,
            name: String,
            category: String,
            unit: MarketQuoteUnit,
            accent: Color,
            note: String
        ) -> MarketAsset {
            MarketAsset(
                id: id,
                symbol: symbol,
                name: name,
                category: category,
                unit: unit,
                price: 0,
                change: 0,
                changePercent: 0,
                dayHigh: 0,
                dayLow: 0,
                volumeLabel: "—",
                sparkline: [],
                accent: accent,
                note: note,
                historicalSparklines: [:]
            )
        }

        return [
            asset("sp500", symbol: "SPX", name: "S&P 500", category: "Index", unit: .points, accent: .cyan, note: "Broad market benchmark."),
            asset("dow", symbol: "DJI", name: "Dow Jones", category: "Index", unit: .points, accent: .blue, note: "Heavyweight industrials and financials."),
            asset("gold", symbol: "XAUUSD", name: "Gold", category: "Commodity", unit: .currency, accent: .orange, note: "Safe-haven bid and rate sensitivity."),
            asset("bitcoin", symbol: "BTCUSD", name: "Bitcoin", category: "Crypto", unit: .currency, accent: .green, note: "Risk appetite and liquidity proxy."),
            asset("aapl", symbol: "AAPL", name: "Apple", category: "Large cap", unit: .currency, accent: .blue, note: "Mega-cap software and hardware mix."),
            asset("msft", symbol: "MSFT", name: "Microsoft", category: "Large cap", unit: .currency, accent: .green, note: "Defensive growth and AI exposure."),
            asset("nvda", symbol: "NVDA", name: "NVIDIA", category: "Trending", unit: .currency, accent: .yellow, note: "AI semis continue to lead momentum."),
            asset("tsla", symbol: "TSLA", name: "Tesla", category: "Trending", unit: .currency, accent: .red, note: "High-beta momentum and headline risk."),
            asset("pltr", symbol: "PLTR", name: "Palantir", category: "Momentum", unit: .currency, accent: .green, note: "Momentum name with consistent volume."),
            asset("tsm", symbol: "TSM", name: "TSMC", category: "Semiconductors", unit: .currency, accent: .cyan, note: "Foundry leader powering advanced chips."),
            asset("googl", symbol: "GOOGL", name: "Google", category: "Large cap", unit: .currency, accent: .blue, note: "Search, cloud, and AI platform scale."),
            asset("cost", symbol: "COST", name: "Costco", category: "Consumer", unit: .currency, accent: .orange, note: "Membership retail and resilient demand."),
            asset("cat", symbol: "CAT", name: "Caterpillar", category: "Industrials", unit: .currency, accent: .yellow, note: "Global construction and mining equipment.")
        ]
    }()
}

private enum MarketTrend {
    case up
    case down
    case flat
    case unavailable

    var symbol: String {
        switch self {
        case .up: return "chart.line.uptrend.xyaxis"
        case .down: return "chart.line.downtrend.xyaxis"
        case .flat: return "chart.line.flattrend.xyaxis"
        case .unavailable: return "chart.line.flattrend.xyaxis"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .flat: return .yellow
        case .unavailable: return .white.opacity(0.45)
        }
    }
}

struct NotchMarketsWidgetView: View {
    let layout: PanelLayout
    let isExpanded: Bool
    let presentationProgress: CGFloat
    @Binding var selectedPage: NotchPage

    @State private var selectedAssetID = MarketSnapshot.empty.selectedAssetID
    @State private var selectedRange: MarketTimeRange = .day
    @State private var selectedDisplayCurrency: MarketDisplayCurrency = .usd
    @State private var isHomeButtonHovered = false
    @State private var isSettingsButtonHovered = false
    @State private var hoveredAssetID: String?
    @StateObject private var marketStore = MarketStore()

    var body: some View {
        NotchWidgetChrome(
            layout: layout,
            isExpanded: isExpanded,
            presentationProgress: presentationProgress,
            leading: {
                HStack(spacing: 10) {
                    NotchSummaryHeader(
                        icon: marketTrend.symbol,
                        title: "Markets",
                        subtitle: hasMarketData ? selectedAsset.name : "Data unavailable",
                        accent: marketTrend.color,
                        showsSubtitle: isExpanded,
                        iconAction: marketStore.refreshNow,
                        iconHelp: "Refresh market data"
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
                    } else {
                        MarketTickerStrip(
                            assets: trackedTickerAssets,
                            selectedRange: selectedRange
                        )
                        .frame(height: 28)
                        .offset(x: -10)
                    }

                    if isExpanded {
                        NotchSummaryBadge(text: snapshot.sourceBadge)

                        MarketCurrencySummary(
                            currency: selectedDisplayCurrency,
                            selectedRange: selectedRange,
                            onNextCurrency: cycleDisplayCurrency,
                            onNextRange: cycleRange
                        )
                    }
                }
                .padding(.trailing, 4)
            },
            expanded: {
                VStack(alignment: .leading, spacing: 8) {
                    if hasMarketData {
                        let selectedPerformance = selectedAsset.performance(for: selectedRange, displayCurrency: selectedDisplayCurrency)
                        let selectedMetrics = selectedAsset.rangeMetrics(for: selectedRange, displayCurrency: selectedDisplayCurrency)

                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(selectedAsset.name) · \(selectedAsset.category)")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(selectedAsset.priceLabel(displayCurrency: selectedDisplayCurrency))
                                        .font(.system(size: 19, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .contentTransition(.numericText())

                                    Text(selectedPerformance.changeLabel)
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(selectedPerformance.isPositive ? Color.green.opacity(0.92) : Color.red.opacity(0.92))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule(style: .continuous)
                                                .fill((selectedPerformance.isPositive ? Color.green : Color.red).opacity(0.15))
                                        )
                                }

                                Text(selectedAsset.note)
                                    .font(.system(size: 8.8, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.54))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }

                            Spacer(minLength: 0)

                            VStack(alignment: .trailing, spacing: 2) {
                                statRow(title: "High", value: selectedMetrics.highLabel)
                                statRow(title: "Low", value: selectedMetrics.lowLabel)
                                statRow(title: "Vol", value: selectedMetrics.volumeLabel)
                            }
                        }
                    } else {
                        unavailableSummary
                    }

                    MarketHeroChart(asset: hasMarketData ? selectedAsset : nil, range: selectedRange)
                        .frame(height: 68)

                    if hasMarketData {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(snapshot.assets) { asset in
                                    MarketAssetCard(
                                        asset: asset,
                                        isSelected: selectedAssetID == asset.id,
                                        isHovered: hoveredAssetID == asset.id,
                                        range: selectedRange,
                                        displayCurrency: selectedDisplayCurrency
                                    ) {
                                        withAnimation(NotchMotion.pageTransitionAnimation) {
                                            selectedAssetID = asset.id
                                        }
                                    }
                                    .onHover { hovering in
                                        hoveredAssetID = hovering ? asset.id : (hoveredAssetID == asset.id ? nil : hoveredAssetID)
                                    }
                                }
                            }
                            .padding(.horizontal, 1)
                            .padding(.vertical, 4)
                        }
                        .frame(height: 54)
                    } else {
                        Text("No market data available")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 46, alignment: .center)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        )
        .onAppear { marketStore.start() }
    }

    private var snapshot: MarketSnapshot {
        marketStore.snapshot
    }

    private var selectedAsset: MarketAsset {
        snapshot.asset(id: selectedAssetID)
            ?? snapshot.asset(id: snapshot.selectedAssetID)
            ?? snapshot.assets.first
            ?? MarketAsset.unavailable
    }

    private var hasMarketData: Bool {
        !snapshot.assets.isEmpty
    }

    private var marketTrend: MarketTrend {
        guard hasMarketData else { return .unavailable }

        let benchmarkChanges = ["sp500", "dow"]
            .compactMap { snapshot.asset(id: $0)?.changePercent }

        let averageChange = benchmarkChanges.isEmpty
            ? (snapshot.assets.map(\.changePercent).reduce(0, +) / Double(max(snapshot.assets.count, 1)))
            : benchmarkChanges.reduce(0, +) / Double(benchmarkChanges.count)

        if averageChange > 0.05 {
            return .up
        } else if averageChange < -0.05 {
            return .down
        } else {
            return .flat
        }
    }

    private var trackedTickerAssets: [MarketAsset] {
        let trackedIDs = ["sp500", "dow", "gold", "bitcoin", "aapl", "msft", "nvda", "tsla", "tsm", "googl", "cost", "cat"]
        return trackedIDs.compactMap { id in
            snapshot.asset(id: id)
        }
    }

    private func cycleRange() {
        withAnimation(.easeInOut(duration: NotchMotion.hoverAnimationDuration)) {
            selectedRange = selectedRange.next
        }
    }

    private func cycleDisplayCurrency() {
        withAnimation(.easeInOut(duration: NotchMotion.hoverAnimationDuration)) {
            selectedDisplayCurrency = selectedDisplayCurrency.next
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))

            Text(value)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
    }

    private var unavailableSummary: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Market data unavailable")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(marketStore.errorMessage == nil ? "Loading market data…" : "Click the chart icon to retry")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.54))
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                statRow(title: "High", value: "—")
                statRow(title: "Low", value: "—")
                statRow(title: "Vol", value: "—")
            }
        }
    }
}

private struct MarketCurrencySummary: View {
    let currency: MarketDisplayCurrency
    let selectedRange: MarketTimeRange
    let onNextCurrency: () -> Void
    let onNextRange: () -> Void

    @State private var isCurrencyButtonHovered = false
    @State private var isRangeButtonHovered = false

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: onNextCurrency) {
                Text(currency.shortTitle)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .frame(width: 34, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isCurrencyButtonHovered ? Color.white.opacity(0.22) : Color.white.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isCurrencyButtonHovered ? Color.white.opacity(0.42) : Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: isCurrencyButtonHovered ? Color.cyan.opacity(0.16) : .black.opacity(0.22), radius: isCurrencyButtonHovered ? 5 : 3, y: 1)
                .scaleEffect(isCurrencyButtonHovered ? 1.04 : 1)
            }
            .buttonStyle(InteractiveButtonStyle())
            .onHover { isCurrencyButtonHovered = $0 }
            .help("Display currency: \(currency.title). Click to cycle.")

            Button(action: onNextRange) {
                Text(selectedRange.shortTitle)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isRangeButtonHovered ? Color.white.opacity(0.22) : Color.white.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isRangeButtonHovered ? Color.white.opacity(0.42) : Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .shadow(color: isRangeButtonHovered ? Color.cyan.opacity(0.16) : .black.opacity(0.22), radius: isRangeButtonHovered ? 5 : 3, y: 1)
                    .scaleEffect(isRangeButtonHovered ? 1.04 : 1)
            }
            .buttonStyle(InteractiveButtonStyle())
            .onHover { isRangeButtonHovered = $0 }
            .help("Current range: \(selectedRange.title). Click to cycle.")
        }
    }
}

private struct MarketTickerStrip: View {
    let assets: [MarketAsset]
    let selectedRange: MarketTimeRange

    private let itemWidth: CGFloat = 74
    private let itemSpacing: CGFloat = 5
    private let speed: CGFloat = 18

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1.0 / 30.0)) { timeline in
            GeometryReader { geometry in
                let stream = assets + assets
                let contentWidth = CGFloat(assets.count) * itemWidth + CGFloat(max(assets.count - 1, 0)) * itemSpacing
                let travelWidth = max(contentWidth, geometry.size.width)
                let offset = CGFloat(timeline.date.timeIntervalSinceReferenceDate * Double(speed))
                    .truncatingRemainder(dividingBy: travelWidth)

                HStack(spacing: itemSpacing) {
                    ForEach(Array(stream.enumerated()), id: \.offset) { _, asset in
                        MarketTickerChip(asset: asset, selectedRange: selectedRange, width: itemWidth)
                    }
                }
                .offset(x: -offset)
            }
        }
        .clipped()
    }
}

private struct MarketTickerChip: View {
    let asset: MarketAsset
    let selectedRange: MarketTimeRange
    let width: CGFloat

    var body: some View {
        let performance = asset.performance(for: selectedRange)

        HStack(spacing: 4) {
            Text(asset.symbol)
                .font(.system(size: 8.7, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(performance.percentLabel)
                .font(.system(size: 9.2, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(performance.isPositive ? Color.green.opacity(0.96) : Color.red.opacity(0.96))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 7)
        .frame(width: width, height: 26, alignment: .center)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct MarketAssetCard: View {
    let asset: MarketAsset
    let isSelected: Bool
    let isHovered: Bool
    let range: MarketTimeRange
    let displayCurrency: MarketDisplayCurrency
    let action: () -> Void

    var body: some View {
        let performance = asset.performance(for: range, displayCurrency: displayCurrency)

        Button(action: action) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(backgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(
                                isSelected ? asset.accent.opacity(0.55) : Color.white.opacity(0.10),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(isSelected ? 0.28 : 0.18), radius: 3, y: 1)

                MarketSparkline(
                    values: asset.sparkline(for: range),
                    accent: asset.accent,
                    lineWidth: 1.9,
                    fillOpacity: 0.14,
                    showLastPoint: false
                )
                .padding(.leading, 40)
                .padding(.trailing, 6)
                .padding(.top, 6)
                .padding(.bottom, 4)
                    .opacity(0.95)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(asset.symbol) · \(asset.name)")
                            .font(.system(size: 10.3, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Spacer(minLength: 0)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(asset.priceLabel(displayCurrency: displayCurrency))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        Text(performance.percentLabel)
                            .font(.system(size: 9.3, weight: .semibold, design: .rounded))
                            .foregroundStyle(performance.isPositive ? Color.green.opacity(0.92) : Color.red.opacity(0.92))
                            .lineLimit(1)
                    }
                }
                .padding(6)
            }
            .frame(width: 122, height: 44)
            .scaleEffect(isHovered ? 1.02 : 1)
            .brightness(isSelected ? 0.03 : 0)
        }
        .buttonStyle(InteractiveButtonStyle())
        .help(asset.name)
    }

    private var backgroundFill: LinearGradient {
        LinearGradient(
            colors: [
                isSelected ? asset.accent.opacity(0.26) : Color.white.opacity(0.10),
                isSelected ? asset.accent.opacity(0.10) : Color.white.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct MarketHeroChart: View {
    let asset: MarketAsset?
    let range: MarketTimeRange

    var body: some View {
        let accent = asset?.accent ?? Color.white.opacity(0.25)

        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.18),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            GeometryReader { geometry in
                if let asset {
                    MarketSparkline(
                        values: asset.sparkline(for: range),
                        accent: asset.accent,
                        lineWidth: 2.2,
                        fillOpacity: 0.22,
                        showLastPoint: true
                    )
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
                    .padding(.bottom, 12)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }

            MarketChartAxisLabels(labels: asset == nil ? ["—", "—", "—"] : range.chartLabels)
                .padding(.horizontal, 6)
                .padding(.bottom, 4)
        }
    }
}

private struct MarketChartAxisLabels: View {
    let labels: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                Text(label)
                    .font(.system(size: 7.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(index == labels.count - 1 ? 0.74 : 0.50))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: alignment(for: index))
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .background(Color.black.opacity(0.08), in: Capsule(style: .continuous))
    }

    private func alignment(for index: Int) -> Alignment {
        if index == 0 {
            return .leading
        } else if index == labels.count - 1 {
            return .trailing
        } else {
            return .center
        }
    }
}

private struct MarketSparkline: View {
    let values: [Double]
    let accent: Color
    let lineWidth: CGFloat
    let fillOpacity: Double
    let showLastPoint: Bool

    var body: some View {
        GeometryReader { geometry in
            let points = chartPoints(in: geometry.size)

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
                                accent.opacity(0.95),
                                Color.white.opacity(0.72)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )

                    Path { path in
                        guard let first = points.first, let last = points.last else { return }
                        path.move(to: CGPoint(x: first.x, y: geometry.size.height - 2))
                        path.addLine(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: last.x, y: geometry.size.height - 2))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                accent.opacity(fillOpacity),
                                accent.opacity(fillOpacity * 0.45),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                if showLastPoint, let last = points.last {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4.5, height: 4.5)
                        .shadow(color: accent.opacity(0.35), radius: 2, y: 1)
                        .position(last)
                }
            }
        }
    }

    private func chartPoints(in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }

        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let span = max(maxValue - minValue, 1)
        let horizontalInset: CGFloat = 4
        let verticalInset: CGFloat = 4
        let width = max(size.width - horizontalInset * 2, 1)
        let height = max(size.height - verticalInset * 2, 1)
        let step = values.count > 1 ? width / CGFloat(values.count - 1) : 0

        return values.enumerated().map { index, value in
            let x = horizontalInset + CGFloat(index) * step
            let normalized = CGFloat(value - minValue) / CGFloat(span)
            let y = verticalInset + (1 - normalized) * height
            return CGPoint(x: x, y: y)
        }
    }
}
