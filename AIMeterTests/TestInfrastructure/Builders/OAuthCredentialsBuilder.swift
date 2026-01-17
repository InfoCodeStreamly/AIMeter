import Foundation
@testable import AIMeter

final class OAuthCredentialsBuilder {
    
    // MARK: - Properties
    private var accessToken: String = OAuthCredentialsFixtures.validAccessToken
    private var refreshToken: String = OAuthCredentialsFixtures.validRefreshToken
    private var expiresAt: Date = OAuthCredentialsFixtures.futureExpiry
    private var scopes: [String] = ["user:read", "usage:read"]
    private var subscriptionType: String = "pro"
    private var rateLimitTier: String = "tier4"
    
    // MARK: - Builder Methods
    func withAccessToken(_ token: String) -> Self {
        accessToken = token
        return self
    }
    
    func withRefreshToken(_ token: String) -> Self {
        refreshToken = token
        return self
    }
    
    func withExpiresAt(_ date: Date) -> Self {
        expiresAt = date
        return self
    }
    
    func expiringSoon() -> Self {
        expiresAt = OAuthCredentialsFixtures.soonExpiry
        return self
    }
    
    func expired() -> Self {
        expiresAt = OAuthCredentialsFixtures.pastExpiry
        return self
    }
    
    func withScopes(_ scopes: [String]) -> Self {
        self.scopes = scopes
        return self
    }
    
    func withSubscriptionType(_ type: String) -> Self {
        subscriptionType = type
        return self
    }
    
    func withRateLimitTier(_ tier: String) -> Self {
        rateLimitTier = tier
        return self
    }
    
    // MARK: - Build
    func build() -> OAuthCredentials {
        OAuthCredentials(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            scopes: scopes,
            subscriptionType: subscriptionType,
            rateLimitTier: rateLimitTier
        )
    }
}
