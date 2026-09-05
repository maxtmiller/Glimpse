import Combine
import Foundation
import SwiftUI

@MainActor
final class MarketStore: ObservableObject {
    @Published private(set) var snapshot: MarketSnapshot = .empty
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var refreshTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    private var hasStarted = false

    deinit {
        refreshTask?.cancel()
        loadTask?.cancel()
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        load()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                guard !Task.isCancelled else { return }
                self?.load()
            }
        }
    }

    func refreshNow() {
        load()
    }

    private func load() {
        loadTask?.cancel()
        isLoading = true
        loadTask = Task { [weak self] in
            do {
                let liveSnapshot = try await YahooFinanceMarketService.fetchSnapshot(from: MarketSnapshot.marketUniverse)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        self?.snapshot = liveSnapshot
                        self?.errorMessage = nil
                        self?.isLoading = false
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.errorMessage = error.localizedDescription
                    self?.snapshot = .empty
                    self?.isLoading = false
                }
            }
        }
    }
}
