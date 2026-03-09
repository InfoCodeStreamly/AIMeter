import Testing
@testable import AIMeterApplication
import AIMeterDomain
import Foundation

/// Tests for FetchOrgUsageSummaryUseCase — ensures correct orchestration of
/// AdminKeyRepository and OrgUsageRepository calls.
@Suite("FetchOrgUsageSummaryUseCase")
struct FetchOrgUsageSummaryUseCaseTests {

    // MARK: - Error Path Tests

    @Test("execute throws adminKeyNotFound when no key stored")
    func executeThrowsWhenNoAdminKey() async {
        // Arrange
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: false)

        let useCase = FetchOrgUsageSummaryUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act & Assert
        await #expect(throws: DomainError.adminKeyNotFound) {
            try await useCase.execute()
        }

        // Verify repository was NOT called when no key
        #expect(await mockOrgUsageRepo.fetchUsageReportCallCount == 0)
        #expect(await mockOrgUsageRepo.fetchCostReportCallCount == 0)
    }

    // MARK: - Success Path Tests

    @Test("execute calls fetchUsageReport when key exists")
    func executeCallsFetchUsageReportWhenKeyExists() async throws {
        // Arrange
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: true)
        await mockOrgUsageRepo.configure(usageBuckets: [], costBuckets: [])

        let useCase = FetchOrgUsageSummaryUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act
        _ = try await useCase.execute()

        // Assert
        #expect(await mockOrgUsageRepo.fetchUsageReportCallCount == 1)
    }

    @Test("execute calls fetchCostReport when key exists")
    func executeCallsFetchCostReportWhenKeyExists() async throws {
        // Arrange
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: true)
        await mockOrgUsageRepo.configure(usageBuckets: [], costBuckets: [])

        let useCase = FetchOrgUsageSummaryUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act
        _ = try await useCase.execute()

        // Assert
        #expect(await mockOrgUsageRepo.fetchCostReportCallCount == 1)
    }

    @Test("execute calls both fetchUsageReport and fetchCostReport")
    func executeCallsBothRepositoryMethods() async throws {
        // Arrange
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: true)
        await mockOrgUsageRepo.configure(usageBuckets: [], costBuckets: [])

        let useCase = FetchOrgUsageSummaryUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act
        _ = try await useCase.execute()

        // Assert — both methods must be called
        #expect(await mockOrgUsageRepo.fetchUsageReportCallCount == 1)
        #expect(await mockOrgUsageRepo.fetchCostReportCallCount == 1)
    }

    @Test("execute returns aggregated summary with empty data")
    func executeReturnsEmptySummaryForEmptyData() async throws {
        // Arrange
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: true)
        await mockOrgUsageRepo.configure(usageBuckets: [], costBuckets: [])

        let useCase = FetchOrgUsageSummaryUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act
        let summary = try await useCase.execute()

        // Assert
        #expect(summary.totalInputTokens == 0)
        #expect(summary.totalOutputTokens == 0)
        #expect(summary.totalCostCents == 0)
        #expect(summary.byModel.isEmpty)
    }

    @Test("execute aggregates usage buckets by model")
    func executeAggregatesUsageBucketsByModel() async throws {
        // Arrange
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end   = Date(timeIntervalSince1970: 1_700_003_600)

        let usageBuckets = [
            OrgUsageBucketEntity(
                startTime: start, endTime: end,
                model: "claude-3-opus",
                inputTokens: 1000, outputTokens: 500
            ),
            OrgUsageBucketEntity(
                startTime: start, endTime: end,
                model: "claude-3-opus",
                inputTokens: 2000, outputTokens: 1000
            )
        ]
        let costBuckets: [OrgCostBucketEntity] = []

        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: true)
        await mockOrgUsageRepo.configure(usageBuckets: usageBuckets, costBuckets: costBuckets)

        let useCase = FetchOrgUsageSummaryUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act
        let summary = try await useCase.execute()

        // Assert — tokens from both buckets should be combined
        #expect(summary.totalInputTokens == 3000)
        #expect(summary.totalOutputTokens == 1500)
        #expect(summary.byModel.count == 1)
        #expect(summary.byModel.first?.model == "claude-3-opus")
    }

    @Test("execute sums cost from cost buckets")
    func executeSumsCostFromCostBuckets() async throws {
        // Arrange
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end   = Date(timeIntervalSince1970: 1_700_003_600)

        let costBuckets = [
            OrgCostBucketEntity(startTime: start, endTime: end, amountCents: 500),
            OrgCostBucketEntity(startTime: start, endTime: end, amountCents: 750)
        ]

        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: true)
        await mockOrgUsageRepo.configure(usageBuckets: [], costBuckets: costBuckets)

        let useCase = FetchOrgUsageSummaryUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act
        let summary = try await useCase.execute()

        // Assert
        #expect(summary.totalCostCents == 1250)
    }

    @Test("execute propagates fetchUsageReport errors")
    func executePropagatesUsageReportErrors() async {
        // Arrange
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: true)
        await mockOrgUsageRepo.configure(usageError: TestNetworkError.timeout)

        let useCase = FetchOrgUsageSummaryUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act & Assert
        await #expect(throws: TestNetworkError.timeout) {
            try await useCase.execute()
        }
    }
}

