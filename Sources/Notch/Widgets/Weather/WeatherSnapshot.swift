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

    static let sample: WeatherSnapshot = {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let nowHour = calendar.component(.hour, from: Date())

        let hourly = (0...24).map { hour in
            let date = calendar.date(byAdding: .hour, value: hour, to: startOfDay) ?? startOfDay
            let temperature = sampleTemperature(for: hour)
            let symbol = sampleSymbol(for: hour, temperature: temperature)
            return HourlyForecast(
                date: date,
                hour: hourLabel(for: date),
                symbol: symbol,
                temperature: temperature,
                feelsLike: temperature + (hour % 3 == 0 ? 2 : 1),
                humidity: sampleHumidity(for: hour),
                wind: sampleWind(for: hour),
                windDirectionDegrees: sampleWindDirection(for: hour),
                isCurrentHour: hour == nowHour
            )
        }

        return WeatherSnapshot(
            hasLiveData: true,
            city: "San Francisco",
            region: "CA",
            country: "US",
            condition: "Partly Cloudy",
            symbol: "cloud.sun.fill",
            temperature: 72,
            feelsLike: 74,
            high: 76,
            low: 61,
            humidity: 58,
            wind: 9,
            hourly: hourly,
            timeZoneIdentifier: calendar.timeZone.identifier
        )
    }()

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
            wind: wind,
            hourly: hourly,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

    private static func hourLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "ha"
        return formatter.string(from: date).lowercased().replacingOccurrences(of: " ", with: "")
    }

    private static func sampleTemperature(for hour: Int) -> Int {
        let phase = Double(hour) / 24.0
        let baseline = 69.0
        let swing = 6.0 * sin((phase * 2.0 * .pi) - (.pi / 2.0))
        let secondary = 1.5 * sin((phase * 4.0 * .pi) + 0.8)
        return Int((baseline + swing + secondary).rounded())
    }

    private static func sampleSymbol(for hour: Int, temperature: Int) -> String {
        switch hour {
        case 0...5:
            return temperature < 64 ? "cloud.moon.fill" : "moon.stars.fill"
        case 6...10:
            return "cloud.sun.fill"
        case 11...15:
            return "sun.max.fill"
        case 16...19:
            return "cloud.sun.fill"
        default:
            return "cloud.moon.fill"
        }
    }

    private static func sampleHumidity(for hour: Int) -> Int {
        let cycle = sin((Double(hour) / 24.0) * 2.0 * .pi)
        return Int((58.0 + (cycle * 10.0)).rounded())
    }

    private static func sampleWind(for hour: Int) -> Int {
        let cycle = sin((Double(hour) / 24.0) * 4.0 * .pi + 0.7)
        return max(4, Int((7.0 + (cycle * 2.5)).rounded()))
    }

    private static func sampleWindDirection(for hour: Int) -> Int {
        let directions = [0, 45, 90, 135, 180, 225, 270, 315]
        return directions[hour % directions.count]
    }
}
