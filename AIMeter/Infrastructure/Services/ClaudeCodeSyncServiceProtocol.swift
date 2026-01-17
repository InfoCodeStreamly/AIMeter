import Foundation

/// Protocol for Claude Code sync service
/// Enables dependency injection and testing
protocol ClaudeCodeSyncServiceProtocol: Sendable {

    /// Checks if Claude Code credentials exist in system Keychain
    func hasCredentials() async -> Bool

    /// Gets subscription info from Claude Code credentials
    func getSubscriptionInfo() async -> (type: String, email: String?)?

    /// Extracts full OAuth credentials from Claude Code keychain
    func extractOAuthCredentials() async throws -> OAuthCredentials

    /// Updates Claude Code keychain with refreshed credentials
    func updateCredentials(_ credentials: OAuthCredentials) async throws
}
