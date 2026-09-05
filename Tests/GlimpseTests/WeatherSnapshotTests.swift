import XCTest
@testable import Glimpse

final class WeatherSnapshotTests: XCTestCase {
    func testPlaceholderContainsNoLiveData() {
        let snapshot = WeatherSnapshot.placeholder

        XCTAssertFalse(snapshot.hasLiveData)
        XCTAssertEqual(snapshot.city, "Location unavailable")
        XCTAssertEqual(snapshot.condition, "Enable location services")
        XCTAssertTrue(snapshot.hourly.isEmpty)
    }

    func testWeatherUnavailableContainsNoLiveData() {
        let snapshot = WeatherSnapshot.weatherUnavailable(
            city: "Toronto",
            region: "ON",
            country: "CA"
        )

        XCTAssertFalse(snapshot.hasLiveData)
        XCTAssertEqual(snapshot.displayLocationLabel, "Toronto")
        XCTAssertEqual(snapshot.condition, "Weather unavailable")
        XCTAssertEqual(snapshot.symbol, "cloud.exclamationmark.fill")
        XCTAssertTrue(snapshot.hourly.isEmpty)
    }

    func testLocationOnlyContainsNoWeatherData() {
        let snapshot = WeatherSnapshot.locationOnly(
            city: "Toronto",
            region: "ON",
            country: "CA"
        )

        XCTAssertFalse(snapshot.hasLiveData)
        XCTAssertEqual(snapshot.city, "Toronto")
        XCTAssertEqual(snapshot.condition, "Fetching weather...")
        XCTAssertEqual(snapshot.temperature, 0)
        XCTAssertTrue(snapshot.hourly.isEmpty)
    }

    func testLiveSnapshotContainsLiveData() {
        let snapshot = WeatherSnapshot.live(
            city: "Toronto",
            region: "ON",
            country: "CA",
            condition: "Clear",
            symbol: "sun.max.fill",
            temperature: 20,
            feelsLike: 19,
            high: 23,
            low: 12,
            humidity: 55,
            rainChance: 10,
            wind: 12,
            timeZoneIdentifier: "America/Toronto",
            hourly: []
        )

        XCTAssertTrue(snapshot.hasLiveData)
        XCTAssertEqual(snapshot.locationAbbreviation, "ON, CA")
        XCTAssertEqual(snapshot.displayLocationLabel, "ON, CA")
        XCTAssertEqual(snapshot.temperature, 20)
    }

    func testForecastRangesProvideExpectedDayCounts() {
        XCTAssertEqual(WeatherForecastRange.oneDay.apiDays, 1)
        XCTAssertEqual(WeatherForecastRange.threeDays.apiDays, 3)
        XCTAssertEqual(WeatherForecastRange.sevenDays.apiDays, 7)
        XCTAssertEqual(WeatherForecastRange.sixteenDays.apiDays, 16)
        XCTAssertEqual(WeatherForecastRange.oneDay.next, .threeDays)
        XCTAssertEqual(WeatherForecastRange.sixteenDays.next, .oneDay)
    }
}
