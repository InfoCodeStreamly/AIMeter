import Foundation

/// Validated Admin API key for Anthropic Admin API
/// Format: sk-ant-admin-...
public struct AdminAPIKey: Sendable, Equatable {
    public let value: String

    private nonisolated init(_ value: String) {
        self.value = value
    }

    /// Creates validated Admin API key
    /// - Throws: `DomainError.invalidAdminKeyFormat` if invalid
    public nonisolated static func create(_ value: String) throws -> AdminAPIKey {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw DomainError.invalidAdminKeyFormat
        }

        guard trimmed.hasPrefix("sk-ant-admin") else {
            throw DomainError.invalidAdminKeyFormat
        }

        guard trimmed.count >= 20 else {
            throw DomainError.invalidAdminKeyFormat
        }

        return AdminAPIKey(trimmed)
    }

    /// Masked value for display (e.g., "sk-ant...xyz")
    public var masked: String {
        guard value.count > 10 else { return "***" }
        let prefix = String(value.prefix(6))
        let suffix = String(value.suffix(3))
        return "\(prefix)...\(suffix)"
    }
}
