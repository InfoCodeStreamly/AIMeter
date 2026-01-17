import Foundation

/// Validated Claude session key
public struct SessionKey: Sendable, Equatable {
    public let value: String

    private nonisolated init(_ value: String) {
        self.value = value
    }

    /// Creates validated session key
    /// - Throws: `DomainError` if invalid
    public nonisolated static func create(_ value: String) throws -> SessionKey {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw DomainError.emptySessionKey
        }

        guard trimmed.count >= 20 else {
            throw DomainError.invalidSessionKeyFormat
        }

        return SessionKey(trimmed)
    }

    /// Masked value for display (e.g., "sk-ant...xyz")
    public var masked: String {
        guard value.count > 10 else { return "***" }
        let prefix = String(value.prefix(6))
        let suffix = String(value.suffix(3))
        return "\(prefix)...\(suffix)"
    }
}
