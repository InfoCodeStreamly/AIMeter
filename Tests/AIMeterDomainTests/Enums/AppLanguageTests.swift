import Testing
import Foundation
@testable import AIMeterDomain

@Suite("AppLanguage")
struct AppLanguageTests {

    // MARK: - Cases Tests

    @Test("all cases are present")
    func allCases() {
        let cases = AppLanguage.allCases
        #expect(cases.count == 7)
        #expect(cases.contains(.system))
        #expect(cases.contains(.english))
        #expect(cases.contains(.ukrainian))
        #expect(cases.contains(.polish))
        #expect(cases.contains(.german))
        #expect(cases.contains(.spanish))
        #expect(cases.contains(.french))
    }

    // MARK: - Raw Value Tests

    @Test("system raw value")
    func systemRawValue() {
        #expect(AppLanguage.system.rawValue == "system")
    }

    @Test("english raw value")
    func englishRawValue() {
        #expect(AppLanguage.english.rawValue == "en")
    }

    @Test("ukrainian raw value")
    func ukrainianRawValue() {
        #expect(AppLanguage.ukrainian.rawValue == "uk")
    }

    @Test("polish raw value")
    func polishRawValue() {
        #expect(AppLanguage.polish.rawValue == "pl")
    }

    @Test("german raw value")
    func germanRawValue() {
        #expect(AppLanguage.german.rawValue == "de")
    }

    @Test("spanish raw value")
    func spanishRawValue() {
        #expect(AppLanguage.spanish.rawValue == "es")
    }

    @Test("french raw value")
    func frenchRawValue() {
        #expect(AppLanguage.french.rawValue == "fr")
    }

    @Test("initialize from raw value")
    func initFromRawValue() {
        #expect(AppLanguage(rawValue: "system") == .system)
        #expect(AppLanguage(rawValue: "en") == .english)
        #expect(AppLanguage(rawValue: "uk") == .ukrainian)
        #expect(AppLanguage(rawValue: "pl") == .polish)
        #expect(AppLanguage(rawValue: "de") == .german)
        #expect(AppLanguage(rawValue: "es") == .spanish)
        #expect(AppLanguage(rawValue: "fr") == .french)
        #expect(AppLanguage(rawValue: "invalid") == nil)
    }

    // MARK: - Locale Tests

    @Test("system locale is nil")
    func systemLocale() {
        #expect(AppLanguage.system.locale == nil)
    }

    @Test("english locale")
    func englishLocale() {
        let locale = AppLanguage.english.locale
        #expect(locale != nil)
        #expect(locale?.identifier == "en")
    }

    @Test("ukrainian locale")
    func ukrainianLocale() {
        let locale = AppLanguage.ukrainian.locale
        #expect(locale != nil)
        #expect(locale?.identifier == "uk")
    }

    @Test("polish locale")
    func polishLocale() {
        let locale = AppLanguage.polish.locale
        #expect(locale != nil)
        #expect(locale?.identifier == "pl")
    }

    @Test("german locale")
    func germanLocale() {
        let locale = AppLanguage.german.locale
        #expect(locale != nil)
        #expect(locale?.identifier == "de")
    }

    @Test("spanish locale")
    func spanishLocale() {
        let locale = AppLanguage.spanish.locale
        #expect(locale != nil)
        #expect(locale?.identifier == "es")
    }

    @Test("french locale")
    func frenchLocale() {
        let locale = AppLanguage.french.locale
        #expect(locale != nil)
        #expect(locale?.identifier == "fr")
    }

    @Test("only system has nil locale")
    func onlySystemNilLocale() {
        let nonSystemLanguages = AppLanguage.allCases.filter { $0 != .system }
        for language in nonSystemLanguages {
            #expect(language.locale != nil)
        }
    }

    // MARK: - Codable Tests

    @Test("encode system")
    func encodeSystem() throws {
        let language = AppLanguage.system
        let encoded = try JSONEncoder().encode(language)
        let json = String(data: encoded, encoding: .utf8)!
        #expect(json.contains("system"))
    }

    @Test("encode english")
    func encodeEnglish() throws {
        let language = AppLanguage.english
        let encoded = try JSONEncoder().encode(language)
        let json = String(data: encoded, encoding: .utf8)!
        #expect(json.contains("en"))
    }

    @Test("decode system")
    func decodeSystem() throws {
        let json = "\"system\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppLanguage.self, from: json)
        #expect(decoded == .system)
    }

    @Test("decode english")
    func decodeEnglish() throws {
        let json = "\"en\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppLanguage.self, from: json)
        #expect(decoded == .english)
    }

    @Test("decode ukrainian")
    func decodeUkrainian() throws {
        let json = "\"uk\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppLanguage.self, from: json)
        #expect(decoded == .ukrainian)
    }

    @Test("decode invalid language throws")
    func decodeInvalid() {
        let json = "\"invalid\"".data(using: .utf8)!
        #expect(throws: Error.self) {
            _ = try JSONDecoder().decode(AppLanguage.self, from: json)
        }
    }

    @Test("roundtrip encoding and decoding")
    func codableRoundtrip() throws {
        for language in AppLanguage.allCases {
            let encoded = try JSONEncoder().encode(language)
            let decoded = try JSONDecoder().decode(AppLanguage.self, from: encoded)
            #expect(decoded == language)
        }
    }

    // MARK: - Equality Tests

    @Test("equality for same cases")
    func equalitySame() {
        #expect(AppLanguage.system == AppLanguage.system)
        #expect(AppLanguage.english == AppLanguage.english)
        #expect(AppLanguage.ukrainian == AppLanguage.ukrainian)
    }

    @Test("inequality for different cases")
    func inequalityDifferent() {
        #expect(AppLanguage.system != AppLanguage.english)
        #expect(AppLanguage.english != AppLanguage.ukrainian)
        #expect(AppLanguage.ukrainian != AppLanguage.polish)
    }

    // MARK: - Collection Tests

    @Test("filter languages with locale")
    func filterWithLocale() {
        let languagesWithLocale = AppLanguage.allCases.filter { $0.locale != nil }
        #expect(languagesWithLocale.count == 6)
        #expect(!languagesWithLocale.contains(.system))
    }

    @Test("filter system language")
    func filterSystem() {
        let systemLanguages = AppLanguage.allCases.filter { $0 == .system }
        #expect(systemLanguages.count == 1)
        #expect(systemLanguages.first == .system)
    }

    // MARK: - Locale Identifier Verification

    @Test("locale identifiers match raw values for non-system")
    func localeIdentifiersMatchRawValues() {
        let nonSystemLanguages = AppLanguage.allCases.filter { $0 != .system }
        for language in nonSystemLanguages {
            if let locale = language.locale {
                #expect(locale.identifier == language.rawValue)
            }
        }
    }
}
