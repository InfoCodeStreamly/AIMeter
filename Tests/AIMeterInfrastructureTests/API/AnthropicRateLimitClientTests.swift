import Testing
import Foundation
@testable import AIMeterInfrastructure
import AIMeterDomain

/// Tests for AnthropicRateLimitClient header parsing.
///
/// Exercises the case-insensitive header lookup introduced in the change from
/// `allHeaderFields` dictionary to `value(forHTTPHeaderField:)`, verifying that
/// integer values are parsed correctly and missing headers return 0.
///
/// Tests are serialized because they share static state on MockRateLimitURLProtocol.
@Suite("AnthropicRateLimitClient Tests", .serialized)
struct AnthropicRateLimitClientTests {

    // MARK: - intHeader via fetchRateLimits

    @Test("fetchRateLimits parses integer rate-limit headers from HTTP 200 response")
    func fetchRateLimits_parsesIntegerHeaders_onHTTP200() async throws {
        // Arrange
        let headers: [String: String] = [
            "anthropic-ratelimit-requests-limit": "1000",
            "anthropic-ratelimit-requests-remaining": "850",
            "anthropic-ratelimit-input-tokens-limit": "450000",
            "anthropic-ratelimit-input-tokens-remaining": "425000",
            "anthropic-ratelimit-output-tokens-limit": "90000",
            "anthropic-ratelimit-output-tokens-remaining": "85000",
        ]
        let session = makeMockSession(statusCode: 200, headers: headers)
        let client = AnthropicRateLimitClient(session: session)

        // Act
        let entity = try await client.fetchRateLimits(apiKey: "sk-ant-api03-testkey1234567890abcdef")

        // Assert
        #expect(entity.requestsLimit == 1000)
        #expect(entity.requestsRemaining == 850)
        #expect(entity.inputTokensLimit == 450_000)
        #expect(entity.inputTokensRemaining == 425_000)
        #expect(entity.outputTokensLimit == 90_000)
        #expect(entity.outputTokensRemaining == 85_000)
    }

    @Test("fetchRateLimits parses integer rate-limit headers from HTTP 429 response")
    func fetchRateLimits_parsesIntegerHeaders_onHTTP429() async throws {
        // Rate limit headers are returned even on 429 — this is a key contract.
        let headers: [String: String] = [
            "anthropic-ratelimit-requests-limit": "500",
            "anthropic-ratelimit-requests-remaining": "0",
            "anthropic-ratelimit-input-tokens-limit": "100000",
            "anthropic-ratelimit-input-tokens-remaining": "0",
            "anthropic-ratelimit-output-tokens-limit": "20000",
            "anthropic-ratelimit-output-tokens-remaining": "0",
        ]
        let session = makeMockSession(statusCode: 429, headers: headers)
        let client = AnthropicRateLimitClient(session: session)

        // Act
        let entity = try await client.fetchRateLimits(apiKey: "sk-ant-api03-testkey1234567890abcdef")

        // Assert
        #expect(entity.requestsLimit == 500)
        #expect(entity.requestsRemaining == 0)
        #expect(entity.inputTokensLimit == 100_000)
        #expect(entity.inputTokensRemaining == 0)
    }

    @Test("fetchRateLimits returns zero for missing rate-limit headers")
    func fetchRateLimits_returnZero_whenHeadersMissing() async throws {
        // Arrange — no rate-limit headers at all
        let session = makeMockSession(statusCode: 200, headers: [:])
        let client = AnthropicRateLimitClient(session: session)

        // Act
        let entity = try await client.fetchRateLimits(apiKey: "sk-ant-api03-testkey1234567890abcdef")

        // Assert
        #expect(entity.requestsLimit == 0)
        #expect(entity.requestsRemaining == 0)
        #expect(entity.inputTokensLimit == 0)
        #expect(entity.inputTokensRemaining == 0)
        #expect(entity.outputTokensLimit == 0)
        #expect(entity.outputTokensRemaining == 0)
    }

    @Test("fetchRateLimits returns zero for non-numeric header values")
    func fetchRateLimits_returnZero_whenHeaderValueIsNonNumeric() async throws {
        // Arrange — malformed header values
        let headers: [String: String] = [
            "anthropic-ratelimit-requests-limit": "not-a-number",
            "anthropic-ratelimit-requests-remaining": "",
            "anthropic-ratelimit-input-tokens-limit": "1000",
            "anthropic-ratelimit-input-tokens-remaining": "500",
            "anthropic-ratelimit-output-tokens-limit": "abc",
            "anthropic-ratelimit-output-tokens-remaining": "200",
        ]
        let session = makeMockSession(statusCode: 200, headers: headers)
        let client = AnthropicRateLimitClient(session: session)

        // Act
        let entity = try await client.fetchRateLimits(apiKey: "sk-ant-api03-testkey1234567890abcdef")

        // Assert — non-numeric and empty headers fall back to 0
        #expect(entity.requestsLimit == 0)
        #expect(entity.requestsRemaining == 0)
        // Valid numeric headers are parsed correctly
        #expect(entity.inputTokensLimit == 1000)
        #expect(entity.inputTokensRemaining == 500)
        // Non-numeric output tokens header also returns 0
        #expect(entity.outputTokensLimit == 0)
        #expect(entity.outputTokensRemaining == 200)
    }

