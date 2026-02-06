import AIMeterApplication
import AIMeterDomain
import AIMeterInfrastructure
import SwiftUI

/// UI-specific extensions for UsageStatus
extension UsageStatus {
    /// Color for UI display
    public var color: Color {
        switch self {
        case .safe: return AccessibleColors.safe
        case .moderate: return AccessibleColors.moderate
        case .critical: return .red
        }
    }

    /// SF Symbol icon name
    public var icon: String {
        switch self {
        case .safe: return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }

    /// Human-readable description
    public var statusDescription: String {
        switch self {
        case .safe: return "Good"
        case .moderate: return "Moderate"
        case .critical: return "Near Limit"
        }
    }
}
