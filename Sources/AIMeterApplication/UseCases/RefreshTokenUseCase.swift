import Foundation
import OSLog
import AIMeterDomain

/// Use case for refreshing OAuth tokens
public final class RefreshTokenUseCase: Sendable {
    private let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "token-refresh")
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
            logger.warning("execute: no credentials found")
            throw TokenRefreshError.noCredentials
        }

        guard credentials.shouldRefresh else {
            logger.debug("execute: token still valid, no refresh needed")
            return credentials
        }

        logger.info("execute: token needs refresh, attempting...")

        do {
            let response = try await tokenRefreshService.refresh(
                using: credentials.refreshToken
            )

            let newCredentials = credentials.withRefreshedTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                expiresIn: response.expiresIn
            )

            try await credentialsRepository.saveOAuthCredentials(newCredentials)
            logger.info("execute: token refreshed and saved successfully")

            try? await credentialsRepository.updateClaudeCodeKeychain(newCredentials)

            return newCredentials
        } catch {
            logger.warning("execute: refresh failed (\(error.localizedDescription)), trying resync from Claude Code keychain")
            if let resynced = try? await credentialsRepository.resyncFromClaudeCode(),
               !resynced.isExpired {
                logger.info("execute: resync from Claude Code keychain succeeded")
                return resynced
            }
            logger.error("execute: resync also failed, propagating error")
            throw error
        }
    }

    /// Force-refresh token via refresh_token endpoint (e.g. when access_token is perma-429'd)
    /// - Returns: New credentials with fresh access_token, or nil if refresh failed
    public func forceRefresh() async -> OAuthCredentials? {
        logger.info("forceRefresh: forcing token refresh via refresh_token endpoint")
        guard let credentials = await credentialsRepository.getOAuthCredentials(),
              !credentials.refreshToken.isEmpty else {
            logger.warning("forceRefresh: no credentials or refresh token")
            return nil
        }
        do {
            let response = try await tokenRefreshService.refresh(using: credentials.refreshToken)
            let newCredentials = credentials.withRefreshedTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                expiresIn: response.expiresIn
            )
            try await credentialsRepository.saveOAuthCredentials(newCredentials)
            try? await credentialsRepository.updateClaudeCodeKeychain(newCredentials)
            logger.info("forceRefresh: got fresh access_token (prefix=\(String(newCredentials.accessToken.prefix(15)), privacy: .public))")
            return newCredentials
        } catch {
            logger.warning("forceRefresh: failed (\(error.localizedDescription, privacy: .public))")
            return nil
        }
    }

    /// Force resync credentials from Claude Code keychain (e.g. after 429 — user may have /login'd)
    /// - Returns: Resynced credentials if different from current, nil if same or failed
    public func forceResync() async -> OAuthCredentials? {
        logger.info("forceResync: attempting resync from Claude Code keychain")
        do {
            let current = await credentialsRepository.getOAuthCredentials()
            let resynced = try await credentialsRepository.resyncFromClaudeCode()
            if resynced.accessToken != current?.accessToken {
                logger.info("forceResync: got DIFFERENT token, resync successful")
                return resynced
            } else {
                logger.info("forceResync: same token as before, no change")
                return nil
            }
        } catch {
            logger.warning("forceResync: failed (\(error.localizedDescription, privacy: .public))")
            return nil
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
