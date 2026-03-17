import Foundation

/// Repository protocol for organization usage data via Admin API
public protocol OrgUsageRepository: Sendable {
    /// Fetches token usage report for the given time range
    func fetchUsageReport(
        from: Date,
        to: Date,
        bucketWidth: BucketWidth,
        groupBy: [String]?
    ) async throws -> [OrgUsageBucketEntity]

    /// Fetches cost report for the given time range
    func fetchCostReport(
        from: Date,
        to: Date,
        groupBy: [String]?
    ) async throws -> [OrgCostBucketEntity]

    /// Fetches Claude Code per-user analytics for a specific date
    func fetchClaudeCodeAnalytics(
        date: Date
    ) async throws -> [ClaudeCodeUserActivityEntity]
}
