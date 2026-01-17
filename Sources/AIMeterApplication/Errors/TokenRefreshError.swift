import Foundation

/// Errors that can occur during token refresh
public enum TokenRefreshError: LocalizedError, Equatable, Sendable {
    case noCredentials
    case refreshTokenExpired
    case refreshFailed(statusCode: Int)
    case invalidResponse
    case keychainUpdateFailed

    public var errorDescription: String? {
        switch self {
        case .noCredentials:
            return "No OAuth credentials found. Please sync from Claude Code."
        case .refreshTokenExpired:
            return "Session expired. Please re-login to Claude Code."
        case .refreshFailed(let code):
            return "Token refresh failed (HTTP \(code))"
        case .invalidResponse:
            return "Invalid response from auth server"
        case .keychainUpdateFailed:
            return "Failed to update credentials"
        }
    }

    /// Whether this error requires user to re-authenticate
    public var requiresReauth: Bool {
        switch self {
        case .noCredentials, .refreshTokenExpired:
            return true
        default:
            return false
        }
    }
}
