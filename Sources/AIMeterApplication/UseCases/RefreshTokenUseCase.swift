import Foundation
import AIMeterDomain

/// Use case for refreshing OAuth tokens
public final class RefreshTokenUseCase: Sendable {
    private let credentialsRepository: any OAuthCredentialsRepository
    private let tokenRefreshService: any TokenRefreshServiceProtocol

    public init(
        credentialsRepository: any OAuthCredentialsRepository,
        tokenRefreshService: any TokenRefreshServiceProtocol
    ) {
        self.credentialsRepository = credentialsRepository
        self.tokenRefreshService = tokenRefreshService
    }

    /// Refreshes token if needed, returns current valid credentials
    /// - Returns: Valid OAuth credentials (either existing or refreshed)
    /// - Throws: TokenRefreshError if refresh fails
    public func execute() async throws -> OAuthCredentials {

        guard let credentials = await credentialsRepository.getOAuthCredentials() else {
            throw TokenRefreshError.noCredentials
        }


        // Check if refresh needed
        guard credentials.shouldRefresh else {
            let remaining = Int(credentials.timeUntilExpiry)
            return credentials
        }

        if credentials.isExpired {
        } else {
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
        } catch {
            // Non-fatal: our app still works, just Claude Code CLI won't have new token
        }


        return newCredentials
    }

    /// Checks if credentials exist and are valid (or can be refreshed)
    public func hasValidCredentials() async -> Bool {
        guard let credentials = await credentialsRepository.getOAuthCredentials() else {
            return false
        }
        // Even if expired, we might be able to refresh
        return !credentials.refreshToken.isEmpty
    }
}
