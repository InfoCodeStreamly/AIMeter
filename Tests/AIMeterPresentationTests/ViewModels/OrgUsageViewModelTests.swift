import Testing
@testable import AIMeterPresentation
@testable import AIMeterApplication
@testable import AIMeterDomain
import Foundation

/// Tests for OrgUsageViewModel, focusing on rate limit polling behavior
/// in standalone API key mode (no Admin key required).
@Suite("OrgUsageViewModel Tests")
@MainActor
struct OrgUsageViewModelTests {

    // MARK: - Mock Repositories

    actor MockAdminKeyRepository: AdminKeyRepository {
        var storedKey: AdminAPIKey?

        func configure(storedKey: AdminAPIKey? = nil) {
            self.storedKey = storedKey
        }

        func save(_ key: AdminAPIKey) async throws {
            storedKey = key
        }

        func get() async -> AdminAPIKey? {
            return storedKey
        }

        func delete() async {
            storedKey = nil
        }

        func exists() async -> Bool {
            return storedKey != nil
        }
    }

    actor MockAPIKeyRepository: APIKeyRepository {
        var storedKey: AnthropicAPIKey?

        func configure(storedKey: AnthropicAPIKey? = nil) {
            self.storedKey = storedKey
        }

        func save(_ key: AnthropicAPIKey) async throws {
            storedKey = key
        }

        func get() async -> AnthropicAPIKey? {
            return storedKey
        }

        func delete() async {
            storedKey = nil
        }

        func exists() async -> Bool {
            return storedKey != nil
        }
    }

    actor MockOrgUsageRepository: OrgUsageRepository {
        var shouldThrow = false
        var usageBuckets: [OrgUsageBucketEntity] = []
        var costBuckets: [OrgCostBucketEntity] = []
        var analyticsEntities: [ClaudeCodeUserActivityEntity] = []

        func configure(shouldThrow: Bool) {
            self.shouldThrow = shouldThrow
        }

        func fetchUsageReport(
            from: Date,
            to: Date,
            bucketWidth: BucketWidth,
            groupBy: [String]?
        ) async throws -> [OrgUsageBucketEntity] {
            if shouldThrow { throw DomainError.rateLimited }
            return usageBuckets
        }

        func fetchCostReport(from: Date, to: Date) async throws -> [OrgCostBucketEntity] {
            if shouldThrow { throw DomainError.rateLimited }
            return costBuckets
        }

        func fetchClaudeCodeAnalytics(date: Date) async throws -> [ClaudeCodeUserActivityEntity] {
            if shouldThrow { throw DomainError.rateLimited }
            return analyticsEntities
        }
    }

    actor MockRateLimitRepository: RateLimitRepository {
        var callCount = 0
        var result: APIKeyRateLimitEntity?
        var shouldThrow = false

        func configure(result: APIKeyRateLimitEntity? = nil, shouldThrow: Bool = false) {
            self.result = result
            self.shouldThrow = shouldThrow
        }

        func fetchRateLimits(apiKey: String) async throws -> APIKeyRateLimitEntity {
            callCount += 1
            if shouldThrow { throw DomainError.rateLimited }
            return result ?? APIKeyRateLimitEntity(
                requestsLimit: 100,
                requestsRemaining: 80,
                inputTokensLimit: 10_000,
                inputTokensRemaining: 8_000,
                outputTokensLimit: 5_000,
                outputTokensRemaining: 4_000
            )
        }
    }

    // MARK: - Helper

    func makeViewModel(
        mockAdminKeyRepo: MockAdminKeyRepository,
        mockAPIKeyRepo: MockAPIKeyRepository? = nil,
        mockOrgUsageRepo: MockOrgUsageRepository,
        mockRateLimitRepo: MockRateLimitRepository? = nil
    ) -> OrgUsageViewModel {
        let fetchOrgUseCase = FetchOrgUsageSummaryUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )
        let fetchAnalyticsUseCase = FetchClaudeCodeAnalyticsUseCase(
            adminKeyRepository: mockAdminKeyRepo,
            orgUsageRepository: mockOrgUsageRepo
        )
        let getAdminKeyUseCase = GetAdminKeyUseCase(adminKeyRepository: mockAdminKeyRepo)

