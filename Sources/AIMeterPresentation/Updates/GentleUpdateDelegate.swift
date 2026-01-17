import Foundation
import Sparkle

/// Delegate for gentle update reminders (suitable for menu bar apps)
/// Configures Sparkle to show non-intrusive update notifications
public final class GentleUpdateDelegate: NSObject, SPUStandardUserDriverDelegate {

    public override init() {
        super.init()
    }

    // MARK: - SPUStandardUserDriverDelegate

    /// Returns whether the update check was initiated by the user
    /// For menu bar apps, we want automatic checks to be gentle
    public var supportsGentleScheduledUpdateReminders: Bool {
        true
    }

    /// Called when Sparkle wants to show a scheduled update
    /// We use gentle reminders for menu bar apps
    public func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        // Gentle handling is done automatically by Sparkle when supportsGentleScheduledUpdateReminders is true
    }

    /// Called when user dismisses the update
    public func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        // Optional: track user engagement with updates
    }
}
