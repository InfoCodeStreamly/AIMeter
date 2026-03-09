import Foundation

/// Repository protocol for Admin API key storage
public protocol AdminKeyRepository: Sendable {
    /// Saves Admin API key to secure storage
    func save(_ key: AdminAPIKey) async throws

    /// Gets stored Admin API key
    func get() async -> AdminAPIKey?

    /// Deletes stored Admin API key
    func delete() async

    /// Checks if Admin API key exists
    func exists() async -> Bool
}
