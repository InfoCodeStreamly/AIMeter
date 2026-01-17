import SwiftUI
import AIMeterDomain
import AIMeterApplication
import AIMeterInfrastructure

/// UI-specific extensions for AppLanguage
extension AppLanguage {
    /// Native display name for each language (always in native language)
    var displayName: LocalizedStringKey {
        switch self {
        case .system: return "System Default"
        case .english: return "English"
        case .ukrainian: return "Українська"
        case .polish: return "Polski"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .french: return "Français"
        }
    }

    /// Icon for language selection UI
    var icon: String {
        switch self {
        case .system: return "gear"
        case .english: return "globe.americas"
        case .ukrainian: return "globe.europe.africa"
        case .polish: return "globe.europe.africa"
        case .german: return "globe.europe.africa"
        case .spanish: return "globe.europe.africa"
        case .french: return "globe.europe.africa"
        }
    }
}
