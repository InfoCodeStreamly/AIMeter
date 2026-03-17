import Foundation
import OSLog
import AIMeterDomain
import AIMeterApplication

/// Implementation of OrgUsageRepository using Anthropic Admin API
public actor AdminOrgUsageRepository: OrgUsageRepository {
    private let adminAPIClient: any AdminAPIClientProtocol
    private let adminKeyRepository: any AdminKeyRepository
    private let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "admin-repo")

    public init(
        adminAPIClient: any AdminAPIClientProtocol,
        adminKeyRepository: any AdminKeyRepository
    ) {
        self.adminAPIClient = adminAPIClient
        self.adminKeyRepository = adminKeyRepository
    }

    public func fetchUsageReport(
        from: Date,
        to: Date,
        bucketWidth: BucketWidth,
        groupBy: [String]?
    ) async throws -> [OrgUsageBucketEntity] {
        let apiKey = try await getApiKey()

        var allBuckets: [OrgUsageBucketEntity] = []
        var nextPage: String? = nil

        repeat {
            let response = try await adminAPIClient.fetchUsageReport(
                apiKey: apiKey,
                from: from,
                to: to,
                bucketWidth: bucketWidth.rawValue,
                groupBy: groupBy,
                page: nextPage
            )
            allBuckets.append(contentsOf: AdminAPIMapper.toUsageBuckets(response))
            nextPage = response.hasMore ? response.nextPage : nil
        } while nextPage != nil

        logger.info("fetchUsageReport: \(allBuckets.count) buckets fetched")
        return allBuckets
    }

    public func fetchCostReport(
        from: Date,
        to: Date,
        groupBy: [String]?
    ) async throws -> [OrgCostBucketEntity] {
        let apiKey = try await getApiKey()

        var allBuckets: [OrgCostBucketEntity] = []
        var nextPage: String? = nil

        repeat {
            let response = try await adminAPIClient.fetchCostReport(
                apiKey: apiKey,
                from: from,
                to: to,
                groupBy: groupBy,
                page: nextPage
            )
            allBuckets.append(contentsOf: AdminAPIMapper.toCostBuckets(response))
            nextPage = response.hasMore ? response.nextPage : nil
        } while nextPage != nil

        logger.info("fetchCostReport: \(allBuckets.count) cost buckets fetched")
        return allBuckets
    }

    public func fetchClaudeCodeAnalytics(
        date: Date
    ) async throws -> [ClaudeCodeUserActivityEntity] {
        let apiKey = try await getApiKey()

        var allActivities: [ClaudeCodeUserActivityEntity] = []
        var nextPage: String? = nil

        repeat {
            let response = try await adminAPIClient.fetchClaudeCodeAnalytics(
                apiKey: apiKey,
                date: date,
                limit: 100,
                page: nextPage
            )
            allActivities.append(contentsOf: AdminAPIMapper.toUserActivities(response))
            nextPage = response.hasMore ? response.nextPage : nil
        } while nextPage != nil

        logger.info("fetchClaudeCodeAnalytics: \(allActivities.count) user activities fetched")
        return allActivities
    }

    // MARK: - Private

    private func getApiKey() async throws -> String {
        guard let key = await adminKeyRepository.get() else {
            throw DomainError.adminKeyNotFound
        }
        return key.value
    }
}
