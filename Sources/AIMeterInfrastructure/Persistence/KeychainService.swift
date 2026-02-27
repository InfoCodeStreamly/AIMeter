import AIMeterDomain
import Foundation
import OSLog
import Security

/// Keychain operations service (Infrastructure implementation)
///
/// Uses Data Protection keychain (kSecUseDataProtectionKeychain) which
/// does NOT have per-app ACL tied to code signature. This prevents
/// password prompts on app rebuild/update.
/// Requires application-groups or keychain-access-groups entitlement.
public actor KeychainService: KeychainServiceProtocol {
    private let service: String
    private let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "keychain")

    public init(service: String = "com.codestreamly.AIMeter") {
        self.service = service
    }

    /// Migrates items from the file-based login keychain (which has ACL
    /// tied to code signature, causing password prompts) to the Data
    /// Protection keychain (no per-app ACL).
    public func migrateFromACLKeychain(forKey key: String) {
        // Check if item already exists in Data Protection keychain
        if read(forKey: key) != nil { return }

        // Try reading from old file-based keychain (without kSecUseDataProtectionKeychain)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
            let data = result as? Data,
            let value = String(data: data, encoding: .utf8)
        else { return }

        logger.info("Migrating keychain item '\(key)' to Data Protection keychain")

        // Delete old item from file-based keychain
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Save to Data Protection keychain
        try? save(value, forKey: key)
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
            kSecUseDataProtectionKeychain as String: true,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw InfrastructureError.keychainSaveFailed(status)
        }
    }

    public func read(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseDataProtectionKeychain as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

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
