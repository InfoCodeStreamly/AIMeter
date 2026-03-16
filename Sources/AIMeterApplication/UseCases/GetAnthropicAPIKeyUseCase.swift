import Foundation
import AIMeterDomain

/// Retrieves or manages the stored Anthropic API key
public final class GetAnthropicAPIKeyUseCase: Sendable {
    private let apiKeyRepository: any APIKeyRepository

    public init(apiKeyRepository: any APIKeyRepository) {
        self.apiKeyRepository = apiKeyRepository
    }

    /// Gets stored Anthropic API key
    public func execute() async -> AnthropicAPIKey? {
        await apiKeyRepository.get()
    }

    /// Deletes stored Anthropic API key
    public func delete() async {
        await apiKeyRepository.delete()
    }

    /// Checks if Anthropic API key is configured
    public func isConfigured() async -> Bool {
        await apiKeyRepository.exists()
    }
}
