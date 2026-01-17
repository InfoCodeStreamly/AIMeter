import SwiftUI
import Sparkle

/// ViewModel for "Check for Updates" button (Sparkle wrapper)
public final class CheckForUpdatesViewModel: ObservableObject {
    @Published public private(set) var canCheckForUpdates = false
    private let updater: SPUUpdater

    public init(updater: SPUUpdater) {
        self.updater = updater
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    public func checkForUpdates() {
        updater.checkForUpdates()
    }
}
