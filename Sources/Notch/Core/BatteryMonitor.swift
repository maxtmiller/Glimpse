import Foundation
import IOKit.ps
import SwiftUI

struct BatteryReading: Equatable {
    let percentage: Int
    let isCharging: Bool
    let isPluggedIn: Bool
}

@MainActor
final class BatteryMonitor: ObservableObject {
    @Published private(set) var reading: BatteryReading?

    private var refreshTimer: Timer?

    init() {
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }

    private func refresh() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)
                .takeUnretainedValue() as? [String: Any],
                let currentCapacity = description[kIOPSCurrentCapacityKey as String] as? Int,
                let maxCapacity = description[kIOPSMaxCapacityKey as String] as? Int,
                maxCapacity > 0
            else {
                continue
            }

            let state = description[kIOPSPowerSourceStateKey as String] as? String
            let isCharging = state == kIOPSACPowerValue as String
                && (description[kIOPSIsChargingKey as String] as? Bool ?? false)

            reading = BatteryReading(
                percentage: max(0, min(100, Int((Double(currentCapacity) / Double(maxCapacity) * 100).rounded()))),
                isCharging: isCharging,
                isPluggedIn: state == kIOPSACPowerValue as String
            )
            return
        }

        reading = nil
    }
}
