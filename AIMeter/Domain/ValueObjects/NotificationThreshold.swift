import Foundation

/// Threshold levels for usage notifications
enum NotificationThreshold: Double, CaseIterable, Sendable, Codable {
    /// Warning at 80% usage
    case warning = 80
    /// Critical at 95% usage
    case critical = 95

    /// Notification title
    var title: String {
        switch self {
        case .warning:
            return "Usage Warning"
        case .critical:
            return "Usage Critical"
        }
    }

    /// Notification body template
    func body(for type: UsageType, percentage: Int) -> String {
        switch self {
        case .warning:
            return "\(type.displayName) usage at \(percentage)%. Consider slowing down."
        case .critical:
            return "\(type.displayName) usage at \(percentage)%! Limit almost reached."
        }
    }

    /// Check if percentage crosses this threshold
    func isCrossed(by percentage: Double) -> Bool {
        percentage >= rawValue
    }

    /// Unique identifier for tracking sent notifications
    func notificationKey(for type: UsageType, resetDate: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let dateString = formatter.string(from: resetDate)
        return "\(type.rawValue)_\(Int(rawValue))_\(dateString)"
    }
}
