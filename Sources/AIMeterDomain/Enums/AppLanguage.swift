import Foundation

/// Supported app languages for localization
public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case system = "system"
    case english = "en"
    case ukrainian = "uk"
    case polish = "pl"
    case german = "de"
    case spanish = "es"
    case french = "fr"

    /// Locale for environment, nil means use system
    public var locale: Locale? {
        switch self {
        case .system: return nil
        case .english: return Locale(identifier: "en")
        case .ukrainian: return Locale(identifier: "uk")
        case .polish: return Locale(identifier: "pl")
        case .german: return Locale(identifier: "de")
        case .spanish: return Locale(identifier: "es")
        case .french: return Locale(identifier: "fr")
        }
    }
}
