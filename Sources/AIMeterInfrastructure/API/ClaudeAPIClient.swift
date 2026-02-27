import Foundation
import OSLog
import AIMeterDomain
import AIMeterApplication

/// HTTP client for Claude OAuth API (Infrastructure implementation)
public actor ClaudeAPIClient: ClaudeAPIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "api")

    public init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    public func fetchUsage(token: String) async throws -> UsageAPIResponse {
        var request = URLRequest(url: APIEndpoints.usage)
        request.httpMethod = "GET"

        for (key, value) in APIEndpoints.headers(token: token) {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return try await perform(request)
    }

    public func validateToken(_ token: String) async throws {
        _ = try await fetchUsage(token: token)
    }

    // MARK: - Private

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw InfrastructureError.networkUnavailable
        }

        logger.debug("API response status: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200..<300:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                // Log raw response body and detailed decode error for diagnosis
                if let body = String(data: data.prefix(1000), encoding: .utf8) {
                    logger.error("Decode failed. Response body: \(body, privacy: .private)")
                }
                if let decodingError = error as? DecodingError {
                    logger.error("DecodingError detail: \(String(describing: decodingError))")
                }
                throw InfrastructureError.decodingFailed(error)
            }

        case 401, 403:
            throw InfrastructureError.unauthorized

        default:
            throw InfrastructureError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }
}
