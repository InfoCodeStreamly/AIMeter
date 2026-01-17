import SwiftUI

/// UI-related constants
enum UIConstants {
    /// Menu bar popover dimensions
    enum MenuBar {
        static let width: CGFloat = 280
        static let minHeight: CGFloat = 200
        static let maxHeight: CGFloat = 400
    }

    /// Spacing constants
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    /// Corner radius constants
    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
    }

    /// Animation durations
    enum Animation {
        static let fast: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.5
    }

    /// Progress circle sizes
    enum ProgressCircle {
        static let primarySize: CGFloat = 48
        static let secondarySize: CGFloat = 36
        static let primaryLineWidth: CGFloat = 6
        static let secondaryLineWidth: CGFloat = 4
    }

    /// Usage thresholds (percentage)
    enum Thresholds {
        static let safe: Double = 50
        static let moderate: Double = 80
        // Above 80% is critical
    }

    /// Settings window dimensions
    enum Settings {
        static let windowWidth: CGFloat = 420
        static let windowHeight: CGFloat = 450
    }
}
