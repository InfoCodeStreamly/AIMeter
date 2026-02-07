import AIMeterDomain
import Foundation
import Security

/// Keychain operations service (Infrastructure implementation)
public actor KeychainService: KeychainServiceProtocol {
    private let service: String

    public init(service: String = "com.codestreamly.AIMeter") {
        self.service = service
    }

    /// Migrates items from file-based keychain to Data Protection keychain.
    /// Old items (created without kSecUseDataProtectionKeychain) have ACL
    /// tied to code signature, causing password prompts on every rebuild.
    /// This reads from old keychain, saves to new, then deletes old item.
    public func migrateFromFileBasedKeychain(forKey key: String) {
        // Try to read from old file-based keychain
        let oldQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(oldQuery as CFDictionary, &result)

        guard status == errSecSuccess,
            let data = result as? Data,
            let value = String(data: data, encoding: .utf8)
        else { return }

        // Save to Data Protection keychain
        try? save(value, forKey: key)

        // Delete from old file-based keychain (without kSecUseDataProtectionKeychain)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)
    }

    public func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw InfrastructureError.keychainSaveFailed(-1)
        }

        // Delete existing item first
        try? delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecUseDataProtectionKeychain as String: true,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw InfrastructureError.keychainSaveFailed(status)
        }
    }

    public func read(forKey key: String) -> String? {
        // Try Data Protection keychain first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseDataProtectionKeychain as String: true,
        ]

        var result: AnyObject?
        var status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
            let data = result as? Data,
            let value = String(data: data, encoding: .utf8)
        {
            return value
        }

        // Fallback: try file-based keychain (pre-migration items)
        let fallbackQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        result = nil
        status = SecItemCopyMatching(fallbackQuery as CFDictionary, &result)

        guard status == errSecSuccess,
            let data = result as? Data,
            let value = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return value
    }

    public func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecUseDataProtectionKeychain as String: true,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw InfrastructureError.keychainDeleteFailed(status)
        }
    }

    public func exists(forKey key: String) -> Bool {
        read(forKey: key) != nil
    }
}
