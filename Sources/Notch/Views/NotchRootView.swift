import SwiftUI

struct NotchRootView: View {
    @StateObject private var store = WeatherStore()
    @AppStorage("notch.theme") private var themeRawValue = NotchTheme.system.rawValue

    let layout: PanelLayout

    var body: some View {
        NotchView(
            snapshot: store.snapshot,
            layout: layout,
            onForecastRangeChange: { range in
                store.setForecastRange(range)
            },
            onHoverChanged: { _ in },
            onLocationRequest: {
                store.requestLocationAccess()
            }
        )
        .preferredColorScheme(NotchTheme(rawValue: themeRawValue)?.colorScheme)
        .onAppear {
            store.start()
        }
    }
}
