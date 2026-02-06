import Testing
import Foundation
@testable import AIMeterDomain

@Suite("OAuthCredentials")
struct OAuthCredentialsTests {

    // MARK: - isExpired Tests

    @Test("isExpired returns true for past expiration")
    func isExpiredPast() {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let credentials = OAuthCredentials(
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresAt: pastDate,
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )
        #expect(credentials.isExpired == true)
    }

    @Test("isExpired returns false for future expiration")
    func isExpiredFuture() {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let credentials = OAuthCredentials(
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresAt: futureDate,
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )
        #expect(credentials.isExpired == false)
    }

    @Test("isExpired returns true for current time")
    func isExpiredNow() {
        let credentials = OAuthCredentials(
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresAt: Date(),
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )
        #expect(credentials.isExpired == true)
    }

    // MARK: - shouldRefresh Tests

    @Test("shouldRefresh returns true when less than 5 minutes remaining")
    func shouldRefreshTrue() {
        let fourMinutes = Date().addingTimeInterval(4 * 60)
        let credentials = OAuthCredentials(
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresAt: fourMinutes,
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )
        #expect(credentials.shouldRefresh == true)
    }

    @Test("shouldRefresh returns false when more than 5 minutes remaining")
    func shouldRefreshFalse() {
        let sixMinutes = Date().addingTimeInterval(6 * 60)
        let credentials = OAuthCredentials(
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresAt: sixMinutes,
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )
        #expect(credentials.shouldRefresh == false)
    }

    @Test("shouldRefresh returns true at exactly 5 minutes")
    func shouldRefreshBoundary() {
        let fiveMinutes = Date().addingTimeInterval(5 * 60)
        let credentials = OAuthCredentials(
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresAt: fiveMinutes,
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )
        #expect(credentials.shouldRefresh == true)
    }

    @Test("shouldRefresh returns true for expired tokens")
    func shouldRefreshExpired() {
        let pastDate = Date().addingTimeInterval(-3600)
        let credentials = OAuthCredentials(
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresAt: pastDate,
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )
        #expect(credentials.shouldRefresh == true)
    }

    // MARK: - toSessionKey Tests

    @Test("toSessionKey creates valid session key from access token")
    func toSessionKeyValid() throws {
        let credentials = OAuthCredentials(
            accessToken: "sk-ant-oat01-1234567890abcdefghij",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )
        let sessionKey = try credentials.toSessionKey()
        #expect(sessionKey.value == "sk-ant-oat01-1234567890abcdefghij")
    }

