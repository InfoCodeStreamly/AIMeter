import Foundation
import AIMeterDomain

/// Protocol for Claude Code sync service
public protocol ClaudeCodeSyncServiceProtocol: Sendable {
    func hasCredentials() async -> Bool
    func getSubscriptionInfo() async -> (type: String, email: String?)?
    func extractOAuthCredentials() async throws -> OAuthCredentials
    func updateCredentials(_ credentials: OAuthCredentials) async throws
}
