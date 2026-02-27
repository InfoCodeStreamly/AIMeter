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

    /// Observers stored with nonisolated(unsafe) — only accessed on main actor
    nonisolated(unsafe) private static var windowObserver: Any?
    nonisolated(unsafe) private static var deactivateObserver: Any?

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
        let level = UIConstants.WindowLevel.updateAlert
        Task { @MainActor in
            NSApp.setActivationPolicy(.regular)
            NSApp.activate()

            Self.applyUpdateLevel(level)

            if !userInitiated {
                NSApp.dockTile.badgeLabel = "1"
            }

            Self.removeObservers()

            // Observe new windows becoming key — catches Sparkle window whenever it appears
            Self.windowObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    Self.applyUpdateLevel(level)
                }
            }

            // Re-raise Sparkle windows when app loses focus
            Self.deactivateObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    Self.applyUpdateLevel(level)
                }
            }

            // Retries — Sparkle may not have created its window yet
            for delay in [0.3, 0.7, 1.5] {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(delay))
                    Self.applyUpdateLevel(level)
                }
            }
        }
    }

    /// User acknowledged the update — clear badge
    public func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        Task { @MainActor in
            NSApp.dockTile.badgeLabel = ""
        }
    }

    /// Update session ended — return to menu bar only mode
    public func standardUserDriverWillFinishUpdateSession() {
        Task { @MainActor in
            Self.removeObservers()
            NSApp.setActivationPolicy(.accessory)
        }
    }

    // MARK: - Private

    @MainActor
    private static func removeObservers() {
        if let windowObserver {
            NotificationCenter.default.removeObserver(windowObserver)
        }
        if let deactivateObserver {
            NotificationCenter.default.removeObserver(deactivateObserver)
        }
        windowObserver = nil
        deactivateObserver = nil
    }

    @MainActor
    private static func applyUpdateLevel(_ level: NSWindow.Level) {
        for window in NSApp.windows where window.isVisible {
            // Skip the MenuBarExtra panel (managed by macOS, already at statusBar level)
            guard window.level.rawValue < NSWindow.Level.statusBar.rawValue else { continue }
            window.level = level
            window.hidesOnDeactivate = false
            window.collectionBehavior.insert(.fullScreenAuxiliary)
            window.orderFrontRegardless()
        }
    }
}
