import Foundation

enum WeatherForecastRange: CaseIterable, Equatable {
    case oneDay
    case threeDays
    case sevenDays
    case sixteenDays

    var apiDays: Int {
        switch self {
        case .oneDay: return 1
        case .threeDays: return 3
        case .sevenDays: return 7
        case .sixteenDays: return 16
        }
    }

    var shortTitle: String { "\(apiDays)D" }

    var next: WeatherForecastRange {
        switch self {
        case .oneDay: return .threeDays
        case .threeDays: return .sevenDays
        case .sevenDays: return .sixteenDays
        case .sixteenDays: return .oneDay
        }
    }
}

struct WeatherSnapshot {
    struct HourlyForecast: Identifiable {
        let id = UUID()
        let date: Date
        let hour: String
        let symbol: String
        let temperature: Int
        let feelsLike: Int
        let humidity: Int
        let rainChance: Int
        let wind: Int
        let windDirectionDegrees: Int
        let isCurrentHour: Bool
    }

    let hasLiveData: Bool
    let city: String
    let region: String
    let country: String
    let condition: String
    let symbol: String
    let temperature: Int
    let feelsLike: Int
    let high: Int
    let low: Int
    let humidity: Int
    let rainChance: Int
    let wind: Int
    let hourly: [HourlyForecast]
    let timeZoneIdentifier: String

    var locationAbbreviation: String {
        guard hasLiveData else { return "-" }
        return [region, country].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var displayLocationLabel: String {
        if hasLiveData {
            return locationAbbreviation == "-" ? city : locationAbbreviation
        }

        return city == "Location unavailable" ? "Loc" : city
    }

    static let placeholder = WeatherSnapshot(
        hasLiveData: false,
        city: "Location unavailable",
        region: "",
        country: "",
        condition: "Enable location services",
        symbol: "cloud.fill",
        temperature: 0,
        feelsLike: 0,
        high: 0,
        low: 0,
        humidity: 0,
        rainChance: 0,
        wind: 0,
        hourly: [],
        timeZoneIdentifier: TimeZone.current.identifier
    )

    static func locationOnly(city: String, region: String, country: String) -> WeatherSnapshot {
        WeatherSnapshot(
            hasLiveData: false,
            city: city,
            region: region,
            country: country,
            condition: "Fetching weather...",
            symbol: "cloud.fill",
            temperature: 0,
            feelsLike: 0,
            high: 0,
            low: 0,
            humidity: 0,
            rainChance: 0,
            wind: 0,
            hourly: [],
            timeZoneIdentifier: TimeZone.current.identifier
        )
    }

    static func weatherUnavailable(city: String, region: String, country: String) -> WeatherSnapshot {
        WeatherSnapshot(
            hasLiveData: false,
            city: city,
            region: region,
            country: country,
            condition: "Weather unavailable",
            symbol: "cloud.exclamationmark.fill",
            temperature: 0,
            feelsLike: 0,
            high: 0,
            low: 0,
            humidity: 0,
            rainChance: 0,
            wind: 0,
            hourly: [],
            timeZoneIdentifier: TimeZone.current.identifier
        )
    }

    static func live(
        city: String,
        region: String,
        country: String,
        condition: String,
        symbol: String,
        temperature: Int,
        feelsLike: Int,
        high: Int,
        low: Int,
        humidity: Int,
        rainChance: Int,
        wind: Int,
        timeZoneIdentifier: String,
        hourly: [HourlyForecast]
    ) -> WeatherSnapshot {
        return WeatherSnapshot(
            hasLiveData: true,
            city: city,
            region: region,
            country: country,
            condition: condition,
            symbol: symbol,
            temperature: temperature,
            feelsLike: feelsLike,
            high: high,
            low: low,
            humidity: humidity,
            rainChance: rainChance,
            wind: wind,
            hourly: hourly,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

}
