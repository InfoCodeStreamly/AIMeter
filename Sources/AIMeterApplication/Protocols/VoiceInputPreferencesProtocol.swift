import Foundation
import AIMeterDomain

/// Protocol for managing voice input preferences
@MainActor
public protocol VoiceInputPreferencesProtocol: Sendable {
    /// Whether voice input feature is enabled
    var isEnabled: Bool { get set }

    /// Selected transcription language
    var selectedLanguage: TranscriptionLanguage { get set }
}
