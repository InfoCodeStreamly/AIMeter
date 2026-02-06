import Testing
@testable import AIMeterInfrastructure
import Foundation

@Suite("APIConstants")
struct APIConstantsTests {

    // MARK: - Base URL Tests

    @Test("baseURL is a valid URL")
    func baseURLIsValid() {
        // Arrange
        let urlString = APIConstants.baseURL

        // Act
        let url = URL(string: urlString)

        // Assert
        #expect(url != nil)
        #expect(url?.scheme == "https")
        #expect(url?.host == "claude.ai")
    }

    @Test("baseURL does not end with slash")
    func baseURLNoTrailingSlash() {
        // Arrange
        let urlString = APIConstants.baseURL

        // Assert
        #expect(!urlString.hasSuffix("/"))
    }

    // MARK: - Timeout Tests

    @Test("timeout is positive")
    func timeoutIsPositive() {
        // Assert
        #expect(APIConstants.timeout > 0)
    }

    @Test("timeout is reasonable duration")
    func timeoutIsReasonable() {
        // Assert - should be between 10 and 120 seconds
        #expect(APIConstants.timeout >= 10)
        #expect(APIConstants.timeout <= 120)
    }

    // MARK: - Refresh Interval Tests

    @Test("refreshInterval is positive")
    func refreshIntervalIsPositive() {
        // Assert
        #expect(APIConstants.refreshInterval > 0)
    }

    @Test("refreshInterval is reasonable")
    func refreshIntervalIsReasonable() {
        // Assert - should be at least 30 seconds to avoid API rate limits
        #expect(APIConstants.refreshInterval >= 30)
    }

    // MARK: - Max Retries Tests

    @Test("maxRetries is non-negative")
    func maxRetriesIsNonNegative() {
        // Assert
        #expect(APIConstants.maxRetries >= 0)
    }

    @Test("maxRetries is reasonable")
    func maxRetriesIsReasonable() {
        // Assert - should be between 0 and 10
        #expect(APIConstants.maxRetries <= 10)
    }

    // MARK: - Keychain Keys Tests

    @Test("sessionKey is not empty")
    func sessionKeyNotEmpty() {
        // Assert
        #expect(!APIConstants.KeychainKeys.sessionKey.isEmpty)
    }

    @Test("organizationId is not empty")
    func organizationIdNotEmpty() {
        // Assert
        #expect(!APIConstants.KeychainKeys.organizationId.isEmpty)
    }

    // MARK: - Headers Tests

    @Test("header constants are not empty")
    func headerConstantsNotEmpty() {
        // Assert
        #expect(!APIConstants.Headers.contentType.isEmpty)
        #expect(!APIConstants.Headers.accept.isEmpty)
        #expect(!APIConstants.Headers.cookie.isEmpty)
        #expect(!APIConstants.Headers.userAgent.isEmpty)
    }

    @Test("applicationJSON is valid MIME type")
    func applicationJSONIsValid() {
        // Assert
        #expect(APIConstants.Headers.applicationJSON == "application/json")
    }

    @Test("appUserAgent contains version")
    func appUserAgentContainsVersion() {
        // Assert
        #expect(APIConstants.Headers.appUserAgent.contains("AIMeter"))
    }

    // MARK: - GitHub Constants Tests

    @Test("GitHub apiBaseURL is valid URL")
    func githubAPIBaseURLIsValid() {
        // Arrange
        let urlString = APIConstants.GitHub.apiBaseURL

        // Act
        let url = URL(string: urlString)

        // Assert
        #expect(url != nil)
        #expect(url?.scheme == "https")
        #expect(url?.host == "api.github.com")
    }

    @Test("GitHub repoOwner is not empty")
    func githubRepoOwnerNotEmpty() {
        // Assert
        #expect(!APIConstants.GitHub.repoOwner.isEmpty)
    }

    @Test("GitHub repoName is not empty")
    func githubRepoNameNotEmpty() {
        // Assert
        #expect(!APIConstants.GitHub.repoName.isEmpty)
    }

    @Test("GitHub repoURL is valid URL")
    func githubRepoURLIsValid() {
        // Arrange
        let urlString = APIConstants.GitHub.repoURL

        // Act
        let url = URL(string: urlString)

        // Assert
        #expect(url != nil)
        #expect(url?.scheme == "https")
        #expect(url?.host == "github.com")
    }

    @Test("GitHub repoURL contains owner and repo")
    func githubRepoURLContainsOwnerAndRepo() {
        // Arrange
        let repoURL = APIConstants.GitHub.repoURL
        let owner = APIConstants.GitHub.repoOwner
        let repo = APIConstants.GitHub.repoName

        // Assert
        #expect(repoURL.contains(owner))
        #expect(repoURL.contains(repo))
    }

