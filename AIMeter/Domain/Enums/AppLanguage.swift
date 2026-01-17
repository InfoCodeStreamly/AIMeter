import Foundation

/// Supported app languages for localization
enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case system = "system"
    case english = "en"
    case ukrainian = "uk"

    /// Locale for SwiftUI environment, nil means use system
    var locale: Locale? {
        switch self {
        case .system: return nil
        case .english: return Locale(identifier: "en")
        case .ukrainian: return Locale(identifier: "uk")
        }
    }

    /// Native display name for each language (always in native language)
    var displayName: String {
        switch self {
        case .system: return String(localized: "System Default")
        case .english: return "English"
        case .ukrainian: return "Українська"
        }
    }

    /// Icon for language selection UI
    var icon: String {
        switch self {
        case .system: return "gear"
        case .english: return "globe.americas"
        case .ukrainian: return "globe.europe.africa"
        }
    }
}
