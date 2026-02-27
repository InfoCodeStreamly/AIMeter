import Foundation

/// Domain entity representing a completed transcription result
public struct TranscriptionEntity: Sendable, Equatable {
    public let id: UUID
    public let text: String
    public let language: TranscriptionLanguage
    public let duration: TimeInterval

    public nonisolated init(
        id: UUID = UUID(),
        text: String,
        language: TranscriptionLanguage,
        duration: TimeInterval
    ) {
        self.id = id
        self.text = text
        self.language = language
        self.duration = duration
    }

    public var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var wordCount: Int {
        text.split(separator: " ").count
    }
}

// MARK: - Factory Methods

extension TranscriptionEntity {
    public nonisolated static func empty() -> TranscriptionEntity {
        TranscriptionEntity(text: "", language: .autoDetect, duration: 0)
    }
}
