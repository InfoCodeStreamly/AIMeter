import Testing
@testable import AIMeterApplication
import AIMeterDomain

@Suite("StartTranscriptionUseCase")
struct StartTranscriptionUseCaseTests {

    // MARK: - Success Path Tests

    @Test("Execute calls repository with correct language and apiKey")
    func executeCallsRepositoryWithCorrectParams() async throws {
        // Arrange
        let mockRepo = MockTranscriptionRepository()
        let useCase = StartTranscriptionUseCase(transcriptionRepository: mockRepo)

        // Act
        _ = try await useCase.execute(language: .english, apiKey: "test-api-key")

        // Assert
        #expect(await mockRepo.startStreamingCallCount == 1)
        #expect(await mockRepo.lastLanguage == .english)
        #expect(await mockRepo.lastApiKey == "test-api-key")
    }

    @Test("Execute throws apiKeyMissing when apiKey is empty")
    func executeThrowsWhenApiKeyEmpty() async {
        // Arrange
        let mockRepo = MockTranscriptionRepository()
        let useCase = StartTranscriptionUseCase(transcriptionRepository: mockRepo)

        // Act & Assert
        await #expect(throws: TranscriptionError.apiKeyMissing) {
            try await useCase.execute(language: .english, apiKey: "")
        }

        // Verify repository was NOT called
        #expect(await mockRepo.startStreamingCallCount == 0)
    }

    @Test("Execute returns stream from repository")
    func executeReturnsStream() async throws {
        // Arrange
        let mockRepo = MockTranscriptionRepository()
        let useCase = StartTranscriptionUseCase(transcriptionRepository: mockRepo)

        // Act
        let stream = try await useCase.execute(language: .autoDetect, apiKey: "valid-key")

        // Assert - stream should be consumable
        var texts: [String] = []
        for await text in stream {
            texts.append(text)
        }
        // Default mock returns empty stream, so should have no elements
        #expect(texts.isEmpty)
    }

    @Test("Execute propagates repository errors")
    func executePropagatesErrors() async {
        // Arrange
        let mockRepo = MockTranscriptionRepository()
        await mockRepo.configure(startStreamingError: TranscriptionError.connectionFailed("timeout"))
        let useCase = StartTranscriptionUseCase(transcriptionRepository: mockRepo)

        // Act & Assert
        await #expect(throws: TranscriptionError.connectionFailed("timeout")) {
            try await useCase.execute(language: .english, apiKey: "valid-key")
        }

        #expect(await mockRepo.startStreamingCallCount == 1)
    }

    @Test("Execute passes language correctly for .ukrainian")
    func executePassesUkrainianLanguage() async throws {
        // Arrange
        let mockRepo = MockTranscriptionRepository()
        let useCase = StartTranscriptionUseCase(transcriptionRepository: mockRepo)

        // Act
        _ = try await useCase.execute(language: .ukrainian, apiKey: "my-key")

        // Assert
        #expect(await mockRepo.lastLanguage == .ukrainian)
        #expect(await mockRepo.lastApiKey == "my-key")
    }
}

// MARK: - Mock Implementation

private actor MockTranscriptionRepository: TranscriptionRepository {
    var startStreamingCallCount = 0
    var lastLanguage: TranscriptionLanguage?
    var lastApiKey: String?
    var startStreamingError: (any Error)?

    func configure(startStreamingError: (any Error)? = nil) {
        self.startStreamingError = startStreamingError
    }

    func startStreaming(language: TranscriptionLanguage, apiKey: String) async throws -> AsyncStream<String> {
        startStreamingCallCount += 1
        lastLanguage = language
        lastApiKey = apiKey
        if let error = startStreamingError { throw error }
        return AsyncStream { $0.finish() }
    }

    func stopStreaming() async throws -> TranscriptionEntity {
        .empty()
    }

    func cancelStreaming() async {}
}
