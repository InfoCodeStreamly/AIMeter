import Foundation

/// Repository protocol for Anthropic API key storage
public protocol APIKeyRepository: Sendable {
    /// Saves Anthropic API key to secure storage
    func save(_ key: AnthropicAPIKey) async throws

    /// Gets stored Anthropic API key
    func get() async -> AnthropicAPIKey?

    /// Deletes stored Anthropic API key
    func delete() async

    /// Checks if Anthropic API key exists
    func exists() async -> Bool
}
