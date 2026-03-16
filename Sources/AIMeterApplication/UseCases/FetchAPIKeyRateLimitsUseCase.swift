import Foundation
import AIMeterDomain

/// Fetches current rate limits for the configured Anthropic API key
public final class FetchAPIKeyRateLimitsUseCase: Sendable {
    private let apiKeyRepository: any APIKeyRepository
    private let rateLimitRepository: any RateLimitRepository

    public init(
        apiKeyRepository: any APIKeyRepository,
        rateLimitRepository: any RateLimitRepository
    ) {
        self.apiKeyRepository = apiKeyRepository
        self.rateLimitRepository = rateLimitRepository
    }

    /// Fetches rate limits from API headers
    /// - Throws: `DomainError.apiKeyNotFound` if no key configured
    public func execute() async throws -> APIKeyRateLimitEntity {
        guard let key = await apiKeyRepository.get() else {
            throw DomainError.apiKeyNotFound
        }
        return try await rateLimitRepository.fetchRateLimits(apiKey: key.value)
    }
}
