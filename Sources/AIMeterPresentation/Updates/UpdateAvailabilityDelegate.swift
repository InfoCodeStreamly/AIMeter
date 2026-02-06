import Foundation
import Sparkle

/// Delegate that tracks whether a new update is available via Sparkle
/// Used to show update indicator in menu bar and update banner in popover
@MainActor
@Observable
public final class UpdateAvailabilityDelegate: NSObject, SPUUpdaterDelegate {
    public private(set) var updateAvailable: Bool = false
    public private(set) var availableVersion: String?

    public override init() {
        super.init()
    }

    // MARK: - SPUUpdaterDelegate

    nonisolated public func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let version = item.displayVersionString
        Task { @MainActor in
            self.updateAvailable = true
            self.availableVersion = version
        }
    }

    nonisolated public func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        Task { @MainActor in
            self.updateAvailable = false
            self.availableVersion = nil
        }
    }
}
