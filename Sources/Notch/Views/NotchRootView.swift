import SwiftUI

struct NotchRootView: View {
    @StateObject private var store = WeatherStore()

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
        .onAppear {
            store.start()
        }
    }
}
