import SwiftUI
import AIMeterDomain

/// UI-specific extensions for AppTheme
extension AppTheme {
    /// Display name for theme selection UI
    public var displayName: LocalizedStringKey {
        switch self {
        case .system: return "System Default"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// SF Symbol icon for theme selection UI
    public var icon: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }

    /// Resolved color scheme for SwiftUI `.preferredColorScheme()`
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
