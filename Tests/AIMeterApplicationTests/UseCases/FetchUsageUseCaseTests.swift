import Testing
@testable import AIMeterApplication
import AIMeterDomain

/// Tests for FetchUsageUseCase following Clean Architecture principles
@Suite
struct FetchUsageUseCaseTests {

    // MARK: - Success Path Tests

    @Test("Execute succeeds when session key exists and repository fetches data")
    func executeSuccessPath() async throws {
        // Arrange
        let mockUsageRepo = MockUsageRepository()
        let mockSessionRepo = MockSessionKeyRepository()
        await mockSessionRepo.configure(existsResult: true)

        let expectedEntities = [
            UsageEntity(type: .session, percentage: Percentage.clamped(45.5), resetTime: .defaultSession),
            UsageEntity(type: .weekly, percentage: Percentage.clamped(30.0), resetTime: .defaultWeekly)
        ]
        await mockUsageRepo.configure(fetchUsageResult: expectedEntities)

        let useCase = FetchUsageUseCase(
            usageRepository: mockUsageRepo,
            sessionKeyRepository: mockSessionRepo
        )

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.count == 2)
        #expect(result[0].type == .session)
        #expect(result[1].type == .weekly)
        #expect(await mockSessionRepo.existsCallCount == 1)
        #expect(await mockUsageRepo.fetchUsageCallCount == 1)
        #expect(await mockUsageRepo.cacheUsageCallCount == 1)
        #expect(await mockUsageRepo.lastCachedEntities?.count == 2)
    }

    @Test("Execute caches fetched usage data")
    func executeCachesData() async throws {
        // Arrange
        let mockUsageRepo = MockUsageRepository()
        let mockSessionRepo = MockSessionKeyRepository()
        await mockSessionRepo.configure(existsResult: true)

        let entities = [
            UsageEntity(type: .opus, percentage: Percentage.clamped(80.0), resetTime: .defaultWeekly)
        ]
        await mockUsageRepo.configure(fetchUsageResult: entities)

        let useCase = FetchUsageUseCase(
            usageRepository: mockUsageRepo,
            sessionKeyRepository: mockSessionRepo
        )

        // Act
        _ = try await useCase.execute()

        // Assert
        #expect(await mockUsageRepo.cacheUsageCallCount == 1)
        let cached = await mockUsageRepo.lastCachedEntities
        #expect(cached?.count == 1)
        #expect(cached?[0].type == .opus)
        #expect(cached?[0].percentage.value == 80.0)
    }

    // MARK: - Error Path Tests

    @Test("Execute throws sessionKeyNotFound when session key missing")
    func executeThrowsWhenNoSessionKey() async throws {
        // Arrange
        let mockUsageRepo = MockUsageRepository()
        let mockSessionRepo = MockSessionKeyRepository()
        await mockSessionRepo.configure(existsResult: false)

        let useCase = FetchUsageUseCase(
            usageRepository: mockUsageRepo,
            sessionKeyRepository: mockSessionRepo
        )

        // Act & Assert
        await #expect(throws: DomainError.sessionKeyNotFound) {
            try await useCase.execute()
        }

        // Verify repository was NOT called when session key missing
        #expect(await mockUsageRepo.fetchUsageCallCount == 0)
        #expect(await mockUsageRepo.cacheUsageCallCount == 0)
    }

    @Test("Execute propagates repository errors")
    func executePropagatesErrors() async throws {
        // Arrange
        let mockUsageRepo = MockUsageRepository()
        let mockSessionRepo = MockSessionKeyRepository()
        await mockSessionRepo.configure(existsResult: true)

        enum TestError: Error, Equatable {
            case networkFailure
        }
        await mockUsageRepo.configure(fetchUsageError: TestError.networkFailure)

        let useCase = FetchUsageUseCase(
            usageRepository: mockUsageRepo,
            sessionKeyRepository: mockSessionRepo
        )

        // Act & Assert
        await #expect(throws: TestError.networkFailure) {
            try await useCase.execute()
        }

        // Verify cache was NOT called when fetch fails
        #expect(await mockUsageRepo.cacheUsageCallCount == 0)
    }

    @Test("Execute handles empty usage array")
    func executeHandlesEmptyArray() async throws {
        // Arrange
        let mockUsageRepo = MockUsageRepository()
        let mockSessionRepo = MockSessionKeyRepository()
        await mockSessionRepo.configure(existsResult: true)
        await mockUsageRepo.configure(fetchUsageResult: [])

        let useCase = FetchUsageUseCase(
            usageRepository: mockUsageRepo,
            sessionKeyRepository: mockSessionRepo
        )

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result.isEmpty)
        #expect(await mockUsageRepo.cacheUsageCallCount == 1)
        #expect(await mockUsageRepo.lastCachedEntities?.isEmpty == true)
    }
}

// MARK: - Mock Implementations

/// Mock implementation of UsageRepository for testing
private actor MockUsageRepository: UsageRepository {
    var fetchUsageCallCount = 0
    var cacheUsageCallCount = 0
    var getCachedUsageCallCount = 0
    var getExtraUsageCallCount = 0

    var fetchUsageResult: [UsageEntity] = []
    var fetchUsageError: (any Error)?
    var cachedUsageResult: [UsageEntity] = []
    var extraUsageResult: ExtraUsageEntity?
    var lastCachedEntities: [UsageEntity]?

    func configure(
        fetchUsageResult: [UsageEntity]? = nil,
        fetchUsageError: (any Error)? = nil,
        cachedUsageResult: [UsageEntity]? = nil,
        extraUsageResult: ExtraUsageEntity?? = nil
    ) {
        if let fetchUsageResult { self.fetchUsageResult = fetchUsageResult }
        if let fetchUsageError { self.fetchUsageError = fetchUsageError }
        if let cachedUsageResult { self.cachedUsageResult = cachedUsageResult }
        if let extraUsageResult { self.extraUsageResult = extraUsageResult }
    }

    func fetchUsage() async throws -> [UsageEntity] {
        fetchUsageCallCount += 1
        if let error = fetchUsageError {
            throw error
        }
        return fetchUsageResult
    }

    func getCachedUsage() async -> [UsageEntity] {
        getCachedUsageCallCount += 1
        return cachedUsageResult
    }

    func cacheUsage(_ entities: [UsageEntity]) async {
        cacheUsageCallCount += 1
        lastCachedEntities = entities
    }

    func getExtraUsage() async -> ExtraUsageEntity? {
        getExtraUsageCallCount += 1
        return extraUsageResult
    }
}

/// Mock implementation of SessionKeyRepository for testing
private actor MockSessionKeyRepository: SessionKeyRepository {
    var saveCallCount = 0
    var getCallCount = 0
    var deleteCallCount = 0
    var existsCallCount = 0
    var validateTokenCallCount = 0

    var existsResult = false
    var getResult: SessionKey?
    var validateTokenError: (any Error)?
    var lastSavedKey: SessionKey?
    var lastValidatedToken: String?

    func configure(
        existsResult: Bool? = nil,
        getResult: SessionKey?? = nil,
        validateTokenError: (any Error)? = nil
    ) {
        if let existsResult { self.existsResult = existsResult }
        if let getResult { self.getResult = getResult }
        if let validateTokenError { self.validateTokenError = validateTokenError }
    }

    func save(_ key: SessionKey) async throws {
        saveCallCount += 1
        lastSavedKey = key
    }

    func get() async -> SessionKey? {
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

    func validateToken(_ token: String) async throws {
        validateTokenCallCount += 1
        lastValidatedToken = token
        if let error = validateTokenError {
            throw error
        }
    }
}
