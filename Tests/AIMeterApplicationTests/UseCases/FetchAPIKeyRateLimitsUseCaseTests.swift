import Foundation
import Testing
@testable import AIMeterApplication
import AIMeterDomain

/// Tests for FetchAPIKeyRateLimitsUseCase — orchestrates key lookup and rate limit fetching.
@Suite("FetchAPIKeyRateLimitsUseCase")
struct FetchAPIKeyRateLimitsUseCaseTests {

    // MARK: - Success Path Tests

    @Test("execute returns entity when API key is configured")
    func executeReturnsEntityWhenKeyConfigured() async throws {
        // Arrange
        let mockAPIKeyRepo = MockAPIKeyRepository()
        let mockRateLimitRepo = MockRateLimitRepository()
        let storedKey = try AnthropicAPIKey.create("sk-ant-api03-abc123def456789xyz")
        let expectedEntity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000
        )
        await mockAPIKeyRepo.configure(getResult: storedKey)
        await mockRateLimitRepo.configure(fetchResult: expectedEntity)

        let useCase = FetchAPIKeyRateLimitsUseCase(
            apiKeyRepository: mockAPIKeyRepo,
            rateLimitRepository: mockRateLimitRepo
        )

        // Act
        let result = try await useCase.execute()

        // Assert
        #expect(result == expectedEntity)
    }

    @Test("execute passes key value to rate limit repository")
    func executePassesKeyValueToRateLimitRepository() async throws {
        // Arrange
        let mockAPIKeyRepo = MockAPIKeyRepository()
        let mockRateLimitRepo = MockRateLimitRepository()
        let keyValue = "sk-ant-api03-abc123def456789xyz"
        let storedKey = try AnthropicAPIKey.create(keyValue)
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 100,
            requestsRemaining: 100,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )
        await mockAPIKeyRepo.configure(getResult: storedKey)
        await mockRateLimitRepo.configure(fetchResult: entity)

        let useCase = FetchAPIKeyRateLimitsUseCase(
            apiKeyRepository: mockAPIKeyRepo,
            rateLimitRepository: mockRateLimitRepo
        )

        // Act
        _ = try await useCase.execute()

        // Assert — rate limit repo receives exact key value
        #expect(await mockRateLimitRepo.lastFetchedAPIKey == keyValue)
        #expect(await mockRateLimitRepo.fetchCallCount == 1)
    }

    @Test("execute calls apiKeyRepository.get exactly once")
    func executeCallsAPIKeyRepositoryGetOnce() async throws {
        // Arrange
        let mockAPIKeyRepo = MockAPIKeyRepository()
        let mockRateLimitRepo = MockRateLimitRepository()
        let storedKey = try AnthropicAPIKey.create("sk-ant-api03-abc123def456789xyz")
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )
        await mockAPIKeyRepo.configure(getResult: storedKey)
        await mockRateLimitRepo.configure(fetchResult: entity)

        let useCase = FetchAPIKeyRateLimitsUseCase(
            apiKeyRepository: mockAPIKeyRepo,
            rateLimitRepository: mockRateLimitRepo
        )

        // Act
        _ = try await useCase.execute()

        // Assert
        #expect(await mockAPIKeyRepo.getCallCount == 1)
    }

    // MARK: - Failure Path Tests

    @Test("execute throws apiKeyNotFound when no key is configured")
    func executeThrowsAPIKeyNotFoundWhenNoKey() async {
        // Arrange
        let mockAPIKeyRepo = MockAPIKeyRepository()
        let mockRateLimitRepo = MockRateLimitRepository()
        await mockAPIKeyRepo.configure(getResult: nil)

        let useCase = FetchAPIKeyRateLimitsUseCase(
            apiKeyRepository: mockAPIKeyRepo,
            rateLimitRepository: mockRateLimitRepo
        )

        // Act & Assert
        await #expect(throws: DomainError.apiKeyNotFound) {
            try await useCase.execute()
        }
    }

    @Test("execute does not call rate limit repository when no key configured")
    func executeDoesNotCallRateLimitRepoWhenNoKey() async {
        // Arrange
        let mockAPIKeyRepo = MockAPIKeyRepository()
        let mockRateLimitRepo = MockRateLimitRepository()
        await mockAPIKeyRepo.configure(getResult: nil)

        let useCase = FetchAPIKeyRateLimitsUseCase(
            apiKeyRepository: mockAPIKeyRepo,
            rateLimitRepository: mockRateLimitRepo
        )

        // Act — ignore thrown error
        _ = try? await useCase.execute()

        // Assert — rate limit repo must not be called
        #expect(await mockRateLimitRepo.fetchCallCount == 0)
    }

    @Test("execute propagates errors from rate limit repository")
    func executePropagatesRateLimitRepositoryErrors() async throws {
        // Arrange
        let mockAPIKeyRepo = MockAPIKeyRepository()
        let mockRateLimitRepo = MockRateLimitRepository()
        let storedKey = try AnthropicAPIKey.create("sk-ant-api03-abc123def456789xyz")
        await mockAPIKeyRepo.configure(getResult: storedKey)
        await mockRateLimitRepo.configure(fetchError: TestFetchError.networkFailed)

        let useCase = FetchAPIKeyRateLimitsUseCase(
            apiKeyRepository: mockAPIKeyRepo,
            rateLimitRepository: mockRateLimitRepo
        )

        // Act & Assert
        await #expect(throws: TestFetchError.networkFailed) {
            try await useCase.execute()
        }
    }
}

// MARK: - Test Helpers

private enum TestFetchError: Error, Equatable {
    case networkFailed
}

// MARK: - Mock: APIKeyRepository

private actor MockAPIKeyRepository: APIKeyRepository {
    var getCallCount = 0
    var getResult: AnthropicAPIKey? = nil

    func configure(getResult: AnthropicAPIKey?? = nil) {
        if let getResult { self.getResult = getResult }
    }

    func save(_ key: AnthropicAPIKey) async throws {}

    func get() async -> AnthropicAPIKey? {
        getCallCount += 1
        return getResult
    }

    func delete() async {}

    func exists() async -> Bool { false }
}

// MARK: - Mock: RateLimitRepository

private actor MockRateLimitRepository: RateLimitRepository {
    var fetchCallCount = 0
    var lastFetchedAPIKey: String?
    var fetchResult: APIKeyRateLimitEntity?
    var fetchError: (any Error)?

    func configure(
        fetchResult: APIKeyRateLimitEntity? = nil,
        fetchError: (any Error)? = nil
    ) {
        if let fetchResult { self.fetchResult = fetchResult }
        if let fetchError { self.fetchError = fetchError }
    }

    func fetchRateLimits(apiKey: String) async throws -> APIKeyRateLimitEntity {
        fetchCallCount += 1
        lastFetchedAPIKey = apiKey
        if let error = fetchError { throw error }
        return fetchResult ?? APIKeyRateLimitEntity(
            requestsLimit: 0,
            requestsRemaining: 0,
            inputTokensLimit: 0,
            inputTokensRemaining: 0,
            outputTokensLimit: 0,
            outputTokensRemaining: 0
        )
    }
}
