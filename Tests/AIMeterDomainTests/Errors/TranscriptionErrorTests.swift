import Testing
@testable import AIMeterDomain

@Suite("TranscriptionError")
struct TranscriptionErrorTests {

    // MARK: - errorDescription Tests

    @Test("errorDescription for microphoneAccessDenied")
    func errorDescriptionMicrophoneAccessDenied() {
        let error = TranscriptionError.microphoneAccessDenied
        #expect(error.errorDescription == "Microphone access denied")
    }

    @Test("errorDescription for accessibilityDenied")
    func errorDescriptionAccessibilityDenied() {
        let error = TranscriptionError.accessibilityDenied
        #expect(error.errorDescription == "Accessibility permission required")
    }

    @Test("errorDescription for apiKeyMissing")
    func errorDescriptionApiKeyMissing() {
        let error = TranscriptionError.apiKeyMissing
        #expect(error.errorDescription == "Deepgram API key not configured")
    }

    @Test("errorDescription for connectionFailed includes message")
    func errorDescriptionConnectionFailed() {
        let error = TranscriptionError.connectionFailed("timeout")
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("timeout"))
    }

    @Test("errorDescription for authenticationFailed")
    func errorDescriptionAuthenticationFailed() {
        let error = TranscriptionError.authenticationFailed
        #expect(error.errorDescription == "Invalid API key")
    }

    @Test("errorDescription for transcriptionFailed includes reason")
    func errorDescriptionTranscriptionFailed() {
        let error = TranscriptionError.transcriptionFailed("reason")
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription!.contains("reason"))
    }

    @Test("errorDescription for cancelled")
    func errorDescriptionCancelled() {
        let error = TranscriptionError.cancelled
        #expect(error.errorDescription == "Cancelled")
    }

    // MARK: - recoverySuggestion Tests

    @Test("recoverySuggestion for microphoneAccessDenied mentions System Settings")
    func recoverySuggestionMicrophoneAccessDenied() {
        let error = TranscriptionError.microphoneAccessDenied
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion!.contains("System Settings"))
    }

    @Test("recoverySuggestion for apiKeyMissing mentions Settings")
    func recoverySuggestionApiKeyMissing() {
        let error = TranscriptionError.apiKeyMissing
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion!.contains("Settings"))
    }

    @Test("recoverySuggestion for authenticationFailed mentions API key")
    func recoverySuggestionAuthenticationFailed() {
        let error = TranscriptionError.authenticationFailed
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion!.contains("API key"))
    }

    // MARK: - Equatable Tests

    @Test("cancelled equals cancelled")
    func equatableCancelled() {
        #expect(TranscriptionError.cancelled == TranscriptionError.cancelled)
    }

    @Test("connectionFailed with different messages not equal")
    func equatableConnectionFailedDifferent() {
        #expect(TranscriptionError.connectionFailed("a") != TranscriptionError.connectionFailed("b"))
    }
}
