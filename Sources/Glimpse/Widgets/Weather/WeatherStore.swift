import AppKit
import CoreLocation
import Foundation
import SwiftUI

@MainActor
final class WeatherStore: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published private(set) var snapshot: WeatherSnapshot = .placeholder

    private let locationManager = CLLocationManager()
    private var weatherTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var hasRequestedAuthorization = false
    private var hasStarted = false
    private var lastContext: WeatherContext?
    private var forecastRange: WeatherForecastRange = .oneDay

    private struct WeatherContext {
        let location: CLLocation
        let city: String
        let region: String
        let country: String
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    deinit {
        weatherTask?.cancel()
        refreshTask?.cancel()
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        bootstrap()
        startRefreshLoop()
    }

    private func bootstrap() {
        let status = locationManager.authorizationStatus
        if status == .authorized || status == .authorizedAlways {
            requestCurrentLocation()
            return
        }

        if status == .notDetermined && !hasRequestedAuthorization {
            hasRequestedAuthorization = true
            locationManager.requestWhenInUseAuthorization()
        }
    }

    private func requestCurrentLocation() {
        locationManager.requestLocation()
    }

    func requestLocationAccess() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            if !hasRequestedAuthorization {
                hasRequestedAuthorization = true
            }
            locationManager.requestWhenInUseAuthorization()
        case .authorized, .authorizedAlways:
            requestCurrentLocation()
        case .denied, .restricted:
            openLocationSettings()
        @unknown default:
            break
        }
    }

    func setForecastRange(_ range: WeatherForecastRange) {
        guard forecastRange != range else { return }
        forecastRange = range

        guard let context = lastContext else { return }
        weatherTask?.cancel()
        weatherTask = Task { [weak self] in
            await self?.refreshLiveWeather(for: context)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorized, .authorizedAlways:
            requestCurrentLocation()
        case .denied, .restricted, .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        weatherTask?.cancel()
        weatherTask = Task { [weak self] in
            guard let self else { return }
            await self.loadWeather(for: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        snapshot = .placeholder
    }

    private func loadWeather(for location: CLLocation) async {
        var city = "Current Location"
        var region = ""
        var country = ""

        do {
            let placemark = try await reverseGeocode(location)
            city = displayCity(from: placemark)
            region = displayRegion(from: placemark)
            country = displayCountry(from: placemark)
        } catch {
            print("WeatherStore load failed: \(error)")
        }

        lastContext = WeatherContext(location: location, city: city, region: region, country: country)

        withAnimation(.easeInOut(duration: 0.35)) {
            snapshot = WeatherSnapshot.locationOnly(city: city, region: region, country: country)
        }

        do {
            let liveSnapshot = try await OpenMeteoWeatherService.fetchSnapshot(
                for: location,
                city: city,
                region: region,
                country: country,
                forecastRange: forecastRange
            )
            withAnimation(.easeInOut(duration: 0.45)) {
                snapshot = liveSnapshot
            }
        } catch {
            print("OpenMeteoWeatherService failed: \(error)")
            withAnimation(.easeInOut(duration: 0.35)) {
                snapshot = WeatherSnapshot.weatherUnavailable(city: city, region: region, country: country)
            }
        }
    }

    private func refreshLiveWeather(for context: WeatherContext? = nil) async {
        guard let context = context ?? lastContext else { return }

        do {
            let liveSnapshot = try await OpenMeteoWeatherService.fetchSnapshot(
                for: context.location,
                city: context.city,
                region: context.region,
                country: context.country,
                forecastRange: forecastRange
            )
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.45)) {
                snapshot = liveSnapshot
            }
        } catch {
            print("OpenMeteoWeatherService refresh failed: \(error)")
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                snapshot = WeatherSnapshot.weatherUnavailable(
                    city: context.city,
                    region: context.region,
                    country: context.country
                )
            }
        }
    }

    private func startRefreshLoop() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10 * 60 * 1_000_000_000)
                guard !Task.isCancelled else { return }
                guard let self else { return }
                await self.refreshLiveWeather()
            }
        }
    }

    private func reverseGeocode(_ location: CLLocation) async throws -> CLPlacemark? {
        let geocoder = CLGeocoder()

        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: placemarks?.first)
            }
        }
    }

    private func displayCity(from placemark: CLPlacemark?) -> String {
        placemark?.locality
            ?? placemark?.subAdministrativeArea
            ?? placemark?.name
            ?? "Current Location"
    }

    private func displayRegion(from placemark: CLPlacemark?) -> String {
        placemark?.administrativeArea ?? ""
    }

    private func displayCountry(from placemark: CLPlacemark?) -> String {
        placemark?.isoCountryCode ?? ""
    }

    private func openLocationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
