import Foundation

/// Protocol for managing launch at login functionality
@MainActor
public protocol LaunchAtLoginServiceProtocol: AnyObject {
    var isEnabled: Bool { get }
    func toggle()
    func refreshStatus()
}
