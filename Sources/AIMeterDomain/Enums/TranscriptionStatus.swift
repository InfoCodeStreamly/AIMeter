import Foundation

/// Status of the voice transcription state machine
public enum TranscriptionStatus: Sendable, Equatable {
    case idle
    case connecting
    case ready
    case recording
    case result(TranscriptionEntity)
    case error(TranscriptionError)

    public var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }

    public var isProcessing: Bool {
        switch self {
        case .connecting, .recording: true
        default: false
        }
    }

    public var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
}
