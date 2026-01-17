import Foundation
import AppKit
import Sparkle

/// Delegate for Sparkle gentle update reminders (menu bar apps)
/// Shows dock badge and notification when update is available
/// Reference: https://sparkle-project.org/documentation/gentle-reminders
final class GentleUpdateDelegate: NSObject, SPUStandardUserDriverDelegate {

    /// Declares support for gentle scheduled update reminders
    var supportsGentleScheduledUpdateReminders: Bool {
        return true
    }

    /// Called when Sparkle is about to show an update
    /// Shows app in Dock with badge to notify user
    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        // Show app in Dock temporarily
        NSApp.setActivationPolicy(.regular)
        // Show badge with "1" to indicate update available
        NSApp.dockTile.badgeLabel = "1"
    }

    /// Called when user has seen the update notification
    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        // Clear the badge
        NSApp.dockTile.badgeLabel = ""
    }

    /// Called when update session finishes
    func standardUserDriverWillFinishUpdateSession() {
        // Hide app from Dock again (menu bar only)
        NSApp.setActivationPolicy(.accessory)
    }
}
