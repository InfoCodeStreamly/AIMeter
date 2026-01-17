import Foundation
@testable import AIMeter

enum OAuthCredentialsFixtures {
    
    // MARK: - Base Values (SSOT)
    // NOTE: OAuth access tokens use SessionKeyFixtures.validOAuthToken for consistency
    static let validAccessToken = SessionKeyFixtures.validOAuthToken
    static let validRefreshToken = "sk-ant-ort01-valid-refresh-token-for-testing"
    static let expiredAccessToken = "sk-ant-oat01-expired-token"
    
    static var futureExpiry: Date {
        Calendar.current.date(byAdding: .hour, value: 24, to: Date())!
    }
    
    static var soonExpiry: Date {
        Calendar.current.date(byAdding: .minute, value: 3, to: Date())!
    }
    
    static var pastExpiry: Date {
        Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
    }
    
    // MARK: - Complete Credentials
    static var valid: OAuthCredentials {
        OAuthCredentials(
            accessToken: validAccessToken,
            refreshToken: validRefreshToken,
            expiresAt: futureExpiry,
            scopes: ["user:read", "usage:read"],
            subscriptionType: "pro",
            rateLimitTier: "tier4"
        )
    }
    
    static var expiringSoon: OAuthCredentials {
        OAuthCredentials(
            accessToken: validAccessToken,
            refreshToken: validRefreshToken,
            expiresAt: soonExpiry,
            scopes: ["user:read"],
            subscriptionType: "pro",
            rateLimitTier: "tier4"
        )
    }
    
    static var expired: OAuthCredentials {
        OAuthCredentials(
            accessToken: expiredAccessToken,
            refreshToken: validRefreshToken,
            expiresAt: pastExpiry,
            scopes: ["user:read"],
            subscriptionType: "pro",
            rateLimitTier: "tier4"
        )
    }
    
    // MARK: - Parameterized Test Data
    static var expiryStates: [(name: String, credentials: OAuthCredentials, shouldRefresh: Bool)] {
        [
            ("valid", valid, false),
            ("expiringSoon", expiringSoon, true),
            ("expired", expired, true)
        ]
    }
}
