import Foundation
import OSLog

/// HTTP client for Claude API
/// Supports both OAuth (api.anthropic.com) and session key (claude.ai) authentication
actor ClaudeAPIClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = Logger.api

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    /// Fetches organizations for session key (not needed for OAuth)
    /// - Parameter sessionKey: Claude session key
    /// - Returns: Organization API response
    func fetchOrganizations(sessionKey: String) async throws -> OrganizationAPIResponse {
        logger.debug("Fetching organizations")

        let request = makeRequest(
            url: APIEndpoints.organizations,
            sessionKey: sessionKey
        )

        return try await perform(request)
    }

    /// Fetches usage data
    /// - For OAuth tokens: uses api.anthropic.com/api/oauth/usage (no org ID needed)
    /// - For session keys: uses claude.ai/api/organizations/{orgId}/usage
    func fetchUsage(
        organizationId: String?,
        sessionKey: String
    ) async throws -> UsageAPIResponse {
        let url: URL
        let headers: [String: String]

        if APIEndpoints.isOAuthToken(sessionKey) {
            // OAuth token - use Anthropic API
            logger.info("Using OAuth endpoint (api.anthropic.com)")
            url = APIEndpoints.oauthUsage
            headers = APIEndpoints.oauthHeaders(token: sessionKey)
        } else {
            // Session key - use Claude.ai API
            guard let orgId = organizationId else {
                logger.error("Organization ID required for session key auth")
                throw InfrastructureError.missingOrganizationId
            }
            logger.info("Using Claude.ai endpoint with org: \(orgId)")
            url = APIEndpoints.claudeUsage(organizationId: orgId)
            headers = APIEndpoints.claudeHeaders(sessionKey: sessionKey)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        logger.debug("Request URL: \(url.absoluteString)")

        return try await perform(request)
    }

    /// Validates session key by fetching organization (for session key) or usage (for OAuth)
    func validateKey(_ sessionKey: String) async throws -> String? {
        if APIEndpoints.isOAuthToken(sessionKey) {
            // OAuth tokens don't need org ID - just verify the token works
            logger.info("Validating OAuth token")
            _ = try await fetchUsage(organizationId: nil, sessionKey: sessionKey)
            return nil // No org ID for OAuth
        } else {
            // Session keys need to fetch organization first
            logger.info("Validating session key by fetching organization")
            let orgs = try await fetchOrganizations(sessionKey: sessionKey)
            return orgs.firstOrganizationId
        }
    }

    // MARK: - Private

    private func makeRequest(url: URL, sessionKey: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        for (key, value) in APIEndpoints.headers(sessionKey: sessionKey) {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("No HTTP response received")
            throw InfrastructureError.networkUnavailable
        }

        logger.info("Response status: \(httpResponse.statusCode)")

        // Log response body for debugging
        if let bodyString = String(data: data.prefix(500), encoding: .utf8) {
            logger.debug("Response body: \(bodyString, privacy: .private)")
        }

        switch httpResponse.statusCode {
        case 200..<300:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                logger.error("Decoding failed: \(error.localizedDescription)")
                throw InfrastructureError.decodingFailed(error)
            }

        case 401, 403:
            logger.warning("Unauthorized: \(httpResponse.statusCode)")
            throw InfrastructureError.unauthorized

        default:
            logger.error("Request failed with status: \(httpResponse.statusCode)")
            throw InfrastructureError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }
}
