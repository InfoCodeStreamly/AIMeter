import Foundation

/// Response from token refresh operation
public struct TokenRefreshResponse: Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int

    public init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}

/// Protocol for token refresh service
/// Enables dependency injection and testing
public protocol TokenRefreshServiceProtocol: Sendable {
    /// Refresh OAuth token using refresh token
    /// - Parameter refreshToken: The refresh token to use
    /// - Returns: New tokens and expiration
    func refresh(using refreshToken: String) async throws -> TokenRefreshResponse
}
