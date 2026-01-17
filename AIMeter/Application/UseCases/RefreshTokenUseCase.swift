import Foundation
import OSLog

/// Protocol for OAuth credentials storage
protocol OAuthCredentialsRepository: Sendable {
    func getOAuthCredentials() async -> OAuthCredentials?
    func saveOAuthCredentials(_ credentials: OAuthCredentials) async throws
    func updateClaudeCodeKeychain(_ credentials: OAuthCredentials) async throws
}

/// Use case for refreshing OAuth tokens
final class RefreshTokenUseCase: Sendable {
    private let credentialsRepository: OAuthCredentialsRepository
    private let tokenRefreshService: any TokenRefreshServiceProtocol
    private let logger = Logger.api

    init(
        credentialsRepository: OAuthCredentialsRepository,
        tokenRefreshService: any TokenRefreshServiceProtocol
    ) {
        self.credentialsRepository = credentialsRepository
        self.tokenRefreshService = tokenRefreshService
    }

    /// Refreshes token if needed, returns current valid credentials
    /// - Returns: Valid OAuth credentials (either existing or refreshed)
    /// - Throws: TokenRefreshError if refresh fails
    func execute() async throws -> OAuthCredentials {
        logger.debug("🔄 RefreshTokenUseCase.execute() called")

        guard let credentials = await credentialsRepository.getOAuthCredentials() else {
            // Expected state before first sync - use debug level to avoid log spam
            logger.debug("❌ No OAuth credentials found, sync from Claude Code required")
            throw TokenRefreshError.noCredentials
        }

        logger.debug("✅ Got credentials, checking expiry...")

        // Check if refresh needed
        guard credentials.shouldRefresh else {
            let remaining = Int(credentials.timeUntilExpiry)
            logger.debug("Token still valid, expires in \(remaining)s")
            return credentials
        }

        if credentials.isExpired {
            logger.info("Token expired, refreshing...")
        } else {
            logger.info("Token expiring soon, refreshing proactively...")
        }

        // Perform refresh
        let response = try await tokenRefreshService.refresh(
            using: credentials.refreshToken
        )

        // Create updated credentials
        let newCredentials = credentials.withRefreshedTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn
        )

        // Save to our keychain
        try await credentialsRepository.saveOAuthCredentials(newCredentials)

        // Update Claude Code keychain (keep apps in sync)
        do {
            try await credentialsRepository.updateClaudeCodeKeychain(newCredentials)
            logger.info("Updated Claude Code keychain with refreshed credentials")
        } catch {
            // Non-fatal: our app still works, just Claude Code CLI won't have new token
            logger.warning("Failed to update Claude Code keychain: \(error.localizedDescription)")
        }

        logger.info("Token refreshed successfully, valid for \(response.expiresIn)s")

        return newCredentials
    }

    /// Checks if credentials exist and are valid (or can be refreshed)
    func hasValidCredentials() async -> Bool {
        guard let credentials = await credentialsRepository.getOAuthCredentials() else {
            return false
        }
        // Even if expired, we might be able to refresh
        return !credentials.refreshToken.isEmpty
    }
}
