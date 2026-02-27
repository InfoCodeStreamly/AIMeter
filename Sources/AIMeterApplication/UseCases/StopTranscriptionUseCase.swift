import Foundation
import AIMeterDomain

/// Use case for stopping transcription and getting the final result
public final class StopTranscriptionUseCase: Sendable {
    private let transcriptionRepository: any TranscriptionRepository

    public init(transcriptionRepository: any TranscriptionRepository) {
        self.transcriptionRepository = transcriptionRepository
    }

    /// Stops streaming and returns the finalized transcription
    /// - Returns: Final transcription entity with accumulated text
    public func execute() async throws -> TranscriptionEntity {
        try await transcriptionRepository.stopStreaming()
    }
}
