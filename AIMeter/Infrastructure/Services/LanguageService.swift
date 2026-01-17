import SwiftUI

/// SSOT (Single Source of Truth) for app language selection
/// Persists user's language preference and provides current locale
@MainActor
@Observable
final class LanguageService {
    private let userDefaultsKey = "selectedLanguage"

    /// Currently selected language
    var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: userDefaultsKey)
        }
    }

    /// Resolved locale for SwiftUI environment
    /// Returns system locale if .system is selected
    var currentLocale: Locale {
        selectedLanguage.locale ?? Locale.current
    }

    /// Current system language name for display
    var systemLanguageName: String {
        Locale.current.localizedString(forIdentifier: Locale.current.identifier) ?? "Unknown"
    }

    /// System language code (e.g., "en", "uk")
    var systemLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// Languages to show in picker (excludes language matching system when System Default is available)
    var availableLanguages: [AppLanguage] {
        AppLanguage.allCases.filter { language in
            switch language {
            case .system:
                return true
            case .english:
                return systemLanguageCode != "en"
            case .ukrainian:
                return systemLanguageCode != "uk"
            }
        }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = AppLanguage(rawValue: saved) {
            self.selectedLanguage = language
        } else {
            self.selectedLanguage = .system
        }
    }
}
