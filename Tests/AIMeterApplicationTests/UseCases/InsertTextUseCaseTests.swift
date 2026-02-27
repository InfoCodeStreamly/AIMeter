import Testing
@testable import AIMeterApplication
import AIMeterDomain

@Suite("InsertTextUseCase")
struct InsertTextUseCaseTests {

    // MARK: - Success Path Tests

    @Test("Execute calls insertText with correct text")
    @MainActor
    func executeCallsInsertTextWithCorrectText() async throws {
        // Arrange
        let mockService = MockTextInsertionService()
        let useCase = InsertTextUseCase(textInsertionService: mockService)

        // Act
        try await useCase.execute(text: "Hello, world!")

        // Assert
        #expect(mockService.insertTextCallCount == 1)
        #expect(mockService.lastInsertedText == "Hello, world!")
    }

    @Test("Execute does nothing for empty text")
    @MainActor
    func executeDoesNothingForEmptyText() async throws {
        // Arrange
        let mockService = MockTextInsertionService()
        let useCase = InsertTextUseCase(textInsertionService: mockService)

        // Act
        try await useCase.execute(text: "")

        // Assert
        #expect(mockService.insertTextCallCount == 0)
        #expect(mockService.lastInsertedText == nil)
    }

    @Test("Execute propagates errors from service")
    @MainActor
    func executePropagatesErrors() async {
        // Arrange
        let mockService = MockTextInsertionService()
        mockService.insertTextError = TranscriptionError.accessibilityDenied
        let useCase = InsertTextUseCase(textInsertionService: mockService)

        // Act & Assert
        await #expect(throws: TranscriptionError.accessibilityDenied) {
            try await useCase.execute(text: "some text")
        }
    }

    @Test("LastInsertedText captures the text")
    @MainActor
    func lastInsertedTextCapturesText() async throws {
        // Arrange
        let mockService = MockTextInsertionService()
        let useCase = InsertTextUseCase(textInsertionService: mockService)

        // Act
        try await useCase.execute(text: "first")
        try await useCase.execute(text: "second")

        // Assert
        #expect(mockService.insertTextCallCount == 2)
        #expect(mockService.lastInsertedText == "second")
    }
}

// MARK: - Mock Implementation

@MainActor
private final class MockTextInsertionService: TextInsertionServiceProtocol, @unchecked Sendable {
    var insertTextCallCount = 0
    var lastInsertedText: String?
    var insertTextError: (any Error)?
    var accessibilityPermission = true

    func hasAccessibilityPermission() -> Bool {
        accessibilityPermission
    }

    func insertText(_ text: String) throws {
        insertTextCallCount += 1
        lastInsertedText = text
        if let error = insertTextError { throw error }
    }
}
