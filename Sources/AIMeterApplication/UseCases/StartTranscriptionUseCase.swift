import Foundation
import AIMeterDomain

/// Use case for starting real-time voice transcription
public final class StartTranscriptionUseCase: Sendable {
    private let transcriptionRepository: any TranscriptionRepository

    public init(transcriptionRepository: any TranscriptionRepository) {
        self.transcriptionRepository = transcriptionRepository
    }

    /// Starts streaming transcription
    /// - Parameters:
    ///   - language: Target transcription language
    ///   - apiKey: Deepgram API key
    /// - Returns: Async stream of transcribed text updates
    public func execute(language: TranscriptionLanguage, apiKey: String) async throws -> AsyncStream<String> {
        guard !apiKey.isEmpty else {
            throw TranscriptionError.apiKeyMissing
        }
        return try await transcriptionRepository.startStreaming(language: language, apiKey: apiKey)
    }
}
