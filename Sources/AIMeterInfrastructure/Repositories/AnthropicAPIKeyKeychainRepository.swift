import Foundation
import AIMeterDomain
import AIMeterApplication

/// Keychain-backed storage for Anthropic API key
public actor AnthropicAPIKeyKeychainRepository: APIKeyRepository {
    private let keychainService: any KeychainServiceProtocol
    private let keychainKey = "anthropicAPIKey"

    public init(keychainService: any KeychainServiceProtocol) {
        self.keychainService = keychainService
    }

    public func save(_ key: AnthropicAPIKey) async throws {
        try await keychainService.save(key.value, forKey: keychainKey)
    }

    public func get() async -> AnthropicAPIKey? {
        guard let value = await keychainService.read(forKey: keychainKey) else {
            return nil
        }
        return try? AnthropicAPIKey.create(value)
    }

    public func delete() async {
        try? await keychainService.delete(forKey: keychainKey)
    }

    public func exists() async -> Bool {
        await keychainService.exists(forKey: keychainKey)
    }
}
