import Foundation
import AIMeterDomain

/// Protocol for managing notification preferences
@MainActor
public protocol NotificationPreferencesProtocol: Sendable {
    /// Whether notifications are enabled
    var isEnabled: Bool { get set }

    /// Checks if notification was already sent
    /// - Parameter key: Notification identifier key
    /// - Returns: True if already sent
    func wasSent(key: String) -> Bool

    /// Marks notification as sent
    /// - Parameter key: Notification identifier key
    func markSent(key: String)

    /// Clears sent notifications older than 7 days
    func clearExpired()

    /// Resets all sent notifications
    func resetAll()
}