        let fetchRateLimitsUseCase: FetchAPIKeyRateLimitsUseCase? = mockAPIKeyRepo.flatMap { apiKeyRepo in
            mockRateLimitRepo.map { rateLimitRepo in
                FetchAPIKeyRateLimitsUseCase(
                    apiKeyRepository: apiKeyRepo,
                    rateLimitRepository: rateLimitRepo
                )
            }
        }

        let getAnthropicAPIKeyUseCase: GetAnthropicAPIKeyUseCase? = mockAPIKeyRepo.map {
            GetAnthropicAPIKeyUseCase(apiKeyRepository: $0)
        }

        return OrgUsageViewModel(
            fetchOrgUsageSummaryUseCase: fetchOrgUseCase,
            fetchClaudeCodeAnalyticsUseCase: fetchAnalyticsUseCase,
            getAdminKeyUseCase: getAdminKeyUseCase,
            fetchAPIKeyRateLimitsUseCase: fetchRateLimitsUseCase,
            getAnthropicAPIKeyUseCase: getAnthropicAPIKeyUseCase
        )
    }

    // MARK: - Initial State Tests

    @Test("Initial state is noKey")
    func initialStateIsNoKey() {
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let mockOrgUsageRepo = MockOrgUsageRepository()

        let viewModel = makeViewModel(
            mockAdminKeyRepo: mockAdminKeyRepo,
            mockOrgUsageRepo: mockOrgUsageRepo
        )

        #expect(viewModel.state == .noKey)
    }

    // MARK: - Rate Limit Polling Tests

    @Test("startBackgroundRefresh starts rate limit polling when API key is configured without Admin key")
    func startBackgroundRefreshStartsRateLimitPollingWithoutAdminKey() async throws {
        let mockAdminKeyRepo = MockAdminKeyRepository()
        // No Admin key configured

        let mockAPIKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await mockAPIKeyRepo.configure(storedKey: apiKey)

        let mockOrgUsageRepo = MockOrgUsageRepository()
        let mockRateLimitRepo = MockRateLimitRepository()

        let viewModel = makeViewModel(
            mockAdminKeyRepo: mockAdminKeyRepo,
            mockAPIKeyRepo: mockAPIKeyRepo,
            mockOrgUsageRepo: mockOrgUsageRepo,
            mockRateLimitRepo: mockRateLimitRepo
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        // Rate limits should have been fetched independently of Admin key
        let callCount = await mockRateLimitRepo.callCount
        #expect(callCount >= 1)
    }

    @Test("startBackgroundRefresh sets state to noKey when no Admin key, even if API key is present")
    func startBackgroundRefreshSetsNoKeyWhenNoAdminKey() async throws {
        let mockAdminKeyRepo = MockAdminKeyRepository()
        // No Admin key

        let mockAPIKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await mockAPIKeyRepo.configure(storedKey: apiKey)

        let mockOrgUsageRepo = MockOrgUsageRepository()
        let mockRateLimitRepo = MockRateLimitRepository()

        let viewModel = makeViewModel(
            mockAdminKeyRepo: mockAdminKeyRepo,
            mockAPIKeyRepo: mockAPIKeyRepo,
            mockOrgUsageRepo: mockOrgUsageRepo,
            mockRateLimitRepo: mockRateLimitRepo
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        // Org usage state should remain noKey (Admin key not configured)
        #expect(viewModel.state == .noKey)
    }

    @Test("startBackgroundRefresh does not start rate limit polling when API key is not configured")
    func startBackgroundRefreshDoesNotStartRateLimitPollingWithoutAPIKey() async throws {
        let mockAdminKeyRepo = MockAdminKeyRepository()
        // No Admin key

        let mockAPIKeyRepo = MockAPIKeyRepository()
        // No API key stored

        let mockOrgUsageRepo = MockOrgUsageRepository()
        let mockRateLimitRepo = MockRateLimitRepository()

        let viewModel = makeViewModel(
            mockAdminKeyRepo: mockAdminKeyRepo,
            mockAPIKeyRepo: mockAPIKeyRepo,
            mockOrgUsageRepo: mockOrgUsageRepo,
            mockRateLimitRepo: mockRateLimitRepo
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        // Rate limit repository should not have been called
        let callCount = await mockRateLimitRepo.callCount
        #expect(callCount == 0)
    }

    @Test("Rate limits are fetched before Admin key check during startBackgroundRefresh")
    func rateLimitsFetchedBeforeAdminKeyCheck() async throws {
        let mockAdminKeyRepo = MockAdminKeyRepository()
        // No Admin key — so Admin path exits early

        let mockAPIKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await mockAPIKeyRepo.configure(storedKey: apiKey)

        let mockOrgUsageRepo = MockOrgUsageRepository()
        let mockRateLimitRepo = MockRateLimitRepository()

        let viewModel = makeViewModel(
            mockAdminKeyRepo: mockAdminKeyRepo,
            mockAPIKeyRepo: mockAPIKeyRepo,
            mockOrgUsageRepo: mockOrgUsageRepo,
            mockRateLimitRepo: mockRateLimitRepo
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        // Even though Admin key is absent (state == .noKey), rate limits were fetched
        #expect(viewModel.state == .noKey)
        let callCount = await mockRateLimitRepo.callCount
        #expect(callCount >= 1)
        // rateLimits property should be populated
        #expect(viewModel.rateLimits != nil)
    }

    // MARK: - Admin Key Present Tests

    @Test("startBackgroundRefresh sets loading then loaded state when Admin key is configured")
    func startBackgroundRefreshLoadsDataWhenAdminKeyConfigured() async throws {
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let adminKey = try AdminAPIKey.create("sk-ant-admin-testkey1234567890")
        await mockAdminKeyRepo.configure(storedKey: adminKey)

        let mockOrgUsageRepo = MockOrgUsageRepository()
        // Default empty usage/cost buckets → should produce a zero-sum summary

        let viewModel = makeViewModel(
            mockAdminKeyRepo: mockAdminKeyRepo,
            mockOrgUsageRepo: mockOrgUsageRepo
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.state == .loaded)
    }

    @Test("startBackgroundRefresh with Admin key and API key fetches both org usage and rate limits")
    func startBackgroundRefreshFetchesBothOrgUsageAndRateLimits() async throws {
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let adminKey = try AdminAPIKey.create("sk-ant-admin-testkey1234567890")
        await mockAdminKeyRepo.configure(storedKey: adminKey)

        let mockAPIKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await mockAPIKeyRepo.configure(storedKey: apiKey)

        let mockOrgUsageRepo = MockOrgUsageRepository()
        let mockRateLimitRepo = MockRateLimitRepository()

        let viewModel = makeViewModel(
            mockAdminKeyRepo: mockAdminKeyRepo,
            mockAPIKeyRepo: mockAPIKeyRepo,
            mockOrgUsageRepo: mockOrgUsageRepo,
            mockRateLimitRepo: mockRateLimitRepo
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        // Org usage loaded
        #expect(viewModel.state == .loaded)
        // Rate limits fetched
        let callCount = await mockRateLimitRepo.callCount
        #expect(callCount >= 1)
        #expect(viewModel.rateLimits != nil)
    }

    // MARK: - Guard: startBackgroundRefresh idempotency (Admin key present)

    @Test("startBackgroundRefresh with Admin key is a no-op if called a second time")
    func startBackgroundRefreshWithAdminKeyIsIdempotent() async throws {
        let mockAdminKeyRepo = MockAdminKeyRepository()
        let adminKey = try AdminAPIKey.create("sk-ant-admin-testkey1234567890")
        await mockAdminKeyRepo.configure(storedKey: adminKey)

        let mockAPIKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await mockAPIKeyRepo.configure(storedKey: apiKey)

        let mockOrgUsageRepo = MockOrgUsageRepository()
        let mockRateLimitRepo = MockRateLimitRepository()

        let viewModel = makeViewModel(
            mockAdminKeyRepo: mockAdminKeyRepo,
            mockAPIKeyRepo: mockAPIKeyRepo,
            mockOrgUsageRepo: mockOrgUsageRepo,
            mockRateLimitRepo: mockRateLimitRepo
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(100))
        let callCountAfterFirst = await mockRateLimitRepo.callCount

        // Second call — guard `usageRefreshTask == nil` blocks re-entry when task is running
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(100))
        let callCountAfterSecond = await mockRateLimitRepo.callCount

        // No additional rate-limit fetch from the second startBackgroundRefresh call
        #expect(callCountAfterSecond == callCountAfterFirst)
    }
}