    @Test("toSessionKey throws for short access token")
    func toSessionKeyShort() {
        let credentials = OAuthCredentials(
            accessToken: "short",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )
        #expect(throws: DomainError.self) {
            _ = try credentials.toSessionKey()
        }
    }

    @Test("toSessionKey throws for empty access token")
    func toSessionKeyEmpty() {
        let credentials = OAuthCredentials(
            accessToken: "",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )
        #expect(throws: DomainError.self) {
            _ = try credentials.toSessionKey()
        }
    }

    // MARK: - fromClaudeCodeJSON Tests

    @Test("fromClaudeCodeJSON parses valid JSON")
    func fromClaudeCodeJSONValid() throws {
        let expiresAtMs = Int64(Date().addingTimeInterval(3600).timeIntervalSince1970 * 1000)
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "sk-ant-oat01-1234567890abcdefghij",
                "refreshToken": "refresh_token_value",
                "expiresAt": expiresAtMs,
                "scopes": ["usage:read", "admin:write"]
            ] as [String: Any]
        ]
        let credentials = try OAuthCredentials.fromClaudeCodeJSON(json)

        #expect(credentials.accessToken == "sk-ant-oat01-1234567890abcdefghij")
        #expect(credentials.refreshToken == "refresh_token_value")
        #expect(credentials.scopes == ["usage:read", "admin:write"])
    }

    @Test("fromClaudeCodeJSON handles missing scopes as empty")
    func fromClaudeCodeJSONMissingScopes() throws {
        let expiresAtMs = Int64(Date().addingTimeInterval(3600).timeIntervalSince1970 * 1000)
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "sk-ant-oat01-1234567890abcdefghij",
                "refreshToken": "refresh_token_value",
                "expiresAt": expiresAtMs
            ] as [String: Any]
        ]
        let credentials = try OAuthCredentials.fromClaudeCodeJSON(json)
        #expect(credentials.scopes.isEmpty)
    }

    @Test("fromClaudeCodeJSON throws for missing claudeAiOauth key")
    func fromClaudeCodeJSONMissingOAuth() {
        let json: [String: Any] = [
            "someOtherKey": "value"
        ]
        #expect(throws: OAuthCredentialsError.missingOAuthData) {
            _ = try OAuthCredentials.fromClaudeCodeJSON(json)
        }
    }

    @Test("fromClaudeCodeJSON throws for missing accessToken")
    func fromClaudeCodeJSONMissingAccessToken() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "refreshToken": "refresh_token_value",
                "expiresAt": Int64(Date().timeIntervalSince1970 * 1000)
            ] as [String: Any]
        ]
        #expect(throws: OAuthCredentialsError.missingAccessToken) {
            _ = try OAuthCredentials.fromClaudeCodeJSON(json)
        }
    }

    @Test("fromClaudeCodeJSON throws for missing refreshToken")
    func fromClaudeCodeJSONMissingRefreshToken() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "sk-ant-oat01-1234567890abcdefghij",
                "expiresAt": Int64(Date().timeIntervalSince1970 * 1000)
            ] as [String: Any]
        ]
        #expect(throws: OAuthCredentialsError.missingRefreshToken) {
            _ = try OAuthCredentials.fromClaudeCodeJSON(json)
        }
    }

    @Test("fromClaudeCodeJSON throws for missing expiresAt")
    func fromClaudeCodeJSONMissingExpiresAt() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "sk-ant-oat01-1234567890abcdefghij",
                "refreshToken": "refresh_token_value"
            ] as [String: Any]
        ]
        #expect(throws: OAuthCredentialsError.missingExpiresAt) {
            _ = try OAuthCredentials.fromClaudeCodeJSON(json)
        }
    }

    @Test("fromClaudeCodeJSON throws for empty accessToken")
    func fromClaudeCodeJSONEmptyAccessToken() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "",
                "refreshToken": "refresh_token_value",
                "expiresAt": Int64(Date().timeIntervalSince1970 * 1000)
            ] as [String: Any]
        ]
        #expect(throws: OAuthCredentialsError.missingAccessToken) {
            _ = try OAuthCredentials.fromClaudeCodeJSON(json)
        }
    }

    @Test("fromClaudeCodeJSON throws for empty refreshToken")
    func fromClaudeCodeJSONEmptyRefreshToken() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "sk-ant-oat01-1234567890abcdefghij",
                "refreshToken": "",
                "expiresAt": Int64(Date().timeIntervalSince1970 * 1000)
            ] as [String: Any]
        ]
        #expect(throws: OAuthCredentialsError.missingRefreshToken) {
            _ = try OAuthCredentials.fromClaudeCodeJSON(json)
        }
    }

    @Test("fromClaudeCodeJSON parses subscriptionType and rateLimitTier")
    func fromClaudeCodeJSONWithOptionalFields() throws {
        let expiresAtMs = Int64(Date().addingTimeInterval(3600).timeIntervalSince1970 * 1000)
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "sk-ant-oat01-1234567890abcdefghij",
                "refreshToken": "refresh_token_value",
                "expiresAt": expiresAtMs,
                "scopes": ["usage:read"],
                "subscriptionType": "pro",
                "rateLimitTier": "tier1"
            ] as [String: Any]
        ]
        let credentials = try OAuthCredentials.fromClaudeCodeJSON(json)
        #expect(credentials.subscriptionType == "pro")
        #expect(credentials.rateLimitTier == "tier1")
    }

    // MARK: - Equatable Tests

    @Test("equatable compares all fields")
    func equatable() {
        let date = Date()
        let credentials1 = OAuthCredentials(
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresAt: date,
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )
        let credentials2 = OAuthCredentials(
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresAt: date,
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )
        let credentials3 = OAuthCredentials(
            accessToken: "different_token",
            refreshToken: "refresh_token",
            expiresAt: date,
            scopes: ["usage:read"],
            subscriptionType: nil,
            rateLimitTier: nil
        )

        #expect(credentials1 == credentials2)
        #expect(credentials1 != credentials3)
    }

    // MARK: - Codable Tests

    @Test("codable encodes and decodes correctly")
    func codable() throws {
        let original = OAuthCredentials(
            accessToken: "sk-ant-oat01-1234567890abcdefghij",
            refreshToken: "refresh_token_value",
            expiresAt: Date(),
            scopes: ["usage:read", "admin:write"],
            subscriptionType: "pro",
            rateLimitTier: "tier1"
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OAuthCredentials.self, from: encoded)

        #expect(decoded.accessToken == original.accessToken)
        #expect(decoded.refreshToken == original.refreshToken)
        #expect(decoded.scopes == original.scopes)
    }
}
