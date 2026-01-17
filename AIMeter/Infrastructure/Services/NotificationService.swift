import Foundation
import UserNotifications
import os.log

/// Service for sending system notifications
actor NotificationService {
    private let logger = Logger.notifications
    private let center = UNUserNotificationCenter.current()

    /// Requests notification permission from user
    /// - Returns: True if granted
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("Notification permission: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Failed to request notification permission: \(error.localizedDescription)")
            return false
        }
    }

    /// Checks if notification permission is granted
    func isPermissionGranted() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    /// Sends a notification
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body
    ///   - identifier: Unique identifier for the notification
    func send(title: String, body: String, identifier: String) async {
        // Request permission if needed
        let hasPermission = await isPermissionGranted()
        if !hasPermission {
            let granted = await requestPermission()
            guard granted else {
                logger.warning("Cannot send notification - permission denied")
                return
            }
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Deliver immediately
        )

        do {
            try await center.add(request)
            logger.info("Notification sent: \(identifier)")
        } catch {
            logger.error("Failed to send notification: \(error.localizedDescription)")
        }
    }

    /// Removes pending notifications
    func removePending(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Removes delivered notifications
    func removeDelivered(identifiers: [String]) {
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
