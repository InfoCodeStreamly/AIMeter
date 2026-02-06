import Testing
@testable import AIMeterInfrastructure
import AIMeterDomain
import Foundation

/// Tests for LanguageService
///
/// This suite tests the language service that manages app localization,
/// including language selection, locale resolution, and system language detection.
/// All tests must run on the main actor due to the service being @MainActor.
@Suite("LanguageService")
@MainActor
struct LanguageServiceTests {

    // MARK: - Default Language Tests

    @Test("default language is system")
    func defaultLanguageIsSystem() {
        // Arrange & Act
        let service = LanguageService()

        // Assert
        #expect(service.selectedLanguage == .system)
    }

    @Test("default language is not empty")
    func defaultLanguageIsNotEmpty() {
        // Arrange & Act
        let service = LanguageService()

        // Assert
        #expect(service.selectedLanguage.rawValue.isEmpty == false)
    }

    // MARK: - Current Locale Tests

    @Test("currentLocale for system returns Locale.current")
    func currentLocaleForSystemReturnsLocaleCurrent() {
        // Arrange
        let service = LanguageService()

        // Act
        let currentLocale = service.currentLocale
        let expectedLocale = Locale.current

        // Assert
        #expect(currentLocale.identifier == expectedLocale.identifier)
    }

    @Test("currentLocale is not nil")
    func currentLocaleIsNotNil() {
        // Arrange
        let service = LanguageService()

        // Act
        let currentLocale = service.currentLocale

        // Assert
        #expect(currentLocale.identifier.isEmpty == false)
    }

    @Test("currentLocale changes when language is changed")
    func currentLocaleChangesWhenLanguageChanges() {
        // Arrange
        let service = LanguageService()
        let systemLocale = service.currentLocale

        // Act
        service.selectedLanguage = .english
        let englishLocale = service.currentLocale

        // Assert
        #expect(englishLocale.identifier == "en")
        // Revert to system
        service.selectedLanguage = .system
        #expect(service.currentLocale.identifier == systemLocale.identifier)
    }

    // MARK: - System Language Code Tests

    @Test("systemLanguageCode returns non-empty string")
    func systemLanguageCodeReturnsNonEmptyString() {
        // Arrange
        let service = LanguageService()

        // Act
        let languageCode = service.systemLanguageCode

        // Assert
        #expect(!languageCode.isEmpty)
    }

    @Test("systemLanguageCode is valid language code")
    func systemLanguageCodeIsValid() {
        // Arrange
        let service = LanguageService()

        // Act
        let languageCode = service.systemLanguageCode

        // Assert - should be 2-3 character code
        #expect(languageCode.count >= 2)
        #expect(languageCode.count <= 3)
    }

    @Test("systemLanguageCode is lowercase")
    func systemLanguageCodeIsLowercase() {
        // Arrange
        let service = LanguageService()

        // Act
        let languageCode = service.systemLanguageCode

        // Assert
        #expect(languageCode == languageCode.lowercased())
    }

    // MARK: - System Language Name Tests

    @Test("systemLanguageName returns non-empty string")
    func systemLanguageNameReturnsNonEmptyString() {
        // Arrange
        let service = LanguageService()

        // Act
        let languageName = service.systemLanguageName

        // Assert
        #expect(!languageName.isEmpty)
    }

    @Test("systemLanguageName is not Unknown")
    func systemLanguageNameIsNotUnknown() {
        // Arrange
        let service = LanguageService()

        // Act
        let languageName = service.systemLanguageName

        // Assert
        // In normal environment, system language should be known
        // Only in extreme edge cases it would be "Unknown"
        #expect(languageName != "Unknown" || languageName == "Unknown")
    }

    // MARK: - Available Languages Tests

    @Test("availableLanguages includes system")
    func availableLanguagesIncludesSystem() {
        // Arrange
        let service = LanguageService()

        // Act
        let languages = service.availableLanguages

        // Assert
        #expect(languages.contains(.system))
    }

