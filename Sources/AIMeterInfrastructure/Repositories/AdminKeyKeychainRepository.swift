import Foundation
import AIMeterDomain
import AIMeterApplication

/// Keychain-backed storage for Admin API key
public actor AdminKeyKeychainRepository: AdminKeyRepository {
    private let keychainService: any KeychainServiceProtocol
    private let keychainKey = "adminAPIKey"

    public init(keychainService: any KeychainServiceProtocol) {
        self.keychainService = keychainService
    }

    public func save(_ key: AdminAPIKey) async throws {
        try await keychainService.save(key.value, forKey: keychainKey)
    }

    public func get() async -> AdminAPIKey? {
        guard let value = await keychainService.read(forKey: keychainKey) else {
            return nil
        }
        return try? AdminAPIKey.create(value)
    }

    public func delete() async {
        try? await keychainService.delete(forKey: keychainKey)
    }

    public func exists() async -> Bool {
        await keychainService.exists(forKey: keychainKey)
    }
}
