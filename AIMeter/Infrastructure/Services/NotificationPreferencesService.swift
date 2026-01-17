import Foundation
import SwiftUI
import os.log

/// Service for managing notification preferences and tracking sent notifications
@Observable
@MainActor
final class NotificationPreferencesService {
    private let logger = Logger.notifications
    private let sentNotificationsKey = "sentNotifications"
    private let defaults = UserDefaults.standard

    /// Whether notifications are enabled
    var isEnabled: Bool {
        get { defaults.bool(forKey: "notificationsEnabled") }
        set {
            defaults.set(newValue, forKey: "notificationsEnabled")
            logger.info("Notifications enabled: \(newValue)")
        }
    }

    /// Set of sent notification keys
    private var sentNotifications: Set<String> {
        get {
            guard let data = defaults.data(forKey: sentNotificationsKey),
                  let set = try? JSONDecoder().decode(Set<String>.self, from: data) else {
                return []
            }
            return set
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: sentNotificationsKey)
            }
        }
    }

    init() {
        // Set default value if not set
        if defaults.object(forKey: "notificationsEnabled") == nil {
            defaults.set(true, forKey: "notificationsEnabled")
        }
        // Clean up old notifications on init
        clearExpired()
    }

    /// Checks if notification was already sent
    /// - Parameter key: Notification identifier key
    /// - Returns: True if already sent
    func wasSent(key: String) -> Bool {
        sentNotifications.contains(key)
    }

    /// Marks notification as sent
    /// - Parameter key: Notification identifier key
    func markSent(key: String) {
        var current = sentNotifications
        current.insert(key)
        sentNotifications = current
        logger.debug("Marked notification as sent: \(key)")
    }

    /// Clears sent notifications older than 7 days
    func clearExpired() {
        let current = sentNotifications
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let validKeys = current.filter { key in
            // Extract date from key (format: type_threshold_date)
            let components = key.split(separator: "_")
            guard components.count >= 3 else { return false }

            // Last component is the date
            let dateString = String(components.last ?? "")
            guard let date = formatter.date(from: dateString) else { return false }

            return date > sevenDaysAgo
        }

        if validKeys.count != current.count {
            sentNotifications = validKeys
            logger.info("Cleared \(current.count - validKeys.count) expired notification records")
        }
    }

    /// Resets all sent notifications (for testing)
    func resetAll() {
        sentNotifications = []
        logger.info("Reset all sent notification records")
    }
}
