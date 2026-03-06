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
            return credentials
        }

        // Perform refresh
        do {
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
            try? await credentialsRepository.updateClaudeCodeKeychain(newCredentials)

            return newCredentials
        } catch {
            // Refresh failed — fallback: re-sync from Claude Code keychain
            // Claude Code CLI may have already refreshed the token
            if let resynced = try? await credentialsRepository.resyncFromClaudeCode(),
               !resynced.isExpired {
                return resynced
            }
            throw error
        }
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
