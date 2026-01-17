import Testing
import Foundation
@testable import AIMeter

@Suite("OAuthCredentials", .tags(.domain, .oauth, .critical))
struct OAuthCredentialsTests {

    // MARK: - isExpired Tests

    @Test("isExpired returns false when expiration is in the future")
    func isExpiredFalseWhenFuture() {
        let credentials = OAuthCredentialsBuilder()
            .withExpiresAt(Date().addingTimeInterval(3600))  // 1 hour from now
            .build()

        #expect(!credentials.isExpired, "Should not be expired when expiration is in the future")
    }

    @Test("isExpired returns true when expiration is in the past")
    func isExpiredTrueWhenPast() {
        let credentials = OAuthCredentialsBuilder()
            .withExpiresAt(Date().addingTimeInterval(-60))  // 1 minute ago
            .build()

        #expect(credentials.isExpired, "Should be expired when expiration is in the past")
    }

    @Test("isExpired returns true when expiration is exactly now")
    func isExpiredTrueWhenExactlyNow() {
        let credentials = OAuthCredentialsBuilder()
            .withExpiresAt(Date())  // Now
            .build()

        #expect(credentials.isExpired, "Should be expired when expiration is exactly now")
    }

    // MARK: - shouldRefresh Tests

    @Test("shouldRefresh returns false when more than 5 minutes remaining")
    func shouldRefreshFalseWhenMoreThan5Minutes() {
        let credentials = OAuthCredentialsBuilder()
            .withExpiresAt(Date().addingTimeInterval(10 * 60))  // 10 minutes from now
            .build()

        #expect(!credentials.shouldRefresh, "Should not need refresh with more than 5 minutes remaining")
    }

    @Test("shouldRefresh returns true when less than 5 minutes remaining")
    func shouldRefreshTrueWhenLessThan5Minutes() {
        let credentials = OAuthCredentialsBuilder()
            .withExpiresAt(Date().addingTimeInterval(4 * 60))  // 4 minutes from now
            .build()

        #expect(credentials.shouldRefresh, "Should need refresh with less than 5 minutes remaining")
    }

    @Test("shouldRefresh returns true when expired")
    func shouldRefreshTrueWhenExpired() {
        let credentials = OAuthCredentialsBuilder()
            .expired()
            .build()

        #expect(credentials.shouldRefresh, "Should need refresh when expired")
    }

    @Test("shouldRefresh returns true when exactly 5 minutes remaining")
    func shouldRefreshTrueWhenExactly5Minutes() {
        let credentials = OAuthCredentialsBuilder()
            .withExpiresAt(Date().addingTimeInterval(5 * 60))  // Exactly 5 minutes
            .build()

        #expect(credentials.shouldRefresh, "Should need refresh when exactly 5 minutes remaining")
    }

    // MARK: - timeUntilExpiry Tests

    @Test("timeUntilExpiry returns positive value for future expiration")
    func timeUntilExpiryPositiveForFuture() {
        let credentials = OAuthCredentialsBuilder()
            .withExpiresAt(Date().addingTimeInterval(3600))  // 1 hour from now
            .build()

        #expect(credentials.timeUntilExpiry > 0, "Should return positive time until expiry")
        #expect(credentials.timeUntilExpiry <= 3600, "Should be approximately 1 hour")
    }

    @Test("timeUntilExpiry returns negative value for past expiration")
    func timeUntilExpiryNegativeForPast() {
        let credentials = OAuthCredentialsBuilder()
            .withExpiresAt(Date().addingTimeInterval(-60))  // 1 minute ago
            .build()

        #expect(credentials.timeUntilExpiry < 0, "Should return negative time for expired credentials")
    }

    // MARK: - toSessionKey Tests

    @Test("toSessionKey creates SessionKey from valid access token")
    func toSessionKeyCreatesSessionKey() throws {
        let credentials = OAuthCredentialsBuilder()
            .withAccessToken(SessionKeyFixtures.validRawKey)
            .build()

        let sessionKey = try credentials.toSessionKey()
        #expect(sessionKey.value == SessionKeyFixtures.validRawKey, "Should create SessionKey with same token")
    }

