import Foundation
import AIMeterDomain
import AIMeterApplication

/// Implementation of SessionKeyRepository and OAuthCredentialsRepository using Keychain
public actor KeychainSessionRepository: SessionKeyRepository, OAuthCredentialsRepository {
    private let keychainService: any KeychainServiceProtocol
    private let apiClient: any ClaudeAPIClientProtocol
    private let claudeCodeSyncService: any ClaudeCodeSyncServiceProtocol

    private let sessionKeyKey = "sessionKey"
    private let oauthCredentialsKey = "oauthCredentials"

    private var cachedOAuthCredentials: OAuthCredentials?

    public init(
        keychainService: any KeychainServiceProtocol,
        apiClient: any ClaudeAPIClientProtocol,
        claudeCodeSyncService: any ClaudeCodeSyncServiceProtocol
    ) {
        self.keychainService = keychainService
        self.apiClient = apiClient
        self.claudeCodeSyncService = claudeCodeSyncService
    }

    // MARK: - SessionKeyRepository

    public func save(_ key: SessionKey) async throws {
        try await keychainService.save(key.value, forKey: sessionKeyKey)
    }

    public func get() async -> SessionKey? {
        guard let value = await keychainService.read(forKey: sessionKeyKey) else {
            return nil
        }
        return try? SessionKey.create(value)
    }

    public func delete() async {
        try? await keychainService.delete(forKey: sessionKeyKey)
        try? await keychainService.delete(forKey: oauthCredentialsKey)
        cachedOAuthCredentials = nil
    }

    public func exists() async -> Bool {
        await keychainService.exists(forKey: sessionKeyKey)
    }

    public func validateToken(_ token: String) async throws {
        try await apiClient.validateToken(token)
    }

    // MARK: - OAuthCredentialsRepository

    public func getOAuthCredentials() async -> OAuthCredentials? {

        // Try memory cache first
        if let cached = cachedOAuthCredentials {
            return cached
        }

        // Try keychain
        if let jsonString = await keychainService.read(forKey: oauthCredentialsKey),
           let data = jsonString.data(using: .utf8),
           let credentials = try? JSONDecoder().decode(OAuthCredentials.self, from: data) {
            cachedOAuthCredentials = credentials
            return credentials
        }

        return nil
    }

    public func saveOAuthCredentials(_ credentials: OAuthCredentials) async throws {

        let data = try JSONEncoder().encode(credentials)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw TokenRefreshError.keychainUpdateFailed
        }


        try await keychainService.save(jsonString, forKey: oauthCredentialsKey)

        cachedOAuthCredentials = credentials

        // Also update session key to match current access token
        let sessionKey = try credentials.toSessionKey()
        try await save(sessionKey)
    }

    public func updateClaudeCodeKeychain(_ credentials: OAuthCredentials) async throws {
        try await claudeCodeSyncService.updateCredentials(credentials)
    }
}
