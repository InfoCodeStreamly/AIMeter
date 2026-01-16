import Foundation

/// Repository protocol for usage data operations
protocol UsageRepository: Sendable {
    /// Fetches current usage data from API
    /// - Parameter organizationId: Claude organization ID (nil for OAuth tokens)
    /// - Returns: Array of usage entities
    /// - Throws: Repository or network errors
    func fetchUsage(organizationId: OrganizationId?) async throws -> [UsageEntity]

    /// Gets cached usage data
    /// - Returns: Cached usage entities or empty array
    func getCachedUsage() async -> [UsageEntity]

    /// Saves usage data to cache
    /// - Parameter entities: Usage entities to cache
    func cacheUsage(_ entities: [UsageEntity]) async
}
