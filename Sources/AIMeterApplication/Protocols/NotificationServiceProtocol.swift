import Foundation

/// Protocol for sending system notifications
public protocol NotificationServiceProtocol: Sendable {
    /// Requests notification permission from user
    func requestPermission() async -> Bool

    /// Checks if notification permission is granted
    func isPermissionGranted() async -> Bool

    /// Sends a notification
    func send(title: String, body: String, identifier: String) async

    /// Removes pending notifications
    func removePending(identifiers: [String]) async

    /// Removes delivered notifications
    func removeDelivered(identifiers: [String]) async
}
