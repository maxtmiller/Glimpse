import XCTest
@testable import Glimpse

final class MarketSnapshotTests: XCTestCase {
    func testEmptyMarketSnapshotContainsNoAssets() {
        let snapshot = MarketSnapshot.empty

        XCTAssertTrue(snapshot.assets.isEmpty)
        XCTAssertEqual(snapshot.selectedAssetID, "")
        XCTAssertNil(snapshot.asset(id: "sp500"))
        XCTAssertNil(snapshot.benchmark())
    }

    func testUnavailableMarketAssetUsesNoDataValues() {
        let asset = MarketAsset.unavailable

        XCTAssertEqual(asset.name, "Market data unavailable")
        XCTAssertEqual(asset.price, 0)
        XCTAssertEqual(asset.volumeLabel, "—")
        XCTAssertTrue(asset.sparkline.isEmpty)
        XCTAssertEqual(asset.note, "Market data unavailable")
    }

    func testMarketUniverseHasUniqueAssetsAndExpectedBenchmark() {
        let assets = MarketSnapshot.marketUniverse
        let ids = assets.map(\.id)

        XCTAssertFalse(assets.isEmpty)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertEqual(assets.first?.id, "sp500")
        XCTAssertEqual(assets.first?.symbol, "SPX")
        XCTAssertEqual(assets.first?.unit, .points)
    }

    func testMarketSnapshotFindsAssetsAndBenchmark() {
        let asset = MarketSnapshot.marketUniverse[0]
        let snapshot = MarketSnapshot(
            updatedAt: Date(),
            sourceBadge: "YAHOO",
            selectedAssetID: asset.id,
            assets: [asset]
        )

        XCTAssertEqual(snapshot.asset(id: asset.id)?.id, asset.id)
        XCTAssertEqual(snapshot.benchmark()?.id, asset.id)
    }

    func testEmptySparklineUsesUnavailableMetricsSafely() {
        let metrics = MarketAsset.unavailable.rangeMetrics(for: .day)

        XCTAssertEqual(metrics.highLabel, "—")
        XCTAssertEqual(metrics.lowLabel, "—")
        XCTAssertEqual(metrics.volumeLabel, "—")
    }
}
