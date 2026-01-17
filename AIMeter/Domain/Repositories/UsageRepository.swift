import Foundation

/// Repository protocol for usage data operations
protocol UsageRepository: Sendable {
    /// Fetches current usage data from API
    func fetchUsage() async throws -> [UsageEntity]

    /// Gets cached usage data
    func getCachedUsage() async -> [UsageEntity]

    /// Saves usage data to cache
    func cacheUsage(_ entities: [UsageEntity]) async
}
