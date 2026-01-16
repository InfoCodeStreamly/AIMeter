import Foundation

/// Repository protocol for session key operations
protocol SessionKeyRepository: Sendable {
    /// Saves session key securely
    /// - Parameter key: Session key to save
    /// - Throws: Storage errors
    func save(_ key: SessionKey) async throws

    /// Retrieves stored session key
    /// - Returns: Session key or nil if not found
    func get() async -> SessionKey?

    /// Deletes stored session key
    func delete() async

    /// Checks if session key exists
    /// - Returns: True if key is stored
    func exists() async -> Bool

    /// Fetches organization ID using session key
    /// - Parameter key: Session key for authentication
    /// - Returns: Organization ID (nil for OAuth tokens which don't need org ID)
    /// - Throws: Network or validation errors
    func fetchOrganizationId(using key: SessionKey) async throws -> OrganizationId?

    /// Gets cached organization ID
    /// - Returns: Cached organization ID or nil
    func getCachedOrganizationId() async -> OrganizationId?

    /// Caches organization ID
    /// - Parameter id: Organization ID to cache
    func cacheOrganizationId(_ id: OrganizationId) async
}
