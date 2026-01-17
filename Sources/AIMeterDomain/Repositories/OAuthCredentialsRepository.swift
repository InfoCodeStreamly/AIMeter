import Foundation

/// Repository protocol for OAuth credentials storage
public protocol OAuthCredentialsRepository: Sendable {
    /// Gets stored OAuth credentials
    func getOAuthCredentials() async -> OAuthCredentials?

    /// Saves OAuth credentials
    func saveOAuthCredentials(_ credentials: OAuthCredentials) async throws

    /// Updates Claude Code keychain with credentials
    func updateClaudeCodeKeychain(_ credentials: OAuthCredentials) async throws
}
