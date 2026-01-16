import Foundation

/// Type of usage metric
enum UsageType: String, Sendable, Codable, CaseIterable {
    /// 5-hour session limit
    case session
    /// 7-day all models limit
    case weekly
    /// 7-day Opus limit
    case opus
    /// 7-day Sonnet limit
    case sonnet

    /// Display name for UI
    var displayName: String {
        switch self {
        case .session: return "Session"
        case .weekly: return "Weekly"
        case .opus: return "Opus"
        case .sonnet: return "Sonnet"
        }
    }

    /// Subtitle for UI
    var subtitle: String {
        switch self {
        case .session: return "5-hour window"
        case .weekly: return "All models"
        case .opus: return "Weekly"
        case .sonnet: return "Weekly"
        }
    }

    /// Whether this is primary metric
    var isPrimary: Bool {
        self == .session
    }
}
