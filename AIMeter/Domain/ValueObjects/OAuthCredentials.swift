import Foundation

/// Full OAuth credentials from Claude Code
struct OAuthCredentials: Codable, Sendable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let scopes: [String]
    let subscriptionType: String?
    let rateLimitTier: String?

    /// Check if token is expired
    var isExpired: Bool {
        Date() >= expiresAt
    }

    /// Check if token should be refreshed (< 5 min remaining)
    var shouldRefresh: Bool {
        Date().addingTimeInterval(5 * 60) >= expiresAt
    }

    /// Time until expiration in seconds
    var timeUntilExpiry: TimeInterval {
        expiresAt.timeIntervalSinceNow
    }

    /// Create SessionKey from access token
    nonisolated func toSessionKey() throws -> SessionKey {
        try SessionKey.create(accessToken)
    }

    /// Create updated credentials after refresh
    func withRefreshedTokens(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int
    ) -> OAuthCredentials {
        OAuthCredentials(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn)),
            scopes: scopes,
            subscriptionType: subscriptionType,
            rateLimitTier: rateLimitTier
        )
    }
}

// MARK: - JSON Decoding from Claude Code format

extension OAuthCredentials {
    /// Decode from Claude Code Keychain JSON format
    static func fromClaudeCodeJSON(_ json: [String: Any]) throws -> OAuthCredentials {
        guard let oauth = json["claudeAiOauth"] as? [String: Any] else {
            throw OAuthCredentialsError.missingOAuthData
        }

        guard let accessToken = oauth["accessToken"] as? String, !accessToken.isEmpty else {
            throw OAuthCredentialsError.missingAccessToken
        }

        guard let refreshToken = oauth["refreshToken"] as? String, !refreshToken.isEmpty else {
            throw OAuthCredentialsError.missingRefreshToken
        }

        guard let expiresAtMs = oauth["expiresAt"] as? Int64 else {
            throw OAuthCredentialsError.missingExpiresAt
        }

        let expiresAt = Date(timeIntervalSince1970: TimeInterval(expiresAtMs) / 1000)
        let scopes = oauth["scopes"] as? [String] ?? []
        let subscriptionType = oauth["subscriptionType"] as? String
        let rateLimitTier = oauth["rateLimitTier"] as? String

        return OAuthCredentials(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            scopes: scopes,
            subscriptionType: subscriptionType,
            rateLimitTier: rateLimitTier
        )
    }

    /// Convert back to Claude Code Keychain JSON format
    func toClaudeCodeJSON() -> [String: Any] {
        var oauthData: [String: Any] = [
            "accessToken": accessToken,
            "refreshToken": refreshToken,
            "expiresAt": Int64(expiresAt.timeIntervalSince1970 * 1000),
            "scopes": scopes
        ]

        if let subscriptionType = subscriptionType {
            oauthData["subscriptionType"] = subscriptionType
        }

        if let rateLimitTier = rateLimitTier {
            oauthData["rateLimitTier"] = rateLimitTier
        }

        return ["claudeAiOauth": oauthData]
    }
}

// MARK: - Errors

enum OAuthCredentialsError: LocalizedError, Equatable {
    case missingOAuthData
    case missingAccessToken
    case missingRefreshToken
    case missingExpiresAt

    var errorDescription: String? {
        switch self {
        case .missingOAuthData:
            return "OAuth data not found in credentials"
        case .missingAccessToken:
            return "Access token not found"
        case .missingRefreshToken:
            return "Refresh token not found. Please re-login to Claude Code."
        case .missingExpiresAt:
            return "Token expiration not found"
        }
    }
}
