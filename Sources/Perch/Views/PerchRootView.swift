import SwiftUI

struct PerchRootView: View {
    @StateObject private var store = WeatherStore()

    let layout: PanelLayout

    var body: some View {
        PerchView(
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
        .onAppear {
            store.start()
        }
    }
}
