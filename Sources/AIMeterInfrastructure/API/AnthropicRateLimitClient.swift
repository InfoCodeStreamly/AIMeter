import Foundation
import OSLog
import AIMeterDomain

/// HTTP client for fetching rate limits from Anthropic API
/// Makes GET /v1/models?limit=1 and parses rate limit response headers
public actor AnthropicRateLimitClient: RateLimitClientProtocol {
    private let session: URLSession
    private let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "rate-limit-api")

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches rate limits by making a lightweight GET /v1/models request
    public func fetchRateLimits(apiKey: String) async throws -> APIKeyRateLimitEntity {
        var components = URLComponents(string: "\(APIConstants.AdminAPI.baseURL)/v1/models")!
        components.queryItems = [URLQueryItem(name: "limit", value: "1")]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(APIConstants.AdminAPI.versionHeader, forHTTPHeaderField: "anthropic-version")
        request.setValue("AIMeter/1.0", forHTTPHeaderField: "User-Agent")

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw InfrastructureError.networkUnavailable
        }

        logger.debug("Rate limit API response status: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200..<300:
            return parseRateLimitHeaders(httpResponse)

        case 401, 403:
            throw InfrastructureError.unauthorized

        default:
            throw InfrastructureError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Private

    private func parseRateLimitHeaders(_ response: HTTPURLResponse) -> APIKeyRateLimitEntity {
        let headers = response.allHeaderFields

        return APIKeyRateLimitEntity(
            requestsLimit: intHeader(headers, "anthropic-ratelimit-requests-limit"),
            requestsRemaining: intHeader(headers, "anthropic-ratelimit-requests-remaining"),
            requestsResetTime: dateHeader(headers, "anthropic-ratelimit-requests-reset"),
            inputTokensLimit: intHeader(headers, "anthropic-ratelimit-input-tokens-limit"),
            inputTokensRemaining: intHeader(headers, "anthropic-ratelimit-input-tokens-remaining"),
            inputTokensResetTime: dateHeader(headers, "anthropic-ratelimit-input-tokens-reset"),
            outputTokensLimit: intHeader(headers, "anthropic-ratelimit-output-tokens-limit"),
            outputTokensRemaining: intHeader(headers, "anthropic-ratelimit-output-tokens-remaining"),
            outputTokensResetTime: dateHeader(headers, "anthropic-ratelimit-output-tokens-reset")
        )
    }

    private func intHeader(_ headers: [AnyHashable: Any], _ name: String) -> Int {
        if let value = headers[name] as? String, let int = Int(value) {
            return int
        }
        if let value = headers[name] as? Int {
            return value
        }
        return 0
    }

    private func dateHeader(_ headers: [AnyHashable: Any], _ name: String) -> Date? {
        guard let value = headers[name] as? String else { return nil }
        return ISO8601DateFormatter().date(from: value)
    }
}
