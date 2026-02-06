import Testing
@testable import AIMeterInfrastructure
import AIMeterDomain
import AIMeterApplication
import Foundation

/// Tests for APIEndpoints configuration
///
/// This suite tests the OAuth API endpoints configuration, including
/// base URL, usage endpoint URL construction, and header generation.
@Suite("APIEndpoints")
struct APIEndpointsTests {

    // MARK: - Base URL Tests

    @Test("baseURL is correct string")
    func baseURLIsCorrect() {
        // Arrange
        let expected = "https://api.anthropic.com/api/oauth"

        // Act
        let actual = APIEndpoints.baseURL

        // Assert
        #expect(actual == expected)
    }

    @Test("baseURL is valid URL")
    func baseURLIsValidURL() {
        // Act
        let url = URL(string: APIEndpoints.baseURL)

        // Assert
        #expect(url != nil)
        #expect(url?.scheme == "https")
        #expect(url?.host == "api.anthropic.com")
    }

    @Test("baseURL does not end with slash")
    func baseURLNoTrailingSlash() {
        // Act
        let baseURL = APIEndpoints.baseURL

        // Assert
        #expect(!baseURL.hasSuffix("/"))
    }

    // MARK: - Usage Endpoint Tests

    @Test("usage URL path is /api/oauth/usage")
    func usageURLPathIsCorrect() {
        // Act
        let usageURL = APIEndpoints.usage

        // Assert
        #expect(usageURL.absoluteString == "https://api.anthropic.com/api/oauth/usage")
        #expect(usageURL.path == "/api/oauth/usage")
    }

    @Test("usage URL is valid URL")
    func usageURLIsValid() {
        // Act
        let usageURL = APIEndpoints.usage

        // Assert
        #expect(usageURL.scheme == "https")
        #expect(usageURL.host == "api.anthropic.com")
    }

    // MARK: - Headers Tests

    @Test("headers contains Authorization with Bearer prefix and token")
    func headersContainsAuthorizationBearer() {
        // Arrange
        let token = "sk-ant-oat01-test-token-abc123"

        // Act
        let headers = APIEndpoints.headers(token: token)

        // Assert
        #expect(headers["Authorization"] == "Bearer \(token)")
        #expect(headers["Authorization"]?.hasPrefix("Bearer ") == true)
    }

    @Test("headers contains anthropic-beta key")
    func headersContainsAnthropicBeta() {
        // Arrange
        let token = "test-token"

        // Act
        let headers = APIEndpoints.headers(token: token)

        // Assert
        #expect(headers["anthropic-beta"] != nil)
        #expect(headers["anthropic-beta"] == "oauth-2025-04-20")
    }

    @Test("headers contains Content-Type application/json")
    func headersContainsContentTypeJSON() {
        // Arrange
        let token = "test-token"

        // Act
        let headers = APIEndpoints.headers(token: token)

        // Assert
        #expect(headers["Content-Type"] == "application/json")
    }

    @Test("headers contains Accept application/json")
    func headersContainsAcceptJSON() {
        // Arrange
        let token = "test-token"

        // Act
        let headers = APIEndpoints.headers(token: token)

        // Assert
        #expect(headers["Accept"] == "application/json")
    }

    @Test("headers contains User-Agent AIMeter/1.0")
    func headersContainsUserAgent() {
        // Arrange
        let token = "test-token"

        // Act
        let headers = APIEndpoints.headers(token: token)

        // Assert
        #expect(headers["User-Agent"] == "AIMeter/1.0")
        #expect(headers["User-Agent"]?.contains("AIMeter") == true)
    }

    @Test("headers contains all required keys")
    func headersContainsAllRequiredKeys() {
        // Arrange
        let token = "test-token"
        let requiredKeys = [
            "Authorization",
            "anthropic-beta",
            "Content-Type",
            "Accept",
            "User-Agent"
        ]

        // Act
        let headers = APIEndpoints.headers(token: token)

        // Assert
        for key in requiredKeys {
            #expect(headers[key] != nil, "Missing required header key: \(key)")
        }
    }

    @Test("headers with empty token still generates all keys")
    func headersWithEmptyToken() {
        // Arrange
        let token = ""

        // Act
        let headers = APIEndpoints.headers(token: token)

        // Assert
        #expect(headers["Authorization"] == "Bearer ")
        #expect(headers.count == 5)
    }

    @Test("headers values are not empty except for empty token")
    func headersValuesNotEmpty() {
        // Arrange
        let token = "test-token"

        // Act
        let headers = APIEndpoints.headers(token: token)

        // Assert
        for (key, value) in headers {
            if key != "Authorization" {
                #expect(!value.isEmpty, "Header \(key) should not be empty")
            }
        }
    }
}
