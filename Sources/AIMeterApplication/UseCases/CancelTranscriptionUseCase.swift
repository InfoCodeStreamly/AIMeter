import Foundation
import AIMeterDomain

/// Use case for cancelling an in-progress transcription
public final class CancelTranscriptionUseCase: Sendable {
    private let transcriptionRepository: any TranscriptionRepository

    public init(transcriptionRepository: any TranscriptionRepository) {
        self.transcriptionRepository = transcriptionRepository
    }

    /// Cancels the current transcription without returning a result
    public func execute() async {
        await transcriptionRepository.cancelStreaming()
    }
}
