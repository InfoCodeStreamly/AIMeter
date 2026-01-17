import Foundation
import OSLog

/// Service for refreshing OAuth tokens
actor TokenRefreshService: TokenRefreshServiceProtocol {
    private let clientId = APIConstants.OAuth.clientId
    private let tokenURL = URL(string: APIConstants.OAuth.tokenURL)!
    private let logger = Logger.api

    struct TokenRefreshResponse: Sendable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int
    }

    /// Refresh OAuth token using refresh token
    /// - Parameter refreshToken: The refresh token to use
    /// - Returns: New tokens and expiration
    func refresh(using refreshToken: String) async throws -> TokenRefreshResponse {
        logger.info("Refreshing OAuth token...")

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        // IMPORTANT: Must be form-urlencoded, NOT JSON!
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = APIConstants.timeout

        let body = [
            "grant_type=refresh_token",
            "refresh_token=\(refreshToken)",
            "client_id=\(clientId)"
        ].joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw TokenRefreshError.invalidResponse
        }

        logger.debug("Refresh response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorBody = String(data: data, encoding: .utf8) {
                logger.error("Refresh failed: \(errorBody)")
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 400 {
                throw TokenRefreshError.refreshTokenExpired
            }

            throw TokenRefreshError.refreshFailed(statusCode: httpResponse.statusCode)
        }

        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let newRefreshToken = json["refresh_token"] as? String,
              let expiresIn = json["expires_in"] as? Int else {
            logger.error("Failed to parse refresh response")
            throw TokenRefreshError.invalidResponse
        }

        logger.info("Token refresh successful, valid for \(expiresIn)s")

        return TokenRefreshResponse(
            accessToken: accessToken,
            refreshToken: newRefreshToken,
            expiresIn: expiresIn
        )
    }
}

// MARK: - Errors

enum TokenRefreshError: LocalizedError, Equatable {
    case noCredentials
    case refreshTokenExpired
    case refreshFailed(statusCode: Int)
    case invalidResponse
    case keychainUpdateFailed

    var errorDescription: String? {
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
    var requiresReauth: Bool {
        switch self {
        case .noCredentials, .refreshTokenExpired:
            return true
        default:
            return false
        }
    }
}
