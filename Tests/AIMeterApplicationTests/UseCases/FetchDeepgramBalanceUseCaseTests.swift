import Foundation
import Testing
@testable import AIMeterApplication
import AIMeterDomain

@Suite("FetchDeepgramBalanceUseCase")
struct FetchDeepgramBalanceUseCaseTests {

    // MARK: - Success Path Tests

    @Test("Execute calls repository with correct apiKey")
    func executeCallsRepositoryWithCorrectApiKey() async throws {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        let expectedBalance = DeepgramBalance(amount: 187.50, units: "usd")
        await mockRepo.configure(result: expectedBalance)
        let useCase = FetchDeepgramBalanceUseCase(deepgramAPIRepository: mockRepo)

        // Act
        _ = try await useCase.execute(apiKey: "dgp-test-key-123")

        // Assert
        #expect(await mockRepo.fetchBalanceCallCount == 1)
        #expect(await mockRepo.lastApiKey == "dgp-test-key-123")
    }

    @Test("Execute returns DeepgramBalance from repository")
    func executeReturnsBalance() async throws {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        let expectedBalance = DeepgramBalance(amount: 42.99, units: "usd")
        await mockRepo.configure(result: expectedBalance)
        let useCase = FetchDeepgramBalanceUseCase(deepgramAPIRepository: mockRepo)

        // Act
        let result = try await useCase.execute(apiKey: "valid-key")

        // Assert
        #expect(result.amount == 42.99)
        #expect(result.units == "usd")
        #expect(result == expectedBalance)
    }

    @Test("Execute propagates repository errors")
    func executePropagatesErrors() async {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        await mockRepo.configure(error: TranscriptionError.authenticationFailed)
        let useCase = FetchDeepgramBalanceUseCase(deepgramAPIRepository: mockRepo)

        // Act & Assert
        await #expect(throws: TranscriptionError.authenticationFailed) {
            try await useCase.execute(apiKey: "invalid-key")
        }

        #expect(await mockRepo.fetchBalanceCallCount == 1)
    }
}

// MARK: - Mock Implementation

private actor MockDeepgramAPIRepository: DeepgramAPIRepository {
    var fetchBalanceCallCount = 0
    var lastApiKey: String?
    var fetchBalanceResult: DeepgramBalance?
    var fetchBalanceError: (any Error)?

    func configure(result: DeepgramBalance? = nil, error: (any Error)? = nil) {
        self.fetchBalanceResult = result
        self.fetchBalanceError = error
    }

    func fetchBalance(apiKey: String) async throws -> DeepgramBalance {
        fetchBalanceCallCount += 1
        lastApiKey = apiKey
        if let error = fetchBalanceError { throw error }
        return fetchBalanceResult ?? DeepgramBalance(amount: 0, units: "usd")
    }

    func fetchUsage(apiKey: String, start: Date, end: Date) async throws -> (totalSeconds: Double, requestCount: Int) {
        (totalSeconds: 0, requestCount: 0)
    }
}
