import AppKit
import SwiftUI

/// UI-related constants
enum UIConstants {
    /// Menu bar popover dimensions
    enum MenuBar {
        static let width: CGFloat = 300
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

    /// Progress circle sizes (legacy)
    enum ProgressCircle {
        static let primarySize: CGFloat = 48
        static let secondarySize: CGFloat = 36
        static let primaryLineWidth: CGFloat = 6
        static let secondaryLineWidth: CGFloat = 4
    }

    /// Progress bar dimensions
    enum ProgressBar {
        static let height: CGFloat = 8
        static let cornerRadius: CGFloat = 4
    }

    /// Usage thresholds (percentage)
    enum Thresholds {
        static let safe: Double = 50
        static let moderate: Double = 80
        // Above 80% is critical
    }

    /// Window identifiers (SSOT for openWindow(id:))
    enum WindowID {
        static let settings = "settings"
        static let usageDetail = "usage-detail"
    }

    /// Window level hierarchy (SSOT)
    ///
    /// Settings window floats above normal windows, but Sparkle update
    /// alert must appear above Settings so the user always sees it.
    enum WindowLevel {
        /// Settings window — above normal, below update alerts
        static let settings = NSWindow.Level(NSWindow.Level.floating.rawValue)
        /// Sparkle update alert — above Settings
        static let updateAlert = NSWindow.Level(NSWindow.Level.floating.rawValue + 1)
    }

    /// Settings window dimensions
    enum Settings {
        static let windowWidth: CGFloat = 450
        static let windowHeight: CGFloat = 520
    }

    /// Usage Detail window dimensions
    enum UsageDetail {
        static let windowWidth: CGFloat = 520
        static let windowHeight: CGFloat = 420
    }

    /// Settings card dimensions
    enum SettingsCard {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 16
        static let borderWidth: CGFloat = 0.5
        static let borderOpacity: Double = 0.2
    }
}
