import Foundation
import AIMeterApplication

/// Service for refreshing OAuth tokens (Infrastructure implementation)
public actor TokenRefreshService: TokenRefreshServiceProtocol {

    public init() {}

    /// Refresh OAuth token using refresh token
    public func refresh(using refreshToken: String) async throws -> TokenRefreshResponse {
        let tokenURL = URL(string: APIConstants.OAuth.tokenURL)!

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = APIConstants.timeout

        let body = [
            "grant_type=refresh_token",
            "refresh_token=\(refreshToken)",
            "client_id=\(APIConstants.OAuth.clientId)"
        ].joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TokenRefreshError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 400 {
                throw TokenRefreshError.refreshTokenExpired
            }
            throw TokenRefreshError.refreshFailed(statusCode: httpResponse.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let newRefreshToken = json["refresh_token"] as? String,
              let expiresIn = json["expires_in"] as? Int else {
            throw TokenRefreshError.invalidResponse
        }

        return TokenRefreshResponse(
            accessToken: accessToken,
            refreshToken: newRefreshToken,
            expiresIn: expiresIn
        )
    }
}
