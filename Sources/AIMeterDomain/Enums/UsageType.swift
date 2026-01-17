import Foundation

/// Type of usage metric
public enum UsageType: String, Sendable, Codable, CaseIterable {
    /// 5-hour session limit
    case session
    /// 7-day all models limit
    case weekly
    /// 7-day Opus limit
    case opus
    /// 7-day Sonnet limit
    case sonnet

    /// Whether this is primary metric
    public var isPrimary: Bool {
        self == .session
    }
}
