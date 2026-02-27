import Foundation

/// Errors that can occur during voice transcription
public enum TranscriptionError: LocalizedError, Sendable, Equatable {
    case microphoneAccessDenied
    case accessibilityDenied
    case apiKeyMissing
    case connectionFailed(String)
    case authenticationFailed
    case transcriptionFailed(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .microphoneAccessDenied:
            return "Microphone access denied"
        case .accessibilityDenied:
            return "Accessibility permission required"
        case .apiKeyMissing:
            return "Deepgram API key not configured"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .authenticationFailed:
            return "Invalid API key"
        case .transcriptionFailed(let message):
            return "Transcription error: \(message)"
        case .cancelled:
            return "Cancelled"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .microphoneAccessDenied:
            return "Open System Settings \u{2192} Privacy & Security \u{2192} Microphone and enable AIMeter."
        case .accessibilityDenied:
            return "Open System Settings \u{2192} Privacy & Security \u{2192} Accessibility, enable AIMeter, then restart the app."
        case .apiKeyMissing:
            return "Add your Deepgram API key in Settings \u{2192} Voice Input."
        case .authenticationFailed:
            return "Check your API key in Settings \u{2192} Voice Input."
        default:
            return nil
        }
    }
}
