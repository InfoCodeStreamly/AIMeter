import AIMeterApplication
import Foundation
import ServiceManagement

/// Service for managing launch at login functionality
@Observable
@MainActor
public final class LaunchAtLoginService: LaunchAtLoginServiceProtocol {
    public private(set) var isEnabled: Bool = false

    public init() {
        refreshStatus()
    }

    public func refreshStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    public func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }

    public func enable() {
        do {
            try SMAppService.mainApp.register()
            isEnabled = true
        } catch {}
    }

    public func disable() {
        do {
            try SMAppService.mainApp.unregister()
            isEnabled = false
        } catch {}
    }
}
