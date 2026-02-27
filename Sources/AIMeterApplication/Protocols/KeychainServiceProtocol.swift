import Foundation

/// Protocol for Keychain operations (enables testing)
public protocol KeychainServiceProtocol: Sendable {
    func save(_ value: String, forKey key: String) async throws
    func read(forKey key: String) async -> String?
    func delete(forKey key: String) async throws
    func exists(forKey key: String) async -> Bool
}
