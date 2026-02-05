import SwiftUI
import AIMeterDomain
import AIMeterApplication
import AIMeterInfrastructure

/// UI-specific extensions for UsageStatus
public extension UsageStatus {
    /// Color for UI display
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
    var statusDescription: String {
        switch self {
        case .safe: return "Good"
        case .moderate: return "Moderate"
        case .critical: return "Near Limit"
        }
    }
}
