import Foundation
import Testing
@testable import AIMeterDomain

@Suite("TranscriptionEntity")
struct TranscriptionEntityTests {

    // MARK: - Init Tests

    @Test("init sets all properties correctly")
    func initSetsProperties() {
        let id = UUID()
        let entity = TranscriptionEntity(
            id: id,
            text: "Hello world",
            language: .english,
            duration: 5.0
        )

        #expect(entity.id == id)
        #expect(entity.text == "Hello world")
        #expect(entity.language == .english)
        #expect(entity.duration == 5.0)
    }

    // MARK: - isEmpty Tests

    @Test("isEmpty returns true for empty text")
    func isEmptyForEmptyText() {
        let entity = TranscriptionEntity(text: "", language: .english, duration: 1.0)
        #expect(entity.isEmpty)
    }

    @Test("isEmpty returns false for non-empty text")
    func isEmptyForNonEmptyText() {
        let entity = TranscriptionEntity(text: "Hello", language: .english, duration: 1.0)
        #expect(!entity.isEmpty)
    }

    @Test("isEmpty returns true for whitespace-only text")
    func isEmptyForWhitespaceOnly() {
        let entity = TranscriptionEntity(text: "   \n\t  ", language: .english, duration: 1.0)
        #expect(entity.isEmpty)
    }

    // MARK: - wordCount Tests

    @Test("wordCount returns 0 for empty text")
    func wordCountEmpty() {
        let entity = TranscriptionEntity(text: "", language: .english, duration: 1.0)
        #expect(entity.wordCount == 0)
    }

    @Test("wordCount returns correct count for multiple words")
    func wordCountMultipleWords() {
        let entity = TranscriptionEntity(text: "hello world test", language: .english, duration: 1.0)
        #expect(entity.wordCount == 3)
    }

    // MARK: - Factory Method Tests

    @Test("empty() factory returns entity with empty text")
    func emptyFactory() {
        let entity = TranscriptionEntity.empty()
        #expect(entity.text == "")
        #expect(entity.language == .autoDetect)
        #expect(entity.duration == 0)
        #expect(entity.isEmpty)
    }

    // MARK: - Equatable Tests

    @Test("entities with same id and data are equal")
    func equatableSame() {
        let id = UUID()
        let entity1 = TranscriptionEntity(id: id, text: "Hello", language: .english, duration: 2.0)
        let entity2 = TranscriptionEntity(id: id, text: "Hello", language: .english, duration: 2.0)
        #expect(entity1 == entity2)
    }

    @Test("different text means not equal")
    func equatableDifferentText() {
        let id = UUID()
        let entity1 = TranscriptionEntity(id: id, text: "Hello", language: .english, duration: 2.0)
        let entity2 = TranscriptionEntity(id: id, text: "World", language: .english, duration: 2.0)
        #expect(entity1 != entity2)
    }
}
