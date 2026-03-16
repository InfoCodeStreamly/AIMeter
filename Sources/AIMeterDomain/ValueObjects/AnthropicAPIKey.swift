import Foundation

/// Validated Anthropic API key for personal rate limit tracking
/// Format: sk-ant-api03-...
public struct AnthropicAPIKey: Sendable, Equatable {
    public let value: String

    private nonisolated init(_ value: String) {
        self.value = value
    }

    /// Creates validated Anthropic API key
    /// - Throws: `DomainError.invalidAPIKeyFormat` if invalid
    public nonisolated static func create(_ value: String) throws -> AnthropicAPIKey {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw DomainError.invalidAPIKeyFormat
        }

        guard trimmed.hasPrefix("sk-ant-api03-") else {
            throw DomainError.invalidAPIKeyFormat
        }

        guard trimmed.count >= 20 else {
            throw DomainError.invalidAPIKeyFormat
        }

        return AnthropicAPIKey(trimmed)
    }

    /// Masked value for display (e.g., "sk-ant...xyz")
    public var masked: String {
        guard value.count > 10 else { return "***" }
        let prefix = String(value.prefix(6))
        let suffix = String(value.suffix(3))
        return "\(prefix)...\(suffix)"
    }
}
