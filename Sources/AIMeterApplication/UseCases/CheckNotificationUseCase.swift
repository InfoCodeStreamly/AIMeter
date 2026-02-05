import Foundation
import AIMeterDomain

/// Request to send a notification
public struct NotificationRequest: Sendable {
    public let type: UsageType
    public let threshold: NotificationThreshold
    public let percentage: Int
    public let resetDate: Date

    public var title: String { threshold.title }
    public var body: String { threshold.body(for: type, percentage: percentage) }
    public var identifier: String { threshold.notificationKey(for: type, resetDate: resetDate) }
}

/// Use case for checking which notifications should be sent
@MainActor
public final class CheckNotificationUseCase {
    private let notificationService: any NotificationServiceProtocol
    private let preferencesService: any NotificationPreferencesProtocol

    public init(
        notificationService: any NotificationServiceProtocol,
        preferencesService: any NotificationPreferencesProtocol
    ) {
        self.notificationService = notificationService
        self.preferencesService = preferencesService
    }

    /// Checks usages and sends notifications if thresholds are crossed
    /// - Parameter usages: Current usage entities
    public func execute(usages: [UsageEntity]) async {
        // Skip if notifications are disabled
        guard preferencesService.isEnabled else { return }

        for usage in usages {
            await checkAndNotify(for: usage)
        }
    }

    private func checkAndNotify(for usage: UsageEntity) async {
        let percentage = usage.percentage.value
        let resetDate = usage.resetTime.date

        // Build dynamic thresholds from preferences
        let thresholds: [(value: Int, type: NotificationThreshold)] = [
            (preferencesService.warningThreshold, .warning),
            (preferencesService.criticalThreshold, .critical)
        ]

        for (thresholdValue, thresholdType) in thresholds {
            // Check if threshold is crossed
            guard percentage >= Double(thresholdValue) else { continue }

            // Check if already sent (use actual threshold value in key)
            let key = "\(usage.type.rawValue)_\(thresholdValue)_\(ISO8601DateFormatter().string(from: resetDate))"
            guard !preferencesService.wasSent(key: key) else { continue }

            // Send notification
            let request = NotificationRequest(
                type: usage.type,
                threshold: thresholdType,
                percentage: Int(percentage),
                resetDate: resetDate
            )

            await notificationService.send(
                title: request.title,
                body: request.body,
                identifier: key
            )

            // Mark as sent
            preferencesService.markSent(key: key)
        }
    }
}
