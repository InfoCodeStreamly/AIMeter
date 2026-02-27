import Foundation
import Testing
@testable import AIMeterDomain

@Suite("TranscriptionLanguage")
struct TranscriptionLanguageTests {

    // MARK: - CaseIterable Tests

    @Test("allCases count is 8")
    func allCasesCount() {
        #expect(TranscriptionLanguage.allCases.count == 8)
    }

    // MARK: - apiCode Tests

    @Test("apiCode returns nil for autoDetect")
    func apiCodeAutoDetect() {
        #expect(TranscriptionLanguage.autoDetect.apiCode == nil)
    }

    @Test("apiCode returns en for english")
    func apiCodeEnglish() {
        #expect(TranscriptionLanguage.english.apiCode == "en")
    }

    @Test("apiCode returns uk for ukrainian")
    func apiCodeUkrainian() {
        #expect(TranscriptionLanguage.ukrainian.apiCode == "uk")
    }

    @Test("apiCode returns rawValue for all non-auto languages")
    func apiCodeReturnsRawValueForNonAuto() {
        let nonAutoLanguages = TranscriptionLanguage.allCases.filter { $0 != .autoDetect }
        for language in nonAutoLanguages {
            #expect(language.apiCode == language.rawValue)
        }
    }

    // MARK: - displayName Tests

    @Test("displayName returns Auto-detect for autoDetect")
    func displayNameAutoDetect() {
        #expect(TranscriptionLanguage.autoDetect.displayName == "Auto-detect")
    }

    @Test("displayName returns English for english")
    func displayNameEnglish() {
        #expect(TranscriptionLanguage.english.displayName == "English")
    }

    @Test("displayName returns Ukrainian for ukrainian")
    func displayNameUkrainian() {
        #expect(TranscriptionLanguage.ukrainian.displayName == "Ukrainian")
    }

    // MARK: - RawValue Roundtrip Tests

    @Test("rawValue roundtrip works for all cases")
    func rawValueRoundtrip() {
        for language in TranscriptionLanguage.allCases {
            let restored = TranscriptionLanguage(rawValue: language.rawValue)
            #expect(restored == language)
        }
    }

    // MARK: - Codable Tests

    @Test("Codable encode/decode roundtrip")
    func codableRoundtrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for language in TranscriptionLanguage.allCases {
            let data = try encoder.encode(language)
            let decoded = try decoder.decode(TranscriptionLanguage.self, from: data)
            #expect(decoded == language)
        }
    }

    // MARK: - Equatable Tests

    @Test("same cases are equal")
    func equatableSameCases() {
        #expect(TranscriptionLanguage.english == TranscriptionLanguage.english)
        #expect(TranscriptionLanguage.autoDetect == TranscriptionLanguage.autoDetect)
        #expect(TranscriptionLanguage.ukrainian == TranscriptionLanguage.ukrainian)
    }
}
