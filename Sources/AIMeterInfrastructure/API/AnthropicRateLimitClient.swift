import Foundation
import OSLog
import AIMeterDomain

/// HTTP client for fetching rate limits from Anthropic API
/// Makes POST /v1/messages with max_tokens=1 and parses rate limit response headers
public actor AnthropicRateLimitClient: RateLimitClientProtocol {
    private let session: URLSession
    private let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "rate-limit-api")

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches rate limits by making a minimal POST /v1/messages request (1 output token)
    public func fetchRateLimits(apiKey: String) async throws -> APIKeyRateLimitEntity {
        let url = URL(string: "\(APIConstants.AdminAPI.baseURL)/v1/messages")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(APIConstants.AdminAPI.versionHeader, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("AIMeter/1.0", forHTTPHeaderField: "User-Agent")

        // Minimal request — ~10 input tokens + 1 output token, returns rate limit headers
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 1,
            "messages": [["role": "user", "content": "."]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw InfrastructureError.networkUnavailable
        }

        logger.info("Rate limit API: status=\(httpResponse.statusCode), body=\(String(data: data, encoding: .utf8) ?? "nil", privacy: .public)")

        // Rate limit headers are returned even on 429 responses
        switch httpResponse.statusCode {
        case 200..<300, 429:
            let entity = parseRateLimitHeaders(httpResponse)
            logger.info("Rate limit headers: RPM=\(entity.requestsRemaining)/\(entity.requestsLimit), ITPM=\(entity.inputTokensRemaining)/\(entity.inputTokensLimit), OTPM=\(entity.outputTokensRemaining)/\(entity.outputTokensLimit)")
            return entity

        case 401, 403:
            throw InfrastructureError.unauthorized

        default:
            throw InfrastructureError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Private

    private func parseRateLimitHeaders(_ response: HTTPURLResponse) -> APIKeyRateLimitEntity {
        // Use value(forHTTPHeaderField:) — case-insensitive lookup
        // allHeaderFields dictionary is case-sensitive in Swift, which misses headers
        return APIKeyRateLimitEntity(
            requestsLimit: intHeader(response, "anthropic-ratelimit-requests-limit"),
            requestsRemaining: intHeader(response, "anthropic-ratelimit-requests-remaining"),
            requestsResetTime: dateHeader(response, "anthropic-ratelimit-requests-reset"),
            inputTokensLimit: intHeader(response, "anthropic-ratelimit-input-tokens-limit"),
            inputTokensRemaining: intHeader(response, "anthropic-ratelimit-input-tokens-remaining"),
            inputTokensResetTime: dateHeader(response, "anthropic-ratelimit-input-tokens-reset"),
            outputTokensLimit: intHeader(response, "anthropic-ratelimit-output-tokens-limit"),
            outputTokensRemaining: intHeader(response, "anthropic-ratelimit-output-tokens-remaining"),
            outputTokensResetTime: dateHeader(response, "anthropic-ratelimit-output-tokens-reset")
        )
    }

    private func intHeader(_ response: HTTPURLResponse, _ name: String) -> Int {
        guard let value = response.value(forHTTPHeaderField: name), let int = Int(value) else {
            return 0
        }
        return int
    }

    private func dateHeader(_ response: HTTPURLResponse, _ name: String) -> Date? {
        guard let value = response.value(forHTTPHeaderField: name) else { return nil }
        return ISO8601DateFormatter().date(from: value)
    }
}
