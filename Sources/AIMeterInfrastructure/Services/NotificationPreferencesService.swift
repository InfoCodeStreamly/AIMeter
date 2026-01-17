import Foundation
import AIMeterApplication

/// Service for managing notification preferences
@Observable
@MainActor
public final class NotificationPreferencesService: NotificationPreferencesProtocol {
    private let sentNotificationsKey = "sentNotifications"
    private let defaults = UserDefaults.standard

    public var isEnabled: Bool {
        get { defaults.bool(forKey: "notificationsEnabled") }
        set { defaults.set(newValue, forKey: "notificationsEnabled") }
    }

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

    public init() {
        if defaults.object(forKey: "notificationsEnabled") == nil {
            defaults.set(true, forKey: "notificationsEnabled")
        }
        clearExpired()
    }

    public func wasSent(key: String) -> Bool {
        sentNotifications.contains(key)
    }

    public func markSent(key: String) {
        var current = sentNotifications
        current.insert(key)
        sentNotifications = current
    }

    public func clearExpired() {
        let current = sentNotifications
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let validKeys = current.filter { key in
            let components = key.split(separator: "_")
            guard components.count >= 3 else { return false }
            let dateString = String(components.last ?? "")
            guard let date = formatter.date(from: dateString) else { return false }
            return date > sevenDaysAgo
        }

        if validKeys.count != current.count {
            sentNotifications = validKeys
        }
    }

    public func resetAll() {
        sentNotifications = []
    }
}
