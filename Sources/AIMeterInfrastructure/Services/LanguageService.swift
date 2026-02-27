import AIMeterApplication
import AIMeterDomain
import SwiftUI

/// SSOT (Single Source of Truth) for app language selection
/// Persists user's language preference and provides current locale
@MainActor
@Observable
public final class LanguageService: LanguageServiceProtocol {
    private let userDefaultsKey = "selectedLanguage"

    /// Currently selected language
    public var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: userDefaultsKey)
        }
    }

    /// Resolved locale for SwiftUI environment
    /// Returns system locale if .system is selected
    public var currentLocale: Locale {
        selectedLanguage.locale ?? Locale.current
    }

    /// Current system language name for display
    public var systemLanguageName: String {
        Locale.current.localizedString(forIdentifier: Locale.current.identifier) ?? "Unknown"
    }

    /// System language code (e.g., "en", "uk")
    public var systemLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// Languages to show in picker (excludes language matching system when System Default is available)
    public var availableLanguages: [AppLanguage] {
        AppLanguage.allCases.filter { language in
            switch language {
            case .system:
                return true
            case .english:
                return systemLanguageCode != "en"
            case .ukrainian:
                return systemLanguageCode != "uk"
            case .polish:
                return systemLanguageCode != "pl"
            case .german:
                return systemLanguageCode != "de"
            case .spanish:
                return systemLanguageCode != "es"
            case .french:
                return systemLanguageCode != "fr"
            }
        }
    }

    public init() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = AppLanguage(rawValue: saved) {
            self.selectedLanguage = language
        } else {
            self.selectedLanguage = .system
        }
    }
}
