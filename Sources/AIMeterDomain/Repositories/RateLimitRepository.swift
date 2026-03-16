import Foundation

/// Repository protocol for fetching API rate limits
public protocol RateLimitRepository: Sendable {
    /// Fetches current rate limits using API key
    func fetchRateLimits(apiKey: String) async throws -> APIKeyRateLimitEntity
}
