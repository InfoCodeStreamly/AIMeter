import Foundation

/// Repository protocol for real-time speech-to-text streaming
public protocol TranscriptionRepository: Sendable {
    /// Starts streaming audio to Deepgram and returns an async stream of transcribed text
    func startStreaming(language: TranscriptionLanguage, apiKey: String) async throws -> AsyncStream<String>

    /// Stops streaming and returns the final transcription result
    func stopStreaming() async throws -> TranscriptionEntity

    /// Cancels streaming without returning a result
    func cancelStreaming() async
}
