import Foundation
import OSLog
import AIMeterDomain
import AIMeterApplication

/// HTTP client for Anthropic Admin API
public actor AdminAPIClient: AdminAPIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "admin-api")

    public init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    public func fetchUsageReport(
        apiKey: String,
        from: Date,
        to: Date,
        bucketWidth: String,
        groupBy: [String]?,
        page: String?
    ) async throws -> OrgUsageAPIResponse {
        let url = AdminAPIEndpoints.usageReport(
            from: from, to: to,
            bucketWidth: bucketWidth,
            groupBy: groupBy,
            page: page
        )
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request, apiKey: apiKey)
        return try await perform(request)
    }

    public func fetchCostReport(
        apiKey: String,
        from: Date,
        to: Date,
        page: String?
    ) async throws -> OrgCostAPIResponse {
        let url = AdminAPIEndpoints.costReport(from: from, to: to, page: page)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request, apiKey: apiKey)
        return try await perform(request)
    }

    public func fetchClaudeCodeAnalytics(
        apiKey: String,
        date: Date,
        limit: Int?,
        page: String?
    ) async throws -> ClaudeCodeAnalyticsAPIResponse {
        let url = AdminAPIEndpoints.claudeCodeAnalytics(date: date, limit: limit, page: page)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request, apiKey: apiKey)
        return try await perform(request)
    }

    // MARK: - Private

    private func applyHeaders(_ request: inout URLRequest, apiKey: String) {
        for (key, value) in AdminAPIEndpoints.headers(apiKey: apiKey) {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw InfrastructureError.networkUnavailable
        }

        logger.debug("Admin API response status: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200..<300:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
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
