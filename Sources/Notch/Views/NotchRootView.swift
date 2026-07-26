import SwiftUI

struct NotchRootView: View {
    @StateObject private var store = WeatherStore()

    let layout: PanelLayout

    var body: some View {
        NotchView(
            snapshot: store.snapshot,
            layout: layout,
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
