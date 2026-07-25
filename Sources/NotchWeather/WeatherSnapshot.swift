import Foundation
import SwiftUI

struct WeatherSnapshot {
    struct HourlyForecast: Identifiable {
        let id = UUID()
        let hour: String
        let symbol: String
        let temperature: Int
        let isCurrentHour: Bool
    }

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

    var locationAbbreviation: String {
        [region, country].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    static let sample: WeatherSnapshot = {
        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)
        let hourly = (0...24).map { hour in
            let label = hourLabel(for: hour)
            let temperature = sampleTemperature(for: hour)
            let symbol = sampleSymbol(for: hour, temperature: temperature)
            return HourlyForecast(
                hour: label,
                symbol: symbol,
                temperature: temperature,
                isCurrentHour: hour == currentHour
            )
        }

        return WeatherSnapshot(
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
            hourly: hourly
        )
    }()

    private static func hourLabel(for hour: Int) -> String {
        let normalizedHour = hour % 24
        switch normalizedHour {
        case 0:
            return "12 AM"
        case 1...11:
            return "\(normalizedHour) AM"
        case 12:
            return "12 PM"
        default:
            return "\(normalizedHour - 12) PM"
        }
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
}
