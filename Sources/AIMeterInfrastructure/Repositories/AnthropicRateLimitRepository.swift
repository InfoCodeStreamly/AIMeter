import Foundation
import OSLog
import AIMeterDomain

/// Protocol for HTTP clients that fetch Anthropic API rate limits.
/// Enables dependency injection and testability.
public protocol RateLimitClientProtocol: Sendable {
    func fetchRateLimits(apiKey: String) async throws -> APIKeyRateLimitEntity
}

/// Implementation of RateLimitRepository using Anthropic API headers
public actor AnthropicRateLimitRepository: RateLimitRepository {
    private let rateLimitClient: any RateLimitClientProtocol
    private let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "rate-limit-repo")

    public init(rateLimitClient: any RateLimitClientProtocol) {
        self.rateLimitClient = rateLimitClient
    }

    public func fetchRateLimits(apiKey: String) async throws -> APIKeyRateLimitEntity {
        let entity = try await rateLimitClient.fetchRateLimits(apiKey: apiKey)
        logger.info("Rate limits fetched: \(entity.requestsRemaining)/\(entity.requestsLimit) RPM")
        return entity
    }
}
