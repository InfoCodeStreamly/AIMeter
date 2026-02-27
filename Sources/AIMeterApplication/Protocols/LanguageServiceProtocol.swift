import AIMeterDomain
import Foundation
import Observation

/// Protocol for managing app language selection
@MainActor
public protocol LanguageServiceProtocol: AnyObject, Observable {
    var selectedLanguage: AppLanguage { get set }
    var currentLocale: Locale { get }
    var systemLanguageName: String { get }
    var availableLanguages: [AppLanguage] { get }
}
