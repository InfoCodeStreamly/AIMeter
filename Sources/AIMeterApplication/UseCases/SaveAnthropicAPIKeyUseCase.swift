import Foundation
import AIMeterDomain

/// Validates and saves an Anthropic API key
public final class SaveAnthropicAPIKeyUseCase: Sendable {
    private let apiKeyRepository: any APIKeyRepository

    public init(apiKeyRepository: any APIKeyRepository) {
        self.apiKeyRepository = apiKeyRepository
    }

    /// Validates key format and saves to secure storage
    /// - Returns: Validated AnthropicAPIKey
    /// - Throws: `DomainError.invalidAPIKeyFormat` if invalid
    public func execute(rawKey: String) async throws -> AnthropicAPIKey {
        let key = try AnthropicAPIKey.create(rawKey)
        try await apiKeyRepository.save(key)
        return key
    }
}
