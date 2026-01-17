import Foundation
import AIMeterDomain
import AIMeterApplication

/// Protocol for Claude OAuth API operations (enables testing)
public protocol ClaudeAPIClientProtocol: Sendable {
    /// Fetches usage data
    func fetchUsage(token: String) async throws -> UsageAPIResponse

    /// Validates OAuth token
    func validateToken(_ token: String) async throws
}
