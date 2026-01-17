import Foundation
import Security

/// Keychain operations service
actor KeychainService: KeychainServiceProtocol {
    private let service: String

    init(service: String = "com.codestreamly.AIMeter") {
        self.service = service
    }

    /// Saves value to Keychain
    /// - Parameters:
    ///   - value: String value to save
    ///   - key: Keychain key
    func save(_ value: String, forKey key: String) throws {
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
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw InfrastructureError.keychainSaveFailed(status)
        }
    }

    /// Reads value from Keychain
    /// - Parameter key: Keychain key
    /// - Returns: Stored string or nil
    func read(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    /// Deletes value from Keychain
    /// - Parameter key: Keychain key
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw InfrastructureError.keychainDeleteFailed(status)
        }
    }

    /// Checks if key exists in Keychain
    /// - Parameter key: Keychain key
    /// - Returns: True if exists
    func exists(forKey key: String) -> Bool {
        read(forKey: key) != nil
    }
}
