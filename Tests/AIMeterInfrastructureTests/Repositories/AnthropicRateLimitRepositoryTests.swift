import Foundation
import Testing
@testable import AIMeterInfrastructure
import AIMeterDomain

/// Tests for AnthropicRateLimitRepository — delegates to client and returns entity.
@Suite("AnthropicRateLimitRepository")
struct AnthropicRateLimitRepositoryTests {

    // MARK: - fetchRateLimits Tests

    @Test("fetchRateLimits delegates to client with provided api key")
    func fetchRateLimitsDelegatesToClientWithAPIKey() async throws {
        // Arrange
        let mockClient = MockAnthropicRateLimitClient()
        let expectedEntity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000
        )
        await mockClient.configure(fetchResult: expectedEntity)
        let repo = AnthropicRateLimitRepository(rateLimitClient: mockClient)

        // Act
        _ = try await repo.fetchRateLimits(apiKey: "sk-ant-api03-abc123def456789xyz")

        // Assert
        #expect(await mockClient.fetchCallCount == 1)
        #expect(await mockClient.lastAPIKey == "sk-ant-api03-abc123def456789xyz")
    }

    @Test("fetchRateLimits returns entity from client unchanged")
    func fetchRateLimitsReturnsEntityFromClient() async throws {
        // Arrange
        let mockClient = MockAnthropicRateLimitClient()
        let expectedEntity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            requestsResetTime: nil,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            inputTokensResetTime: nil,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000,
            outputTokensResetTime: nil
        )
        await mockClient.configure(fetchResult: expectedEntity)
        let repo = AnthropicRateLimitRepository(rateLimitClient: mockClient)

        // Act
        let result = try await repo.fetchRateLimits(apiKey: "sk-ant-api03-abc123def456789xyz")

        // Assert
        #expect(result == expectedEntity)
    }

    @Test("fetchRateLimits propagates errors from client")
    func fetchRateLimitsPropagatesClientErrors() async throws {
        // Arrange
        let mockClient = MockAnthropicRateLimitClient()
        await mockClient.configure(fetchError: TestRateLimitError.unauthorized)
        let repo = AnthropicRateLimitRepository(rateLimitClient: mockClient)

        // Act & Assert
        await #expect(throws: TestRateLimitError.unauthorized) {
            try await repo.fetchRateLimits(apiKey: "sk-ant-api03-abc123def456789xyz")
        }
    }

    @Test("fetchRateLimits passes different api key values correctly")
    func fetchRateLimitsPassesDifferentAPIKeys() async throws {
        // Arrange
        let mockClient = MockAnthropicRateLimitClient()
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 100,
            requestsRemaining: 100,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )
        await mockClient.configure(fetchResult: entity)
        let repo = AnthropicRateLimitRepository(rateLimitClient: mockClient)
        let differentKey = "sk-ant-api03-different-key-xyz789"

        // Act
        _ = try await repo.fetchRateLimits(apiKey: differentKey)

        // Assert
        #expect(await mockClient.lastAPIKey == differentKey)
    }
}

// MARK: - Test Helpers

private enum TestRateLimitError: Error, Equatable {
    case unauthorized
    case networkFailed
}

// MARK: - Mock: AnthropicRateLimitClient

private actor MockAnthropicRateLimitClient: RateLimitClientProtocol {
    var fetchCallCount = 0
    var lastAPIKey: String?
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
        lastAPIKey = apiKey
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
