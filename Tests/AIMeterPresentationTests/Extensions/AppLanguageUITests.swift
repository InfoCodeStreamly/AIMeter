import Testing
import Foundation
@testable import AIMeterPresentation
import AIMeterDomain

/// Tests for AppLanguage UI extensions
///
/// This module contains unit tests for AppLanguage icon mappings
/// following Clean Architecture principles.
@Suite("AppLanguage UI Extensions")
struct AppLanguageUITests {

    // MARK: - Icon Tests

    @Test("System language returns gear icon")
    func systemLanguageIcon() {
        #expect(AppLanguage.system.icon == "gear")
    }

    @Test("English language returns Americas globe icon")
    func englishLanguageIcon() {
        #expect(AppLanguage.english.icon == "globe.americas")
    }

    @Test("Ukrainian language returns Europe/Africa globe icon")
    func ukrainianLanguageIcon() {
        #expect(AppLanguage.ukrainian.icon == "globe.europe.africa")
    }

    @Test("Polish language returns Europe/Africa globe icon")
    func polishLanguageIcon() {
        #expect(AppLanguage.polish.icon == "globe.europe.africa")
    }

    @Test("German language returns Europe/Africa globe icon")
    func germanLanguageIcon() {
        #expect(AppLanguage.german.icon == "globe.europe.africa")
    }

    @Test("Spanish language returns Europe/Africa globe icon")
    func spanishLanguageIcon() {
        #expect(AppLanguage.spanish.icon == "globe.europe.africa")
    }

    @Test("French language returns Europe/Africa globe icon")
    func frenchLanguageIcon() {
        #expect(AppLanguage.french.icon == "globe.europe.africa")
    }

    @Test("All language cases have non-empty icons")
    func allLanguagesHaveNonEmptyIcons() {
        for language in AppLanguage.allCases {
            #expect(!language.icon.isEmpty)
        }
    }

    @Test("All icons are valid SF Symbol names")
    func allIconsAreValidSFSymbols() {
        for language in AppLanguage.allCases {
            let icon = language.icon
            // SF Symbol names should not contain spaces
            #expect(!icon.contains(" "))
            // Should contain letters
            #expect(!icon.isEmpty)
        }
    }

    @Test("European languages share the same globe icon")
    func europeanLanguagesShareIcon() {
        let europeanLanguages: [AppLanguage] = [
            .ukrainian, .polish, .german, .spanish, .french
        ]

        let icons = Set(europeanLanguages.map { $0.icon })
        #expect(icons.count == 1)
        #expect(icons.first == "globe.europe.africa")
    }

    @Test("System language has unique icon different from language icons")
    func systemLanguageHasUniqueIcon() {
        let systemIcon = AppLanguage.system.icon
        let languageIcons = AppLanguage.allCases
            .filter { $0 != .system }
            .map { $0.icon }

        #expect(!languageIcons.contains(systemIcon))
    }

    @Test("English language has unique globe icon")
    func englishLanguageHasUniqueGlobeIcon() {
        let englishIcon = AppLanguage.english.icon
        let otherLanguageIcons = AppLanguage.allCases
            .filter { $0 != .english && $0 != .system }
            .map { $0.icon }

        #expect(!otherLanguageIcons.contains(englishIcon))
    }

    @Test("Icons contain only lowercase letters, dots, and periods")
    func iconsContainValidCharacters() {
        for language in AppLanguage.allCases {
            let icon = language.icon
            let validCharacters = CharacterSet.lowercaseLetters.union(.init(charactersIn: "."))
            let iconCharacters = CharacterSet(charactersIn: icon)

            #expect(validCharacters.isSuperset(of: iconCharacters))
        }
    }
}
