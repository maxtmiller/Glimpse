import CoreLocation
import Foundation

enum OpenMeteoWeatherService {
    static func fetchSnapshot(
        for location: CLLocation,
        city: String,
        region: String,
        country: String
    ) async throws -> WeatherSnapshot {
        let response = try await fetchResponse(for: location)
        return makeSnapshot(
            from: response,
            city: city,
            region: region,
            country: country
        )
    }

    private static func fetchResponse(for location: CLLocation) async throws -> [String: Any] {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "2"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(
                name: "current",
                value: "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code,is_day"
            ),
            URLQueryItem(
                name: "hourly",
                value: "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code"
            ),
            URLQueryItem(
                name: "daily",
                value: "temperature_2m_max,temperature_2m_min,weather_code"
            )
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let object = json as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        return object
    }

    private static func makeSnapshot(
        from response: [String: Any],
        city: String,
        region: String,
        country: String
    ) -> WeatherSnapshot {
        let timeZone = TimeZone(identifier: stringValue(response, key: "timezone") ?? "") ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let now = Date()
        let current = dictionaryValue(response, key: "current")
            ?? dictionaryValue(response, key: "current_weather")
        let hourlyPayload = dictionaryValue(response, key: "hourly") ?? [:]
        let daily = dictionaryValue(response, key: "daily") ?? [:]

        let currentCode =
            intValue(current, key: "weather_code")
            ?? intValue(current, key: "weatherCode")
            ?? intValue(current, key: "weathercode")
            ?? 3
        let currentIsDay = (intValue(current, key: "is_day") ?? intValue(current, key: "isDay") ?? 1) != 0
        let condition = conditionDescription(for: currentCode)
        let symbol = symbolName(for: currentCode, isDay: currentIsDay)

        let temperature = Int(
            doubleValue(current, key: "temperature_2m")
            ?? doubleValue(current, key: "temperature2m")
            ?? doubleValue(current, key: "temperature")
            ?? 0
        )
        let feelsLike = Int(doubleValue(current, key: "apparent_temperature") ?? doubleValue(current, key: "apparentTemperature") ?? Double(temperature))
        let humidity = Int(doubleValue(current, key: "relative_humidity_2m") ?? doubleValue(current, key: "relativeHumidity2m") ?? 0)
        let wind = Int(
            doubleValue(current, key: "wind_speed_10m")
            ?? doubleValue(current, key: "windSpeed10m")
            ?? doubleValue(current, key: "windspeed")
            ?? 0
        )
        let windDirection = Int(
            doubleValue(current, key: "wind_direction_10m")
            ?? doubleValue(current, key: "windDirection10m")
            ?? 0
        )
        let high = Int((firstDoubleArrayValue(daily, key: "temperature_2m_max") ?? firstDoubleArrayValue(daily, key: "temperature2mMax") ?? Double(temperature)).rounded())
        let low = Int((firstDoubleArrayValue(daily, key: "temperature_2m_min") ?? firstDoubleArrayValue(daily, key: "temperature2mMin") ?? Double(temperature)).rounded())

        let times = stringArrayValue(hourlyPayload, key: "time") ?? []
        let temperatures = doubleArrayValue(hourlyPayload, key: "temperature_2m") ?? doubleArrayValue(hourlyPayload, key: "temperature2m") ?? []
        let feelsLikes = doubleArrayValue(hourlyPayload, key: "apparent_temperature") ?? doubleArrayValue(hourlyPayload, key: "apparentTemperature") ?? []
        let humidities = doubleArrayValue(hourlyPayload, key: "relative_humidity_2m") ?? doubleArrayValue(hourlyPayload, key: "relativeHumidity2m") ?? []
        let winds = doubleArrayValue(hourlyPayload, key: "wind_speed_10m") ?? doubleArrayValue(hourlyPayload, key: "windSpeed10m") ?? doubleArrayValue(hourlyPayload, key: "windspeed") ?? []
        let windDirections = doubleArrayValue(hourlyPayload, key: "wind_direction_10m") ?? doubleArrayValue(hourlyPayload, key: "windDirection10m") ?? []
        let weatherCodes = intArrayValue(hourlyPayload, key: "weather_code") ?? intArrayValue(hourlyPayload, key: "weatherCode") ?? intArrayValue(hourlyPayload, key: "weathercode") ?? []

        let hourlyCount = min(25, times.count)

        let hourlyForecasts = (0..<hourlyCount).compactMap { index -> WeatherSnapshot.HourlyForecast? in
            guard let date = parseForecastDate(times[index], timeZone: timeZone) else {
                return nil
            }

            let hourTemperature = Int((temperatures[safe: index] ?? Double(temperature)).rounded())
            let hourFeelsLike = Int((feelsLikes[safe: index] ?? Double(feelsLike)).rounded())
            let hourHumidity = Int((humidities[safe: index] ?? Double(humidity)).rounded())
            let hourWind = Int((winds[safe: index] ?? Double(wind)).rounded())
            let hourWindDirection = Int((windDirections[safe: index] ?? Double(windDirection)).rounded())
            let hourCode = weatherCodes[safe: index] ?? currentCode
            let hourIsDay = isDaytime(for: date, calendar: calendar)

            return WeatherSnapshot.HourlyForecast(
                date: date,
                hour: hourLabel(for: date, timeZone: timeZone),
                symbol: symbolName(for: hourCode, isDay: hourIsDay),
                temperature: hourTemperature,
                feelsLike: hourFeelsLike,
                humidity: hourHumidity,
                wind: hourWind,
                windDirectionDegrees: hourWindDirection,
                isCurrentHour: calendar.isDate(date, equalTo: now, toGranularity: .hour)
            )
        }

        return WeatherSnapshot.live(
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
            timeZoneIdentifier: timeZone.identifier,
            hourly: hourlyForecasts
        )
    }

