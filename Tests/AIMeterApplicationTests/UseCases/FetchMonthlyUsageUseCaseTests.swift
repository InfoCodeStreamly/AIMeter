import Testing
@testable import AIMeterApplication
@testable import AIMeterDomain
import Foundation

@Suite("FetchMonthlyUsageUseCase")
struct FetchMonthlyUsageUseCaseTests {

    // MARK: - Helpers

    private func makeSUT(
        adminKeyExists: Bool = true,
        usageBuckets: [OrgUsageBucketEntity] = [],
        costBuckets: [OrgCostBucketEntity] = []
    ) async -> (FetchMonthlyUsageUseCase, MockAdminKeyRepo, MockOrgUsageRepo) {
        let adminRepo = MockAdminKeyRepo()
        await adminRepo.configure(existsResult: adminKeyExists)
        let orgRepo = MockOrgUsageRepo()
        await orgRepo.configure(usageBuckets: usageBuckets, costBuckets: costBuckets)
        let sut = FetchMonthlyUsageUseCase(adminKeyRepository: adminRepo, orgUsageRepository: orgRepo)
        return (sut, adminRepo, orgRepo)
    }

    // MARK: - Tests

    @Test("throws adminKeyNotFound when no key")
    func throwsWhenNoAdminKey() async {
        let (sut, _, _) = await makeSUT(adminKeyExists: false)
        await #expect(throws: DomainError.self) {
            _ = try await sut.execute()
        }
    }

    @Test("returns empty monthly usage for empty data")
    func returnsEmptyForEmptyData() async throws {
        let (sut, _, _) = await makeSUT()
        let result = try await sut.execute()
        #expect(result.totalInputTokens == 0)
        #expect(result.totalOutputTokens == 0)
        #expect(result.totalCostCents == 0)
        #expect(result.byApiKey.isEmpty)
        #expect(result.byModel.isEmpty)
        #expect(result.dailyCosts.isEmpty)
    }

    @Test("aggregates total cost from cost buckets")
    func aggregatesTotalCost() async throws {
        let start = Date(timeIntervalSince1970: 1_740_000_000)
        let end = Date(timeIntervalSince1970: 1_740_086_400)

        let costs = [
            OrgCostBucketEntity(startTime: start, endTime: end, model: "claude-sonnet-4-6", costType: "tokens", amountCents: 500),
            OrgCostBucketEntity(startTime: start, endTime: end, model: "claude-haiku-4-5", costType: "tokens", amountCents: 100),
            OrgCostBucketEntity(startTime: start, endTime: end, costType: "web_search", amountCents: 50)
        ]

        let (sut, _, _) = await makeSUT(costBuckets: costs)
        let result = try await sut.execute()

        #expect(result.totalCostCents == 650)
    }

    @Test("groups cost by model from cost_report description")
    func groupsCostByModel() async throws {
        let start = Date(timeIntervalSince1970: 1_740_000_000)
        let end = Date(timeIntervalSince1970: 1_740_086_400)

        let costs = [
            OrgCostBucketEntity(startTime: start, endTime: end, model: "claude-sonnet-4-6", costType: "tokens", amountCents: 800),
            OrgCostBucketEntity(startTime: start, endTime: end, model: "claude-haiku-4-5", costType: "tokens", amountCents: 200)
        ]

        let (sut, _, _) = await makeSUT(costBuckets: costs)
        let result = try await sut.execute()

        #expect(result.byModel.count == 2)
        // Sorted by cost descending
        #expect(result.byModel[0].model == "claude-sonnet-4-6")
        #expect(result.byModel[0].costCents == 800)
        #expect(result.byModel[1].model == "claude-haiku-4-5")
        #expect(result.byModel[1].costCents == 200)
    }

    @Test("groups usage by API key with proportional cost estimate")
    func groupsByApiKeyWithProportionalCost() async throws {
        let start = Date(timeIntervalSince1970: 1_740_000_000)
        let end = Date(timeIntervalSince1970: 1_740_086_400)

        // Key1 uses 75% of sonnet tokens, Key2 uses 25%
        let usage = [
            OrgUsageBucketEntity(startTime: start, endTime: end, model: "sonnet", apiKeyId: "key1", inputTokens: 600, outputTokens: 150),
            OrgUsageBucketEntity(startTime: start, endTime: end, model: "sonnet", apiKeyId: "key2", inputTokens: 200, outputTokens: 50)
        ]

        // Total sonnet cost = 1000 cents
        let costs = [
            OrgCostBucketEntity(startTime: start, endTime: end, model: "sonnet", costType: "tokens", amountCents: 1000)
        ]

        let (sut, _, _) = await makeSUT(usageBuckets: usage, costBuckets: costs)
        let result = try await sut.execute()

        #expect(result.byApiKey.count == 2)
        // Key1: 750/1000 * 1000 = 750 (75%)
        #expect(result.byApiKey[0].apiKeyId == "key1")
        #expect(result.byApiKey[0].estimatedCostCents == 750)
        // Key2: 250/1000 * 1000 = 250 (25%)
        #expect(result.byApiKey[1].apiKeyId == "key2")
        #expect(result.byApiKey[1].estimatedCostCents == 250)
    }

    @Test("aggregates daily costs")
    func aggregatesDailyCosts() async throws {
        let day1Start = Date(timeIntervalSince1970: 1_740_000_000) // some day
        let day1End = Date(timeIntervalSince1970: 1_740_086_400)
        let day2Start = Date(timeIntervalSince1970: 1_740_086_400)
        let day2End = Date(timeIntervalSince1970: 1_740_172_800)

        let costs = [
            OrgCostBucketEntity(startTime: day1Start, endTime: day1End, costType: "tokens", amountCents: 300),
            OrgCostBucketEntity(startTime: day1Start, endTime: day1End, costType: "tokens", amountCents: 200),
            OrgCostBucketEntity(startTime: day2Start, endTime: day2End, costType: "tokens", amountCents: 500)
        ]

        let (sut, _, _) = await makeSUT(costBuckets: costs)
        let result = try await sut.execute()

        #expect(result.dailyCosts.count == 2)
        // Sorted by date ascending
        #expect(result.dailyCosts[0].costCents == 500)
        #expect(result.dailyCosts[1].costCents == 500)
    }

    @Test("aggregates total input and output tokens")
    func aggregatesTotalTokens() async throws {
        let start = Date(timeIntervalSince1970: 1_740_000_000)
        let end = Date(timeIntervalSince1970: 1_740_086_400)

        let usage = [
            OrgUsageBucketEntity(startTime: start, endTime: end, model: "sonnet", inputTokens: 1000, outputTokens: 500),
            OrgUsageBucketEntity(startTime: start, endTime: end, model: "haiku", inputTokens: 2000, outputTokens: 800)
        ]

        let (sut, _, _) = await makeSUT(usageBuckets: usage)
        let result = try await sut.execute()

        #expect(result.totalInputTokens == 3000)
        #expect(result.totalOutputTokens == 1300)
    }

    @Test("non-token costs grouped under other model")
    func nonTokenCostsGroupedUnderOther() async throws {
        let start = Date(timeIntervalSince1970: 1_740_000_000)
        let end = Date(timeIntervalSince1970: 1_740_086_400)

        let costs = [
            OrgCostBucketEntity(startTime: start, endTime: end, costType: "web_search", amountCents: 100),
            OrgCostBucketEntity(startTime: start, endTime: end, costType: "code_execution", amountCents: 50)
        ]

        let (sut, _, _) = await makeSUT(costBuckets: costs)
        let result = try await sut.execute()

        let otherModel = result.byModel.first { $0.model == "other" }
        #expect(otherModel != nil)
        #expect(otherModel?.costCents == 150)
    }

    @Test("skips usage without apiKeyId in per-key breakdown")
    func skipsUsageWithoutApiKeyId() async throws {
        let start = Date(timeIntervalSince1970: 1_740_000_000)
        let end = Date(timeIntervalSince1970: 1_740_086_400)

        let usage = [
            OrgUsageBucketEntity(startTime: start, endTime: end, model: "sonnet", inputTokens: 1000, outputTokens: 500),
            OrgUsageBucketEntity(startTime: start, endTime: end, model: "sonnet", apiKeyId: "key1", inputTokens: 500, outputTokens: 200)
        ]

        let (sut, _, _) = await makeSUT(usageBuckets: usage)
        let result = try await sut.execute()

        // Only key1 appears (bucket without apiKeyId is skipped)
        #expect(result.byApiKey.count == 1)
        #expect(result.byApiKey[0].apiKeyId == "key1")
    }
}

