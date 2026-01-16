import Foundation
import ServiceManagement
import os.log

/// Service for managing launch at login functionality
/// Uses SMAppService (macOS 13+) - no helper app required
@Observable
@MainActor
final class LaunchAtLoginService {
    private(set) var isEnabled: Bool = false

    private let logger = Logger.launchAtLogin

    init() {
        refreshStatus()
    }

    /// Refreshes the current status from system
    func refreshStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
        logger.debug("Launch at login status: \(self.isEnabled)")
    }

    /// Toggles launch at login
    func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }

    /// Enables launch at login
    func enable() {
        do {
            try SMAppService.mainApp.register()
            isEnabled = true
            logger.info("Launch at login enabled")
        } catch {
            logger.error("Failed to enable launch at login: \(error.localizedDescription)")
        }
    }

    /// Disables launch at login
    func disable() {
        do {
            try SMAppService.mainApp.unregister()
            isEnabled = false
            logger.info("Launch at login disabled")
        } catch {
            logger.error("Failed to disable launch at login: \(error.localizedDescription)")
        }
    }
}