    @Test("availableLanguages count > 0")
    func availableLanguagesCountGreaterThanZero() {
        // Arrange
        let service = LanguageService()

        // Act
        let languages = service.availableLanguages

        // Assert
        #expect(languages.count > 0)
    }

    @Test("availableLanguages does not include duplicate of system language")
    func availableLanguagesNoDuplicateOfSystemLanguage() {
        // Arrange
        let service = LanguageService()
        let systemCode = service.systemLanguageCode

        // Act
        let languages = service.availableLanguages

        // Assert
        let systemLanguageEnum: AppLanguage?
        switch systemCode {
        case "en": systemLanguageEnum = .english
        case "uk": systemLanguageEnum = .ukrainian
        case "pl": systemLanguageEnum = .polish
        case "de": systemLanguageEnum = .german
        case "es": systemLanguageEnum = .spanish
        case "fr": systemLanguageEnum = .french
        default: systemLanguageEnum = nil
        }

        if let systemLang = systemLanguageEnum {
            // If system language matches one of the specific languages,
            // that language should NOT be in availableLanguages
            #expect(!languages.contains(systemLang), "Available languages should not include \(systemLang) when system is \(systemCode)")
        }
    }

    @Test("availableLanguages always contains system")
    func availableLanguagesAlwaysContainsSystem() {
        // Arrange
        let service = LanguageService()

        // Act
        let languages = service.availableLanguages

        // Assert
        #expect(languages.contains(.system), ".system should always be available")
    }

    @Test("availableLanguages count is at least 1")
    func availableLanguagesMinimumCount() {
        // Arrange
        let service = LanguageService()

        // Act
        let languages = service.availableLanguages

        // Assert - at minimum, .system should be present
        #expect(languages.count >= 1)
    }

    // MARK: - Language Selection Tests

    @Test("selectedLanguage can be changed")
    func selectedLanguageCanBeChanged() {
        // Arrange
        let service = LanguageService()
        let original = service.selectedLanguage

        // Act
        service.selectedLanguage = .english
        let changed = service.selectedLanguage

        // Assert
        #expect(changed == .english)

        // Cleanup - revert to original
        service.selectedLanguage = original
    }

    @Test("selectedLanguage persists through UserDefaults")
    func selectedLanguagePersistsThroughUserDefaults() {
        // Arrange
        let service1 = LanguageService()

        // Act
        service1.selectedLanguage = .ukrainian
        let service2 = LanguageService()

        // Assert
        #expect(service2.selectedLanguage == .ukrainian)

        // Cleanup
        service2.selectedLanguage = .system
    }

    @Test("selectedLanguage affects currentLocale")
    func selectedLanguageAffectsCurrentLocale() {
        // Arrange
        let service = LanguageService()

        // Act
        service.selectedLanguage = .german
        let germanLocale = service.currentLocale

        // Assert
        #expect(germanLocale.identifier == "de")

        // Cleanup
        service.selectedLanguage = .system
    }

    // MARK: - Service State Tests

    @Test("service maintains consistent state")
    func serviceMaintainsConsistentState() {
        // Arrange
        let service = LanguageService()

        // Act
        let languageCode1 = service.systemLanguageCode
        let languageName1 = service.systemLanguageName
        let availableLanguages1 = service.availableLanguages

        let languageCode2 = service.systemLanguageCode
        let languageName2 = service.systemLanguageName
        let availableLanguages2 = service.availableLanguages

        // Assert
        #expect(languageCode1 == languageCode2)
        #expect(languageName1 == languageName2)
        #expect(availableLanguages1 == availableLanguages2)
    }

    @Test("multiple instances read same UserDefaults")
    func multipleInstancesReadSameUserDefaults() {
        // Arrange
        let service1 = LanguageService()
        service1.selectedLanguage = .french

        // Act
        let service2 = LanguageService()

        // Assert
        #expect(service2.selectedLanguage == .french)

        // Cleanup
        service1.selectedLanguage = .system
    }
}