// MARK: - Test Helpers

private enum TestNetworkError: Error, Equatable {
    case timeout
}

// MARK: - Mock Implementations

private actor MockAdminKeyRepository: AdminKeyRepository {
    var saveCallCount = 0
    var getCallCount = 0
    var deleteCallCount = 0
    var existsCallCount = 0

    var existsResult = false
    var getResult: AdminAPIKey?
    var saveError: (any Error)?

    func configure(
        existsResult: Bool? = nil,
        getResult: AdminAPIKey?? = nil,
        saveError: (any Error)? = nil
    ) {
        if let existsResult { self.existsResult = existsResult }
        if let getResult { self.getResult = getResult }
        if let saveError { self.saveError = saveError }
    }

    func save(_ key: AdminAPIKey) async throws {
        saveCallCount += 1
        if let error = saveError { throw error }
    }

    func get() async -> AdminAPIKey? {
        getCallCount += 1
        return getResult
    }

    func delete() async {
        deleteCallCount += 1
    }

    func exists() async -> Bool {
        existsCallCount += 1
        return existsResult
    }
}

private actor MockOrgUsageRepository: OrgUsageRepository {
    var fetchUsageReportCallCount = 0
    var fetchCostReportCallCount = 0
    var fetchClaudeCodeAnalyticsCallCount = 0

    var usageBuckets: [OrgUsageBucketEntity] = []
    var costBuckets: [OrgCostBucketEntity] = []
    var analyticsEntities: [ClaudeCodeUserActivityEntity] = []

    var usageError: (any Error)?
    var costError: (any Error)?
    var analyticsError: (any Error)?

    func configure(
        usageBuckets: [OrgUsageBucketEntity]? = nil,
        costBuckets: [OrgCostBucketEntity]? = nil,
        analyticsEntities: [ClaudeCodeUserActivityEntity]? = nil,
        usageError: (any Error)? = nil,
        costError: (any Error)? = nil,
        analyticsError: (any Error)? = nil
    ) {
        if let usageBuckets { self.usageBuckets = usageBuckets }
        if let costBuckets { self.costBuckets = costBuckets }
        if let analyticsEntities { self.analyticsEntities = analyticsEntities }
        if let usageError { self.usageError = usageError }
        if let costError { self.costError = costError }
        if let analyticsError { self.analyticsError = analyticsError }
    }

    func fetchUsageReport(
        from: Date,
        to: Date,
        bucketWidth: BucketWidth,
        groupBy: [String]?
    ) async throws -> [OrgUsageBucketEntity] {
        fetchUsageReportCallCount += 1
        if let error = usageError { throw error }
        return usageBuckets
    }

    func fetchCostReport(from: Date, to: Date) async throws -> [OrgCostBucketEntity] {
        fetchCostReportCallCount += 1
        if let error = costError { throw error }
        return costBuckets
    }

    func fetchClaudeCodeAnalytics(date: Date) async throws -> [ClaudeCodeUserActivityEntity] {
        fetchClaudeCodeAnalyticsCallCount += 1
        if let error = analyticsError { throw error }
        return analyticsEntities
    }
}