    @Test("fetchRateLimits performs case-insensitive header lookup")
    func fetchRateLimits_caseInsensitiveLookup() async throws {
        // Arrange — headers with uppercase/mixed-case names.
        // value(forHTTPHeaderField:) on HTTPURLResponse is case-insensitive per RFC 7230,
        // so these must be read correctly regardless of case sent by server.
        let headers: [String: String] = [
            "Anthropic-Ratelimit-Requests-Limit": "750",
            "ANTHROPIC-RATELIMIT-REQUESTS-REMAINING": "600",
            "anthropic-ratelimit-input-tokens-limit": "300000",
            "anthropic-ratelimit-input-tokens-remaining": "250000",
            "anthropic-ratelimit-output-tokens-limit": "60000",
            "anthropic-ratelimit-output-tokens-remaining": "55000",
        ]
        let session = makeMockSession(statusCode: 200, headers: headers)
        let client = AnthropicRateLimitClient(session: session)

        // Act
        let entity = try await client.fetchRateLimits(apiKey: "sk-ant-api03-testkey1234567890abcdef")

        // Assert — case-insensitive lookup must find these values
        #expect(entity.requestsLimit == 750)
        #expect(entity.requestsRemaining == 600)
        #expect(entity.inputTokensLimit == 300_000)
        #expect(entity.inputTokensRemaining == 250_000)
        #expect(entity.outputTokensLimit == 60_000)
        #expect(entity.outputTokensRemaining == 55_000)
    }

    @Test("fetchRateLimits throws unauthorized on HTTP 401")
    func fetchRateLimits_throwsUnauthorized_onHTTP401() async throws {
        // Arrange
        let session = makeMockSession(statusCode: 401, headers: [:])
        let client = AnthropicRateLimitClient(session: session)

        // Act & Assert
        await #expect(throws: (any Error).self) {
            try await client.fetchRateLimits(apiKey: "sk-ant-api03-testkey1234567890abcdef")
        }
    }

    @Test("fetchRateLimits throws unauthorized on HTTP 403")
    func fetchRateLimits_throwsUnauthorized_onHTTP403() async throws {
        // Arrange
        let session = makeMockSession(statusCode: 403, headers: [:])
        let client = AnthropicRateLimitClient(session: session)

        // Act & Assert
        await #expect(throws: (any Error).self) {
            try await client.fetchRateLimits(apiKey: "sk-ant-api03-testkey1234567890abcdef")
        }
    }

    @Test("fetchRateLimits throws requestFailed on HTTP 500")
    func fetchRateLimits_throwsRequestFailed_onHTTP500() async throws {
        // Arrange
        let session = makeMockSession(statusCode: 500, headers: [:])
        let client = AnthropicRateLimitClient(session: session)

        // Act & Assert
        await #expect(throws: (any Error).self) {
            try await client.fetchRateLimits(apiKey: "sk-ant-api03-testkey1234567890abcdef")
        }
    }

    @Test("fetchRateLimits parses reset date header when present")
    func fetchRateLimits_parsesResetDateHeader() async throws {
        // Arrange
        let resetDateString = "2026-03-17T12:00:00Z"
        let headers: [String: String] = [
            "anthropic-ratelimit-requests-limit": "1000",
            "anthropic-ratelimit-requests-remaining": "900",
            "anthropic-ratelimit-requests-reset": resetDateString,
            "anthropic-ratelimit-input-tokens-limit": "1",
            "anthropic-ratelimit-input-tokens-remaining": "1",
            "anthropic-ratelimit-output-tokens-limit": "1",
            "anthropic-ratelimit-output-tokens-remaining": "1",
        ]
        let session = makeMockSession(statusCode: 200, headers: headers)
        let client = AnthropicRateLimitClient(session: session)

        // Act
        let entity = try await client.fetchRateLimits(apiKey: "sk-ant-api03-testkey1234567890abcdef")

        // Assert — reset date must be parsed from ISO8601 string
        #expect(entity.requestsResetTime != nil)
    }

    @Test("fetchRateLimits returns nil reset date when header is absent")
    func fetchRateLimits_returnsNilResetDate_whenHeaderAbsent() async throws {
        // Arrange — no reset date headers
        let headers: [String: String] = [
            "anthropic-ratelimit-requests-limit": "1000",
            "anthropic-ratelimit-requests-remaining": "900",
            "anthropic-ratelimit-input-tokens-limit": "1",
            "anthropic-ratelimit-input-tokens-remaining": "1",
            "anthropic-ratelimit-output-tokens-limit": "1",
            "anthropic-ratelimit-output-tokens-remaining": "1",
        ]
        let session = makeMockSession(statusCode: 200, headers: headers)
        let client = AnthropicRateLimitClient(session: session)

        // Act
        let entity = try await client.fetchRateLimits(apiKey: "sk-ant-api03-testkey1234567890abcdef")

        // Assert
        #expect(entity.requestsResetTime == nil)
        #expect(entity.inputTokensResetTime == nil)
        #expect(entity.outputTokensResetTime == nil)
    }
}

// MARK: - URLProtocol mock helper

/// Builds a URLSession backed by MockRateLimitURLProtocol that returns a
/// deterministic HTTP response with the given status code and headers.
private func makeMockSession(statusCode: Int, headers: [String: String]) -> URLSession {
    MockRateLimitURLProtocol.stubbedStatusCode = statusCode
    MockRateLimitURLProtocol.stubbedHeaders = headers
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockRateLimitURLProtocol.self]
    return URLSession(configuration: config)
}

/// Minimal URLProtocol that intercepts all requests and returns the configured
/// HTTP response with rate-limit headers.
private final class MockRateLimitURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var stubbedStatusCode: Int = 200
    nonisolated(unsafe) static var stubbedHeaders: [String: String] = [:]

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url ?? URL(string: "https://api.anthropic.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: Self.stubbedStatusCode,
            httpVersion: "HTTP/1.1",
            headerFields: Self.stubbedHeaders
        )!
        // Minimal valid JSON body (client logs it but doesn't decode it for rate limits)
        let body = Data("{}".utf8)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
