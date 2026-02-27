import Testing
@testable import AIMeterApplication
import AIMeterDomain

@Suite("CancelTranscriptionUseCase")
struct CancelTranscriptionUseCaseTests {

    // MARK: - Tests

    @Test("Execute calls repository.cancelStreaming()")
    func executeCallsCancelStreaming() async {
        // Arrange
        let mockRepo = MockTranscriptionRepository()
        let useCase = CancelTranscriptionUseCase(transcriptionRepository: mockRepo)

        // Act
        await useCase.execute()

        // Assert
        #expect(await mockRepo.cancelStreamingCallCount == 1)
    }

    @Test("Execute completes without throwing")
    func executeCompletesWithoutThrowing() async {
        // Arrange
        let mockRepo = MockTranscriptionRepository()
        let useCase = CancelTranscriptionUseCase(transcriptionRepository: mockRepo)

        // Act & Assert - should not throw
        await useCase.execute()

        // Verify it was called
        #expect(await mockRepo.cancelStreamingCallCount == 1)
    }

    @Test("CallCount increments on each execute call")
    func callCountIncrements() async {
        // Arrange
        let mockRepo = MockTranscriptionRepository()
        let useCase = CancelTranscriptionUseCase(transcriptionRepository: mockRepo)

        // Act
        await useCase.execute()
        await useCase.execute()
        await useCase.execute()

        // Assert
        #expect(await mockRepo.cancelStreamingCallCount == 3)
    }
}

// MARK: - Mock Implementation

private actor MockTranscriptionRepository: TranscriptionRepository {
    var cancelStreamingCallCount = 0

    func startStreaming(language: TranscriptionLanguage, apiKey: String) async throws -> AsyncStream<String> {
        AsyncStream { $0.finish() }
    }

    func stopStreaming() async throws -> TranscriptionEntity {
        .empty()
    }

    func cancelStreaming() async {
        cancelStreamingCallCount += 1
    }
}
