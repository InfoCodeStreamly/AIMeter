import Foundation
import AIMeterApplication

/// Service for managing notification preferences
@Observable
@MainActor
public final class NotificationPreferencesService: NotificationPreferencesProtocol {
    private let sentNotificationsKey = "sentNotifications"
    private let warningThresholdKey = "notificationWarningThreshold"
    private let criticalThresholdKey = "notificationCriticalThreshold"
    private let defaults = UserDefaults.standard

    // Stored properties for @Observable reactivity
    private var _isEnabled: Bool
    private var _warningThreshold: Int
    private var _criticalThreshold: Int

    public var isEnabled: Bool {
        get { _isEnabled }
        set {
            _isEnabled = newValue
            defaults.set(newValue, forKey: "notificationsEnabled")
        }
    }

    /// Warning threshold (default: 80%)
    public var warningThreshold: Int {
        get { _warningThreshold }
        set {
            _warningThreshold = newValue
            defaults.set(newValue, forKey: warningThresholdKey)
        }
    }

    /// Critical threshold (default: 95%)
    public var criticalThreshold: Int {
        get { _criticalThreshold }
        set {
            _criticalThreshold = newValue
            defaults.set(newValue, forKey: criticalThresholdKey)
        }
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
        // Initialize stored properties from UserDefaults
        let savedWarning = defaults.integer(forKey: warningThresholdKey)
        _warningThreshold = savedWarning > 0 ? savedWarning : 80

        let savedCritical = defaults.integer(forKey: criticalThresholdKey)
        _criticalThreshold = savedCritical > 0 ? savedCritical : 95

        if defaults.object(forKey: "notificationsEnabled") == nil {
            defaults.set(true, forKey: "notificationsEnabled")
            _isEnabled = true
        } else {
            _isEnabled = defaults.bool(forKey: "notificationsEnabled")
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
