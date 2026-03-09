import Testing
@testable import AIMeterApplication
import AIMeterDomain
import Foundation

/// Tests for FetchClaudeCodeAnalyticsUseCase — verifies key check and repository delegation.
@Suite("FetchClaudeCodeAnalyticsUseCase")
struct FetchClaudeCodeAnalyticsUseCaseTests {

    // MARK: - Error Path Tests

    @Test("execute throws adminKeyNotFound when no key stored")
    func executeThrowsWhenNoAdminKey() async {
        // Arrange
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: false)

        let useCase = FetchClaudeCodeAnalyticsUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act & Assert
        await #expect(throws: DomainError.adminKeyNotFound) {
            try await useCase.execute()
        }

        // Verify analytics repository was NOT called
        #expect(await mockOrgUsageRepo.fetchClaudeCodeAnalyticsCallCount == 0)
    }

    // MARK: - Success Path Tests

    @Test("execute calls fetchClaudeCodeAnalytics when key exists")
    func executeCallsFetchClaudeCodeAnalyticsWhenKeyExists() async throws {
        // Arrange
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: true)
        await mockOrgUsageRepo.configure(analyticsEntities: [])

        let useCase = FetchClaudeCodeAnalyticsUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act
        _ = try await useCase.execute()

        // Assert
        #expect(await mockOrgUsageRepo.fetchClaudeCodeAnalyticsCallCount == 1)
    }

    @Test("execute returns entities from repository")
    func executeReturnsEntitiesFromRepository() async throws {
        // Arrange
        let sampleDate = Date(timeIntervalSince1970: 1_700_000_000)
        let expectedEntities = [
            ClaudeCodeUserActivityEntity(
                date: sampleDate,
                email: "user1@example.com",
                sessions: 3,
                linesAdded: 100,
                linesRemoved: 20
            ),
            ClaudeCodeUserActivityEntity(
                date: sampleDate,
                email: "user2@example.com",
                sessions: 5,
                linesAdded: 250,
                linesRemoved: 50
            )
        ]

        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: true)
        await mockOrgUsageRepo.configure(analyticsEntities: expectedEntities)

        let useCase = FetchClaudeCodeAnalyticsUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.count == 2)
        #expect(result[0].email == "user1@example.com")
        #expect(result[1].email == "user2@example.com")
    }

    @Test("execute returns empty array when repository returns no data")
    func executeReturnsEmptyArrayWhenNoData() async throws {
        // Arrange
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: true)
        await mockOrgUsageRepo.configure(analyticsEntities: [])

        let useCase = FetchClaudeCodeAnalyticsUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.isEmpty)
    }

    @Test("execute propagates repository errors")
    func executePropagatesRepositoryErrors() async {
        // Arrange
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: true)
        await mockOrgUsageRepo.configure(analyticsError: TestAnalyticsError.apiFailure)

        let useCase = FetchClaudeCodeAnalyticsUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act & Assert
        await #expect(throws: TestAnalyticsError.apiFailure) {
            try await useCase.execute()
        }
    }

    @Test("execute does not call usage or cost report methods")
    func executeDoesNotCallOtherRepositoryMethods() async throws {
        // Arrange
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()
        await mockAdminKeyRepo.configure(existsResult: true)
        await mockOrgUsageRepo.configure(analyticsEntities: [])

        let useCase = FetchClaudeCodeAnalyticsUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )

        // Act
        _ = try await useCase.execute()

        // Assert — only analytics method should be called
        #expect(await mockOrgUsageRepo.fetchUsageReportCallCount == 0)
        #expect(await mockOrgUsageRepo.fetchCostReportCallCount == 0)
        #expect(await mockOrgUsageRepo.fetchClaudeCodeAnalyticsCallCount == 1)
    }
}

// MARK: - Test Helpers

private enum TestAnalyticsError: Error, Equatable {
    case apiFailure
}

// MARK: - Mock Implementations

private actor MockAdminKeyRepository: AdminKeyRepository {
    var existsResult = false

    func configure(existsResult: Bool? = nil) {
        if let existsResult { self.existsResult = existsResult }
    }

    func save(_ key: AdminAPIKey) async throws {}
    func get() async -> AdminAPIKey? { nil }
    func delete() async {}

    func exists() async -> Bool {
        existsResult
    }
}

private actor MockOrgUsageRepository: OrgUsageRepository {
    var fetchUsageReportCallCount = 0
    var fetchCostReportCallCount = 0
    var fetchClaudeCodeAnalyticsCallCount = 0

    var analyticsEntities: [ClaudeCodeUserActivityEntity] = []
    var analyticsError: (any Error)?

    func configure(
        analyticsEntities: [ClaudeCodeUserActivityEntity]? = nil,
        analyticsError: (any Error)? = nil
    ) {
        if let analyticsEntities { self.analyticsEntities = analyticsEntities }
        if let analyticsError { self.analyticsError = analyticsError }
    }

    func fetchUsageReport(
        from: Date,
        to: Date,
        bucketWidth: BucketWidth,
        groupBy: [String]?
    ) async throws -> [OrgUsageBucketEntity] {
        fetchUsageReportCallCount += 1
        return []
    }

    func fetchCostReport(from: Date, to: Date) async throws -> [OrgCostBucketEntity] {
        fetchCostReportCallCount += 1
        return []
    }

    func fetchClaudeCodeAnalytics(date: Date) async throws -> [ClaudeCodeUserActivityEntity] {
        fetchClaudeCodeAnalyticsCallCount += 1
        if let error = analyticsError { throw error }
        return analyticsEntities
    }
}
