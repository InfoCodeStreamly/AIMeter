import Testing
@testable import AIMeterDomain

@Suite("TranscriptionStatus")
struct TranscriptionStatusTests {

    // MARK: - isRecording Tests

    @Test("isRecording returns true for recording")
    func isRecordingForRecording() {
        #expect(TranscriptionStatus.recording.isRecording)
    }

    @Test("isRecording returns false for idle")
    func isRecordingForIdle() {
        #expect(!TranscriptionStatus.idle.isRecording)
    }

    @Test("isRecording returns false for ready")
    func isRecordingForReady() {
        #expect(!TranscriptionStatus.ready.isRecording)
    }

    @Test("isRecording returns false for connecting")
    func isRecordingForConnecting() {
        #expect(!TranscriptionStatus.connecting.isRecording)
    }

    // MARK: - isProcessing Tests

    @Test("isProcessing returns true for connecting")
    func isProcessingForConnecting() {
        #expect(TranscriptionStatus.connecting.isProcessing)
    }

    @Test("isProcessing returns true for recording")
    func isProcessingForRecording() {
        #expect(TranscriptionStatus.recording.isProcessing)
    }

    @Test("isProcessing returns false for idle")
    func isProcessingForIdle() {
        #expect(!TranscriptionStatus.idle.isProcessing)
    }

    @Test("isProcessing returns false for ready")
    func isProcessingForReady() {
        #expect(!TranscriptionStatus.ready.isProcessing)
    }

    // MARK: - isReady Tests

    @Test("isReady returns true for ready")
    func isReadyForReady() {
        #expect(TranscriptionStatus.ready.isReady)
    }

    @Test("isReady returns false for idle")
    func isReadyForIdle() {
        #expect(!TranscriptionStatus.idle.isReady)
    }

    // MARK: - Equatable Tests

    @Test("idle equals idle")
    func equatableIdle() {
        #expect(TranscriptionStatus.idle == TranscriptionStatus.idle)
    }

    @Test("recording equals recording")
    func equatableRecording() {
        #expect(TranscriptionStatus.recording == TranscriptionStatus.recording)
    }
}
