import Foundation

/// Validated Claude session key
struct SessionKey: Sendable, Equatable {
    let value: String

    private nonisolated init(_ value: String) {
        self.value = value
    }

    /// Creates validated session key
    /// - Throws: `DomainError` if invalid
    nonisolated static func create(_ value: String) throws -> SessionKey {
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
    var masked: String {
        guard value.count > 10 else { return "***" }
        let prefix = String(value.prefix(6))
        let suffix = String(value.suffix(3))
        return "\(prefix)...\(suffix)"
    }
}
