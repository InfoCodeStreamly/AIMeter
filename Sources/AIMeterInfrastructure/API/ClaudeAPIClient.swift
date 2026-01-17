import Foundation
import AIMeterDomain
import AIMeterApplication

/// HTTP client for Claude OAuth API (Infrastructure implementation)
public actor ClaudeAPIClient: ClaudeAPIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

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


        // Log response body for debugging
        if let bodyString = String(data: data.prefix(500), encoding: .utf8) {
        }

        switch httpResponse.statusCode {
        case 200..<300:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw InfrastructureError.decodingFailed(error)
            }

        case 401, 403:
            throw InfrastructureError.unauthorized

        default:
            throw InfrastructureError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }
}
