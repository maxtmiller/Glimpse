import Foundation

enum YahooFinanceMarketService {
    private static let baseURL = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart")!

    private struct ChartResponse: Decodable {
        let chart: ChartPayload
    }

    private struct ChartPayload: Decodable {
        let result: [ChartResult]?
    }

    private struct ChartResult: Decodable {
        let meta: ChartMeta
        let indicators: Indicators?
    }

    private struct ChartMeta: Decodable {
        let symbol: String?
        let shortName: String?
        let regularMarketPrice: Double?
        let chartPreviousClose: Double?
        let regularMarketDayHigh: Double?
        let regularMarketDayLow: Double?
        let regularMarketVolume: Double?
    }

    private struct Indicators: Decodable {
        let quote: [QuoteData]?
    }

    private struct QuoteData: Decodable {
        let close: [Double?]?
    }

    static func fetchSnapshot(from preview: MarketSnapshot) async throws -> MarketSnapshot {
        let assets = await withTaskGroup(of: (String, MarketAsset?).self, returning: [String: MarketAsset].self) { group in
            for asset in preview.assets {
                group.addTask {
                    (asset.id, try? await fetchAsset(asset))
                }
            }

            var result: [String: MarketAsset] = [:]
            for await (id, asset) in group {
                if let asset {
                    result[id] = asset
                }
            }
            return result
        }

        guard !assets.isEmpty else {
            throw URLError(.cannotLoadFromNetwork)
        }

        return MarketSnapshot(
            updatedAt: Date(),
            sourceBadge: "YAHOO",
            selectedAssetID: preview.selectedAssetID,
            assets: preview.assets.map { assets[$0.id] ?? $0 }
        )
    }

    private static func fetchAsset(_ asset: MarketAsset) async throws -> MarketAsset {
        let symbol = yahooSymbol(for: asset.symbol)
        let charts = await withTaskGroup(of: (MarketTimeRange, ChartResult?).self, returning: [MarketTimeRange: ChartResult].self) { group in
            for range in MarketTimeRange.allCases {
                group.addTask {
                    (range, try? await fetchChart(symbol: symbol, range: range))
                }
            }

            var result: [MarketTimeRange: ChartResult] = [:]
            for await (range, chart) in group {
                if let chart {
                    result[range] = chart
                }
            }
            return result
        }

        guard let result = charts[.day] else {
            throw URLError(.cannotLoadFromNetwork)
        }
        let meta = result.meta
        guard let price = meta.regularMarketPrice else {
            throw URLError(.cannotParseResponse)
        }

        let previousClose = meta.chartPreviousClose ?? price
        let change = price - previousClose
        let changePercent = previousClose == 0 ? 0 : (change / previousClose) * 100
        let closes = result.indicators?.quote?.first?.close?.compactMap { $0 } ?? []
        var historicalSparklines: [MarketTimeRange: [Double]] = [:]
        for range in MarketTimeRange.allCases {
            let values = charts[range]?.indicators?.quote?.first?.close?.compactMap { $0 } ?? []
            if !values.isEmpty {
                historicalSparklines[range] = values
            }
        }

        return MarketAsset(
            id: asset.id,
            symbol: asset.symbol,
            name: asset.name,
            category: asset.category,
            unit: asset.unit,
            price: price,
            change: change,
            changePercent: changePercent,
            dayHigh: meta.regularMarketDayHigh ?? asset.dayHigh,
            dayLow: meta.regularMarketDayLow ?? asset.dayLow,
            volumeLabel: formatVolume(meta.regularMarketVolume ?? 0, fallback: asset.volumeLabel),
            sparkline: closes.isEmpty ? asset.sparkline : closes,
            accent: asset.accent,
            note: asset.note,
            historicalSparklines: historicalSparklines
        )
    }

    private static func fetchChart(symbol: String, range: MarketTimeRange) async throws -> ChartResult {
        let query: (range: String, interval: String)
        switch range {
        case .day:
            query = ("1d", "5m")
        case .week:
            query = ("5d", "1h")
        case .month:
            query = ("1mo", "1d")
        case .year:
            query = ("1y", "1d")
        case .allTime:
            query = ("max", "1mo")
        }

        var components = URLComponents(
            url: baseURL.appendingPathComponent(symbol),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "range", value: query.range),
            URLQueryItem(name: "interval", value: query.interval),
            URLQueryItem(name: "includePrePost", value: "true")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(ChartResponse.self, from: data)
        guard let result = decoded.chart.result?.first else {
            throw URLError(.cannotParseResponse)
        }
        return result
    }

    private static func yahooSymbol(for symbol: String) -> String {
        switch symbol.uppercased() {
        case "SPX": return "^GSPC"
        case "DJI": return "^DJI"
        case "XAUUSD": return "GC=F"
        default: return symbol
        }
    }

    private static func formatVolume(_ value: Double, fallback: String) -> String {
        guard value > 0 else { return fallback }
        if value >= 1_000_000_000 { return String(format: "%.1fB", value / 1_000_000_000) }
        if value >= 1_000_000 { return String(format: "%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "%.1fK", value / 1_000) }
        return String(format: "%.0f", value)
    }
}
