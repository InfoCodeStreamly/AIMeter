import Foundation
import AIMeterApplication
@preconcurrency import UserNotifications

/// Service for sending system notifications (Infrastructure implementation)
public actor NotificationService: NotificationServiceProtocol {
    private let center = UNUserNotificationCenter.current()

    public init() {}

    public func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    public func isPermissionGranted() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    public func send(title: String, body: String, identifier: String) async {
        let hasPermission = await isPermissionGranted()
        if !hasPermission {
            let granted = await requestPermission()
            guard granted else { return }
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        try? await center.add(request)
    }

    public func removePending(identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public func removeDelivered(identifiers: [String]) async {
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