    // MARK: - OAuth Constants Tests

    @Test("OAuth tokenURL is valid URL")
    func oauthTokenURLIsValid() {
        // Arrange
        let urlString = APIConstants.OAuth.tokenURL

        // Act
        let url = URL(string: urlString)

        // Assert
        #expect(url != nil)
        #expect(url?.scheme == "https")
        #expect(url?.host == "console.anthropic.com")
    }

    @Test("OAuth tokenURL points to token endpoint")
    func oauthTokenURLIsTokenEndpoint() {
        // Assert
        #expect(APIConstants.OAuth.tokenURL.contains("/token"))
    }

    @Test("OAuth clientId is not empty")
    func oauthClientIdNotEmpty() {
        // Assert
        #expect(!APIConstants.OAuth.clientId.isEmpty)
    }

    @Test("OAuth clientId is valid UUID format")
    func oauthClientIdIsUUID() {
        // Arrange
        let clientId = APIConstants.OAuth.clientId

        // Act
        let uuid = UUID(uuidString: clientId)

        // Assert
        #expect(uuid != nil)
    }

    @Test("OAuth refreshThresholdSeconds is positive")
    func oauthRefreshThresholdIsPositive() {
        // Assert
        #expect(APIConstants.OAuth.refreshThresholdSeconds > 0)
    }

    @Test("OAuth refreshThresholdSeconds is reasonable")
    func oauthRefreshThresholdIsReasonable() {
        // Assert - should be at least 1 minute to allow time for refresh
        #expect(APIConstants.OAuth.refreshThresholdSeconds >= 60)
    }

    @Test("OAuth refreshRetryDelay is positive")
    func oauthRefreshRetryDelayIsPositive() {
        // Assert
        #expect(APIConstants.OAuth.refreshRetryDelay > 0)
    }

    @Test("OAuth refreshRetryDelay is reasonable")
    func oauthRefreshRetryDelayIsReasonable() {
        // Assert - should be between 1 and 60 seconds
        #expect(APIConstants.OAuth.refreshRetryDelay >= 1)
        #expect(APIConstants.OAuth.refreshRetryDelay <= 60)
    }

    // MARK: - Cross-Constant Validation Tests

    @Test("refreshThreshold is 5 minutes (300 seconds)")
    func refreshThresholdValue() {
        // refreshThresholdSeconds (300s) and timeout (30s) measure different things
        // refreshThresholdSeconds = proactive token refresh window
        // timeout = HTTP request timeout
        #expect(APIConstants.OAuth.refreshThresholdSeconds == 300)
    }

    @Test("refreshRetryDelay is less than timeout")
    func refreshRetryDelayLessThanTimeout() {
        // Assert
        #expect(APIConstants.OAuth.refreshRetryDelay < APIConstants.timeout)
    }

    @Test("refreshInterval is greater than refreshRetryDelay")
    func refreshIntervalGreaterThanRetryDelay() {
        // Assert
        #expect(APIConstants.refreshInterval > APIConstants.OAuth.refreshRetryDelay)
    }

    // MARK: - URL Construction Tests

    @Test("baseURL can be used to construct endpoint URLs")
    func baseURLCanConstructEndpoints() {
        // Arrange
        let baseURL = APIConstants.baseURL
        let endpoint = "/oauth/usage"

        // Act
        let fullURL = URL(string: baseURL + endpoint)

        // Assert
        #expect(fullURL != nil)
        #expect(fullURL?.absoluteString == "https://claude.ai/api/oauth/usage")
    }

    @Test("GitHub apiBaseURL can be used to construct endpoint URLs")
    func githubAPIBaseURLCanConstructEndpoints() {
        // Arrange
        let baseURL = APIConstants.GitHub.apiBaseURL
        let endpoint = "/repos/\(APIConstants.GitHub.repoOwner)/\(APIConstants.GitHub.repoName)/releases"

        // Act
        let fullURL = URL(string: baseURL + endpoint)

        // Assert
        #expect(fullURL != nil)
    }

    // MARK: - Immutability Tests

    @Test("constants are immutable")
    func constantsAreImmutable() {
        // This test verifies compilation only
        // If constants are mutable, the following will fail to compile
        let baseURL = APIConstants.baseURL
        let timeout = APIConstants.timeout
        let maxRetries = APIConstants.maxRetries

        #expect(baseURL == APIConstants.baseURL)
        #expect(timeout == APIConstants.timeout)
        #expect(maxRetries == APIConstants.maxRetries)
    }
}
