import Foundation

/// Usage status for color coding
public enum UsageStatus: String, Sendable, Codable, CaseIterable {
    /// 0-49% usage
    case safe
    /// 50-79% usage
    case moderate
    /// 80-100% usage
    case critical
}
