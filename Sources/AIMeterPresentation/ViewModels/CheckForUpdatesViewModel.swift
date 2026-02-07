import Sparkle
import SwiftUI

/// ViewModel for "Check for Updates" button (Sparkle wrapper)
@MainActor
@Observable
public final class CheckForUpdatesViewModel {
    public private(set) var canCheckForUpdates = false
    private let updater: SPUUpdater
    private nonisolated(unsafe) var observationTask: Task<Void, Never>?

    public init(updater: SPUUpdater) {
        self.updater = updater
        startObserving()
    }

    deinit {
        observationTask?.cancel()
    }

    public func checkForUpdates() {
        updater.checkForUpdates()
    }

    private func startObserving() {
        // Poll updater.canCheckForUpdates (KVO property) periodically
        canCheckForUpdates = updater.canCheckForUpdates
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled, let self else { break }
                self.canCheckForUpdates = self.updater.canCheckForUpdates
            }
        }
    }
}
