import AIMeterDomain
import Foundation
import Security

/// Keychain operations service (Infrastructure implementation)
///
/// Uses simple keychain items without kSecAttrAccessible to avoid
/// ACL-based password prompts on code signature changes (rebuilds/updates).
public actor KeychainService: KeychainServiceProtocol {
    private let service: String

    public init(service: String = "com.codestreamly.AIMeter") {
        self.service = service
    }

    /// Migrates old items that had kSecAttrAccessible (which creates ACL
    /// tied to code signature, causing password prompts on rebuild/update).
    /// Reads old item, saves without kSecAttrAccessible, deletes old.
    public func migrateFromACLKeychain(forKey key: String) {
        // Check if a "clean" item already exists (no migration needed)
        if read(forKey: key) != nil { return }

        // Try reading from any existing keychain item (including ACL-protected)
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

        // Delete old item (may have ACL attributes)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Save clean item without kSecAttrAccessible
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
