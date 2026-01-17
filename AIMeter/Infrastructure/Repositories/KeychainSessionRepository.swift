import Foundation
import OSLog

/// Implementation of SessionKeyRepository and OAuthCredentialsRepository using Keychain
actor KeychainSessionRepository: SessionKeyRepository, OAuthCredentialsRepository {
    private let keychainService: any KeychainServiceProtocol
    private let apiClient: any ClaudeAPIClientProtocol
    private let claudeCodeSyncService: any ClaudeCodeSyncServiceProtocol
    private let logger = Logger.keychain

    private let sessionKeyKey = "sessionKey"
    private let oauthCredentialsKey = "oauthCredentials"

    private var cachedOAuthCredentials: OAuthCredentials?

    init(
        keychainService: any KeychainServiceProtocol,
        apiClient: any ClaudeAPIClientProtocol,
        claudeCodeSyncService: any ClaudeCodeSyncServiceProtocol
    ) {
        self.keychainService = keychainService
        self.apiClient = apiClient
        self.claudeCodeSyncService = claudeCodeSyncService
    }

    // MARK: - SessionKeyRepository

    func save(_ key: SessionKey) async throws {
        try await keychainService.save(key.value, forKey: sessionKeyKey)
    }

    func get() async -> SessionKey? {
        guard let value = await keychainService.read(forKey: sessionKeyKey) else {
            return nil
        }
        return try? SessionKey.create(value)
    }

    func delete() async {
        try? await keychainService.delete(forKey: sessionKeyKey)
        try? await keychainService.delete(forKey: oauthCredentialsKey)
        cachedOAuthCredentials = nil
    }

    func exists() async -> Bool {
        await keychainService.exists(forKey: sessionKeyKey)
    }

    func validateToken(_ token: String) async throws {
        try await apiClient.validateToken(token)
    }

    // MARK: - OAuthCredentialsRepository

    func getOAuthCredentials() async -> OAuthCredentials? {
        logger.debug("🔍 Getting OAuth credentials...")

        // Try memory cache first
        if let cached = cachedOAuthCredentials {
            logger.debug("✅ Found in memory cache")
            return cached
        }

        // Try keychain
        if let jsonString = await keychainService.read(forKey: oauthCredentialsKey),
           let data = jsonString.data(using: .utf8),
           let credentials = try? JSONDecoder().decode(OAuthCredentials.self, from: data) {
            logger.debug("✅ Found in keychain, caching...")
            cachedOAuthCredentials = credentials
            return credentials
        }

        logger.debug("❌ No OAuth credentials found")
        return nil
    }

    func saveOAuthCredentials(_ credentials: OAuthCredentials) async throws {
        logger.info("💾 Saving OAuth credentials...")
        logger.debug("   Token expires: \(credentials.expiresAt)")
        logger.debug("   Has refresh token: \(!credentials.refreshToken.isEmpty)")

        let data = try JSONEncoder().encode(credentials)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            logger.error("❌ Failed to encode credentials to JSON")
            throw TokenRefreshError.keychainUpdateFailed
        }

        logger.debug("   JSON length: \(jsonString.count) chars")

        try await keychainService.save(jsonString, forKey: oauthCredentialsKey)
        logger.info("✅ Saved to keychain with key: \(self.oauthCredentialsKey)")

        cachedOAuthCredentials = credentials
        logger.debug("✅ Updated memory cache")

        // Also update session key to match current access token
        let sessionKey = try credentials.toSessionKey()
        try await save(sessionKey)
        logger.info("✅ Session key also updated")
    }

    func updateClaudeCodeKeychain(_ credentials: OAuthCredentials) async throws {
        try await claudeCodeSyncService.updateCredentials(credentials)
    }
}
