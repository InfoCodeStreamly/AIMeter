import Foundation

/// Repository protocol for session key operations
public protocol SessionKeyRepository: Sendable {
    /// Saves session key securely
    func save(_ key: SessionKey) async throws

    /// Retrieves stored session key
    func get() async -> SessionKey?

    /// Deletes stored session key
    func delete() async

    /// Checks if session key exists
    func exists() async -> Bool

    /// Validates OAuth token
    func validateToken(_ token: String) async throws
}
