import AppKit
import Sparkle

/// Delegate for gentle update reminders (suitable for menu bar apps)
///
/// Implements Sparkle's recommended pattern for accessory/menu-bar apps:
/// 1. Show in Dock when update is available
/// 2. Clean up badge when user acknowledges
/// 3. Return to accessory mode when session ends
///
/// See: https://sparkle-project.org/documentation/gentle-reminders/
public final class GentleUpdateDelegate: NSObject, SPUStandardUserDriverDelegate {

    public override init() {
        super.init()
    }

    // MARK: - SPUStandardUserDriverDelegate

    public var supportsGentleScheduledUpdateReminders: Bool {
        true
    }

    /// Bring app to foreground before showing update alert
    public func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        let userInitiated = state.userInitiated
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate()

            // Ensure Sparkle update window appears above Settings (which is .floating)
            Self.raiseSparkleWindow()

            if !userInitiated {
                NSApp.dockTile.badgeLabel = "1"
            }
        }
    }

    /// Find Sparkle's update window and raise it above Settings.
    /// Retries after a short delay because Sparkle may not have created
    /// its window yet at the time of the delegate callback.
    private static func raiseSparkleWindow() {
        applySparkleWindowLevel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            applySparkleWindowLevel()
        }
    }

    private static func applySparkleWindowLevel() {
        for window in NSApp.windows where isSparkleWindow(window) {
            window.level = UIConstants.WindowLevel.updateAlert
            window.orderFrontRegardless()
        }
    }

    /// Detect Sparkle windows by class name prefix
    private static func isSparkleWindow(_ window: NSWindow) -> Bool {
        let className = String(describing: type(of: window))
        return className.hasPrefix("SPU") || className.contains("Sparkle")
    }

    /// User acknowledged the update — clear badge
    public func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        DispatchQueue.main.async {
            NSApp.dockTile.badgeLabel = ""
        }
    }

    /// Update session ended — return to menu bar only mode
    public func standardUserDriverWillFinishUpdateSession() {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