    private static func parseForecastDate(_ value: String, timeZone: TimeZone) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let date = formatter.date(from: value) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: value) {
            return date
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = timeZone
        return isoFormatter.date(from: value)
    }

    private static func hourLabel(for date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "ha"
        return formatter.string(from: date).lowercased().replacingOccurrences(of: " ", with: "")
    }

    private static func isDaytime(for date: Date, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return (6..<18).contains(hour)
    }

    private static func conditionDescription(for code: Int) -> String {
        switch code {
        case 0:
            return "Clear"
        case 1:
            return "Mainly Clear"
        case 2:
            return "Partly Cloudy"
        case 3:
            return "Overcast"
        case 45, 48:
            return "Fog"
        case 51, 53, 55:
            return "Drizzle"
        case 56, 57:
            return "Freezing Drizzle"
        case 61, 63, 65:
            return "Rain"
        case 66, 67:
            return "Freezing Rain"
        case 71, 73, 75:
            return "Snow"
        case 77:
            return "Snow Grains"
        case 80, 81, 82:
            return "Rain Showers"
        case 85, 86:
            return "Snow Showers"
        case 95:
            return "Thunderstorm"
        case 96, 99:
            return "Thunderstorm"
        default:
            return "Cloudy"
        }
    }

    private static func symbolName(for code: Int, isDay: Bool) -> String {
        switch code {
        case 0:
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1:
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 2:
            return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55, 56, 57:
            return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86:
            return "cloud.snow.fill"
        case 95, 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        }
    }
}

private func dictionaryValue(_ dictionary: [String: Any]?, key: String) -> [String: Any]? {
    dictionary?[key] as? [String: Any]
}

private func stringValue(_ dictionary: [String: Any], key: String) -> String? {
    dictionary[key] as? String
}

private func doubleValue(_ dictionary: [String: Any]?, key: String) -> Double? {
    if let value = dictionary?[key] as? Double {
        return value
    }

    if let value = dictionary?[key] as? NSNumber {
        return value.doubleValue
    }

    if let value = dictionary?[key] as? Int {
        return Double(value)
    }

    return nil
}

private func intValue(_ dictionary: [String: Any]?, key: String) -> Int? {
    if let value = dictionary?[key] as? Int {
        return value
    }

    if let value = dictionary?[key] as? NSNumber {
        return value.intValue
    }

    if let value = dictionary?[key] as? Double {
        return Int(value.rounded())
    }

    return nil
}

private func stringArrayValue(_ dictionary: [String: Any], key: String) -> [String]? {
    dictionary[key] as? [String]
}

private func doubleArrayValue(_ dictionary: [String: Any], key: String) -> [Double]? {
    if let values = dictionary[key] as? [Double] {
        return values
    }

    if let values = dictionary[key] as? [NSNumber] {
        return values.map { $0.doubleValue }
    }

    if let values = dictionary[key] as? [Any] {
        return values.compactMap {
            if let number = $0 as? NSNumber {
                return number.doubleValue
            }

            if let double = $0 as? Double {
                return double
            }

            if let int = $0 as? Int {
                return Double(int)
            }

            return nil
        }
    }

    return nil
}

private func intArrayValue(_ dictionary: [String: Any], key: String) -> [Int]? {
    if let values = dictionary[key] as? [Int] {
        return values
    }

    if let values = dictionary[key] as? [NSNumber] {
        return values.map { $0.intValue }
    }

    if let values = dictionary[key] as? [Any] {
        return values.compactMap {
            if let number = $0 as? NSNumber {
                return number.intValue
            }

            if let int = $0 as? Int {
                return int
            }

            if let double = $0 as? Double {
                return Int(double.rounded())
            }

            return nil
        }
    }

    return nil
}

private func firstDoubleArrayValue(_ dictionary: [String: Any], key: String) -> Double? {
    doubleArrayValue(dictionary, key: key)?.first
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
