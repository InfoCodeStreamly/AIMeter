import Foundation

/// Threshold levels for usage notifications
public enum NotificationThreshold: Double, CaseIterable, Sendable, Codable {
    /// Warning at 80% usage
    case warning = 80
    /// Critical at 95% usage
    case critical = 95

    /// Notification title
    public var title: String {
        switch self {
        case .warning:
            return "Usage Warning"
        case .critical:
            return "Usage Critical"
        }
    }

    /// Notification body template
    public func body(for type: UsageType, percentage: Int) -> String {
        let typeName = Self.notificationTypeName(for: type)
        switch self {
        case .warning:
            return "\(typeName) usage at \(percentage)%. Consider slowing down."
        case .critical:
            return "\(typeName) usage at \(percentage)%! Limit almost reached."
        }
    }

    /// Type name for notifications (system notifications use system locale)
    private static func notificationTypeName(for type: UsageType) -> String {
        switch type {
        case .session: return "Session"
        case .weekly: return "Weekly"
        case .opus: return "Opus"
        case .sonnet: return "Sonnet"
        }
    }

    /// Check if percentage crosses this threshold
    public func isCrossed(by percentage: Double) -> Bool {
        percentage >= rawValue
    }

    /// Unique identifier for tracking sent notifications
    public func notificationKey(for type: UsageType, resetDate: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let dateString = formatter.string(from: resetDate)
        return "\(type.rawValue)_\(Int(rawValue))_\(dateString)"
    }
}