    @Test("toSessionKey throws for invalid access token format")
    func toSessionKeyThrowsForInvalidToken() {
        let credentials = OAuthCredentialsBuilder()
            .withAccessToken("invalid-token")
            .build()

        #expect(throws: DomainError.self) {
            _ = try credentials.toSessionKey()
        }
    }

    // MARK: - withRefreshedTokens Tests

    @Test("withRefreshedTokens creates new credentials with updated tokens")
    func withRefreshedTokensCreatesNewCredentials() {
        let original = OAuthCredentialsFixtures.valid

        let refreshed = original.withRefreshedTokens(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            expiresIn: 86400
        )

        #expect(refreshed.accessToken == "new-access-token", "Access token should be updated")
        #expect(refreshed.refreshToken == "new-refresh-token", "Refresh token should be updated")
        #expect(refreshed.scopes == original.scopes, "Scopes should be preserved")
        #expect(refreshed.subscriptionType == original.subscriptionType, "Subscription type should be preserved")
        #expect(refreshed.rateLimitTier == original.rateLimitTier, "Rate limit tier should be preserved")
    }

    @Test("withRefreshedTokens sets correct expiration time")
    func withRefreshedTokensSetsExpirationTime() {
        let original = OAuthCredentialsFixtures.expired
        let expiresIn = 3600  // 1 hour

        let beforeRefresh = Date()
        let refreshed = original.withRefreshedTokens(
            accessToken: "new-token",
            refreshToken: "new-refresh",
            expiresIn: expiresIn
        )
        let afterRefresh = Date()

        // Expiration should be approximately 1 hour from now
        let expectedMin = beforeRefresh.addingTimeInterval(TimeInterval(expiresIn))
        let expectedMax = afterRefresh.addingTimeInterval(TimeInterval(expiresIn))

        #expect(refreshed.expiresAt >= expectedMin, "Expiration should be at least expiresIn seconds from start")
        #expect(refreshed.expiresAt <= expectedMax, "Expiration should be at most expiresIn seconds from end")
    }

    // MARK: - fromClaudeCodeJSON Tests

    @Test("fromClaudeCodeJSON decodes valid JSON successfully")
    func fromClaudeCodeJSONDecodesValid() throws {
        let expiresAtMs = Int64(Date().addingTimeInterval(3600).timeIntervalSince1970 * 1000)
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "test-access-token",
                "refreshToken": "test-refresh-token",
                "expiresAt": expiresAtMs,
                "scopes": ["user:read", "usage:read"],
                "subscriptionType": "pro",
                "rateLimitTier": "tier4"
            ]
        ]

        let credentials = try OAuthCredentials.fromClaudeCodeJSON(json)

        #expect(credentials.accessToken == "test-access-token")
        #expect(credentials.refreshToken == "test-refresh-token")
        #expect(credentials.scopes == ["user:read", "usage:read"])
        #expect(credentials.subscriptionType == "pro")
        #expect(credentials.rateLimitTier == "tier4")
    }

    @Test("fromClaudeCodeJSON throws for missing claudeAiOauth key")
    func fromClaudeCodeJSONThrowsForMissingOAuth() {
        let json: [String: Any] = ["otherKey": "value"]

        #expect(throws: OAuthCredentialsError.missingOAuthData) {
            _ = try OAuthCredentials.fromClaudeCodeJSON(json)
        }
    }

    @Test("fromClaudeCodeJSON throws for missing access token")
    func fromClaudeCodeJSONThrowsForMissingAccessToken() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "refreshToken": "refresh",
                "expiresAt": Int64(Date().timeIntervalSince1970 * 1000)
            ]
        ]

        #expect(throws: OAuthCredentialsError.missingAccessToken) {
            _ = try OAuthCredentials.fromClaudeCodeJSON(json)
        }
    }

    @Test("fromClaudeCodeJSON throws for empty access token")
    func fromClaudeCodeJSONThrowsForEmptyAccessToken() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "",
                "refreshToken": "refresh",
                "expiresAt": Int64(Date().timeIntervalSince1970 * 1000)
            ]
        ]

        #expect(throws: OAuthCredentialsError.missingAccessToken) {
            _ = try OAuthCredentials.fromClaudeCodeJSON(json)
        }
    }

    @Test("fromClaudeCodeJSON throws for missing refresh token")
    func fromClaudeCodeJSONThrowsForMissingRefreshToken() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "access",
                "expiresAt": Int64(Date().timeIntervalSince1970 * 1000)
            ]
        ]

        #expect(throws: OAuthCredentialsError.missingRefreshToken) {
            _ = try OAuthCredentials.fromClaudeCodeJSON(json)
        }
    }

    @Test("fromClaudeCodeJSON throws for missing expiresAt")
    func fromClaudeCodeJSONThrowsForMissingExpiresAt() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "access",
                "refreshToken": "refresh"
            ]
        ]

        #expect(throws: OAuthCredentialsError.missingExpiresAt) {
            _ = try OAuthCredentials.fromClaudeCodeJSON(json)
        }
    }

    @Test("fromClaudeCodeJSON handles optional fields as nil")
    func fromClaudeCodeJSONHandlesOptionalFieldsAsNil() throws {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "access",
                "refreshToken": "refresh",
                "expiresAt": Int64(Date().timeIntervalSince1970 * 1000)
            ]
        ]

        let credentials = try OAuthCredentials.fromClaudeCodeJSON(json)

        #expect(credentials.scopes.isEmpty, "Scopes should default to empty")
        #expect(credentials.subscriptionType == nil, "SubscriptionType should be nil when missing")
        #expect(credentials.rateLimitTier == nil, "RateLimitTier should be nil when missing")
    }

    // MARK: - toClaudeCodeJSON Tests

    @Test("toClaudeCodeJSON produces valid JSON structure")
    func toClaudeCodeJSONProducesValidStructure() {
        let credentials = OAuthCredentialsFixtures.valid
        let json = credentials.toClaudeCodeJSON()

        #expect(json["claudeAiOauth"] != nil, "Should have claudeAiOauth key")

        let oauth = json["claudeAiOauth"] as? [String: Any]
        #expect(oauth?["accessToken"] as? String == credentials.accessToken)
        #expect(oauth?["refreshToken"] as? String == credentials.refreshToken)
        #expect(oauth?["scopes"] as? [String] == credentials.scopes)
    }

    @Test("toClaudeCodeJSON roundtrip preserves data")
    func toClaudeCodeJSONRoundtripPreservesData() throws {
        let original = OAuthCredentialsFixtures.valid
        let json = original.toClaudeCodeJSON()
        let decoded = try OAuthCredentials.fromClaudeCodeJSON(json)

        #expect(decoded.accessToken == original.accessToken)
        #expect(decoded.refreshToken == original.refreshToken)
        #expect(decoded.scopes == original.scopes)
        #expect(decoded.subscriptionType == original.subscriptionType)
        #expect(decoded.rateLimitTier == original.rateLimitTier)
        // Note: expiresAt might have small precision differences due to millisecond conversion
    }

    // MARK: - Equatable Tests

    @Test("Equatable returns true for identical credentials")
    func equatableReturnsTrueForIdentical() {
        // Use fixed date for both to ensure equality
        let fixedDate = Date(timeIntervalSince1970: 2000000000)  // Fixed timestamp
        let credentials1 = OAuthCredentialsBuilder().withExpiresAt(fixedDate).build()
        let credentials2 = OAuthCredentialsBuilder().withExpiresAt(fixedDate).build()

        #expect(credentials1 == credentials2, "Identical credentials should be equal")
    }

    @Test("Equatable returns false for different access tokens")
    func equatableReturnsFalseForDifferentTokens() {
        let credentials1 = OAuthCredentialsBuilder().withAccessToken("token1").build()
        let credentials2 = OAuthCredentialsBuilder().withAccessToken("token2").build()

        #expect(credentials1 != credentials2, "Different access tokens should not be equal")
    }
}