// MARK: - Mocks

private actor MockAdminKeyRepo: AdminKeyRepository {
    var existsResult = true

    func configure(existsResult: Bool) {
        self.existsResult = existsResult
    }

    func save(_ key: AdminAPIKey) async throws {}
    func get() async -> AdminAPIKey? { nil }
    func delete() async {}
    func exists() async -> Bool { existsResult }
}

private actor MockOrgUsageRepo: OrgUsageRepository {
    var usageBuckets: [OrgUsageBucketEntity] = []
    var costBuckets: [OrgCostBucketEntity] = []

    func configure(
        usageBuckets: [OrgUsageBucketEntity]? = nil,
        costBuckets: [OrgCostBucketEntity]? = nil
    ) {
        if let usageBuckets { self.usageBuckets = usageBuckets }
        if let costBuckets { self.costBuckets = costBuckets }
    }

    func fetchUsageReport(
        from: Date, to: Date,
        bucketWidth: BucketWidth,
        groupBy: [String]?
    ) async throws -> [OrgUsageBucketEntity] {
        usageBuckets
    }

    func fetchCostReport(from: Date, to: Date, groupBy: [String]?) async throws -> [OrgCostBucketEntity] {
        costBuckets
    }

    func fetchClaudeCodeAnalytics(date: Date) async throws -> [ClaudeCodeUserActivityEntity] {
        []
    }
}
