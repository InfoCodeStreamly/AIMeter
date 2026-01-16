import SwiftUI

/// Usage status for color coding
enum UsageStatus: String, Sendable, Codable, CaseIterable {
    /// 0-50% usage
    case safe
    /// 51-80% usage
    case moderate
    /// 81-100% usage
    case critical

    /// Color for UI
    var color: Color {
        switch self {
        case .safe: return .green
        case .moderate: return .orange
        case .critical: return .red
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .safe: return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }

    /// Human-readable description
    var description: String {
        switch self {
        case .safe: return "Good"
        case .moderate: return "Moderate"
        case .critical: return "Near Limit"
        }
    }
}
