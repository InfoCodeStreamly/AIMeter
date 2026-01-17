import Foundation
import OSLog

/// HTTP client for Claude OAuth API
actor ClaudeAPIClient: ClaudeAPIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = Logger.api

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    /// Fetches usage data from OAuth API
    func fetchUsage(token: String) async throws -> UsageAPIResponse {
        logger.info("Fetching usage from OAuth API")

        var request = URLRequest(url: APIEndpoints.usage)
        request.httpMethod = "GET"

        for (key, value) in APIEndpoints.headers(token: token) {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return try await perform(request)
    }

    /// Validates OAuth token by fetching usage
    func validateToken(_ token: String) async throws {
        logger.info("Validating OAuth token")
        _ = try await fetchUsage(token: token)
    }

    // MARK: - Private

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("No HTTP response received")
            throw InfrastructureError.networkUnavailable
        }

        logger.debug("Response status: \(httpResponse.statusCode)")

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
