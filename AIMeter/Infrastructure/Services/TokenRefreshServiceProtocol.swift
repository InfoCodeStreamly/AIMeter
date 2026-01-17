import Foundation

/// Protocol for token refresh service
/// Enables dependency injection and testing
protocol TokenRefreshServiceProtocol: Sendable {

    /// Refresh OAuth token using refresh token
    /// - Parameter refreshToken: The refresh token to use
    /// - Returns: New tokens and expiration
    func refresh(using refreshToken: String) async throws -> TokenRefreshService.TokenRefreshResponse
}
