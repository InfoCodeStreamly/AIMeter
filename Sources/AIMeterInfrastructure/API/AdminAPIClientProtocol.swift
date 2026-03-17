import Foundation
import AIMeterDomain
import AIMeterApplication

/// Protocol for Admin API operations (enables testing)
public protocol AdminAPIClientProtocol: Sendable {
    /// Fetches organization usage report
    func fetchUsageReport(
        apiKey: String,
        from: Date,
        to: Date,
        bucketWidth: String,
        groupBy: [String]?,
        page: String?
    ) async throws -> OrgUsageAPIResponse

    /// Fetches organization cost report
    func fetchCostReport(
        apiKey: String,
        from: Date,
        to: Date,
        groupBy: [String]?,
        page: String?
    ) async throws -> OrgCostAPIResponse

    /// Fetches Claude Code analytics
    func fetchClaudeCodeAnalytics(
        apiKey: String,
        date: Date,
        limit: Int?,
        page: String?
    ) async throws -> ClaudeCodeAnalyticsAPIResponse
}
