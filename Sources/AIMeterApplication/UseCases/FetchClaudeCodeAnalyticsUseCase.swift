import Foundation
import AIMeterDomain

/// Fetches today's Claude Code per-user analytics
public final class FetchClaudeCodeAnalyticsUseCase: Sendable {
    private let adminKeyRepository: any AdminKeyRepository
    private let orgUsageRepository: any OrgUsageRepository

    public init(
        adminKeyRepository: any AdminKeyRepository,
        orgUsageRepository: any OrgUsageRepository
    ) {
        self.adminKeyRepository = adminKeyRepository
        self.orgUsageRepository = orgUsageRepository
    }

    /// Fetches today's per-user Claude Code activity
    public func execute() async throws -> [ClaudeCodeUserActivityEntity] {
        guard await adminKeyRepository.exists() else {
            throw DomainError.adminKeyNotFound
        }

        return try await orgUsageRepository.fetchClaudeCodeAnalytics(date: Date())
    }
}
