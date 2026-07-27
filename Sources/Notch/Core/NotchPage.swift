import SwiftUI

enum NotchPage: String, CaseIterable, Identifiable {
    case home
    case weather
    case markets
    case sounds
    case tokenSpend
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .weather: return "Weather"
        case .markets: return "Markets"
        case .sounds: return "Now Playing"
        case .tokenSpend: return "Token Spend"
        case .settings: return "Settings"
        }
    }

    var subtitle: String {
        switch self {
        case .home: return "Choose a widget"
        case .weather: return "Current conditions"
        case .markets: return "Market dashboard"
        case .sounds: return "Computer audio"
        case .tokenSpend: return "Usage scaffold"
        case .settings: return "Panel preferences"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "square.grid.2x2"
        case .weather: return "cloud.sun.fill"
        case .markets: return "chart.line.uptrend.xyaxis"
        case .sounds: return "waveform"
        case .tokenSpend: return "chart.pie.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var accent: Color {
        switch self {
        case .home: return Color.cyan
        case .weather: return Color.orange
        case .markets: return Color.green
        case .sounds: return Color.purple
        case .tokenSpend: return Color.blue
        case .settings: return Color.white.opacity(0.9)
        }
    }
}
