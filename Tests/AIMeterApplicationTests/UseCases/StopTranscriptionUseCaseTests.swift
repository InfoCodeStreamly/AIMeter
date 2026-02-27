import Testing
@testable import AIMeterApplication
import AIMeterDomain

@Suite("StopTranscriptionUseCase")
struct StopTranscriptionUseCaseTests {

    // MARK: - Success Path Tests

    @Test("Execute calls repository.stopStreaming()")
    func executeCallsStopStreaming() async throws {
        // Arrange
        let mockRepo = MockTranscriptionRepository()
        let expectedEntity = TranscriptionEntity(
            text: "Hello world",
            language: .english,
            duration: 3.5
        )
        await mockRepo.configure(stopStreamingResult: expectedEntity)
        let useCase = StopTranscriptionUseCase(transcriptionRepository: mockRepo)

        // Act
        _ = try await useCase.execute()

        // Assert
        #expect(await mockRepo.stopStreamingCallCount == 1)
    }

    @Test("Execute returns TranscriptionEntity from repository")
    func executeReturnsEntity() async throws {
        // Arrange
        let mockRepo = MockTranscriptionRepository()
        let expectedEntity = TranscriptionEntity(
            text: "Transcribed speech",
            language: .ukrainian,
            duration: 10.2
        )
        await mockRepo.configure(stopStreamingResult: expectedEntity)
        let useCase = StopTranscriptionUseCase(transcriptionRepository: mockRepo)

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.text == "Transcribed speech")
        #expect(result.language == .ukrainian)
        #expect(result.duration == 10.2)
    }

    @Test("Execute propagates repository errors")
    func executePropagatesErrors() async {
        // Arrange
        let mockRepo = MockTranscriptionRepository()
        await mockRepo.configure(stopStreamingError: TranscriptionError.transcriptionFailed("unexpected"))
        let useCase = StopTranscriptionUseCase(transcriptionRepository: mockRepo)

        // Act & Assert
        await #expect(throws: TranscriptionError.transcriptionFailed("unexpected")) {
            try await useCase.execute()
        }
    }

    @Test("CallCount increments on each execute call")
    func callCountIncrements() async throws {
        // Arrange
        let mockRepo = MockTranscriptionRepository()
        let entity = TranscriptionEntity(text: "test", language: .english, duration: 1.0)
        await mockRepo.configure(stopStreamingResult: entity)
        let useCase = StopTranscriptionUseCase(transcriptionRepository: mockRepo)

        // Act
        _ = try await useCase.execute()
        _ = try await useCase.execute()
        _ = try await useCase.execute()

        // Assert
        #expect(await mockRepo.stopStreamingCallCount == 3)
    }
}

// MARK: - Mock Implementation

private actor MockTranscriptionRepository: TranscriptionRepository {
    var stopStreamingCallCount = 0
    var stopStreamingResult: TranscriptionEntity?
    var stopStreamingError: (any Error)?

    func configure(
        stopStreamingResult: TranscriptionEntity? = nil,
        stopStreamingError: (any Error)? = nil
    ) {
        self.stopStreamingResult = stopStreamingResult
        self.stopStreamingError = stopStreamingError
    }

    func startStreaming(language: TranscriptionLanguage, apiKey: String) async throws -> AsyncStream<String> {
        AsyncStream { $0.finish() }
    }

    func stopStreaming() async throws -> TranscriptionEntity {
        stopStreamingCallCount += 1
        if let error = stopStreamingError { throw error }
        return stopStreamingResult ?? .empty()
    }

    func cancelStreaming() async {}
}
