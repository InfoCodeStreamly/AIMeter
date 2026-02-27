import Foundation
import Testing
@testable import AIMeterApplication
import AIMeterDomain

@Suite("FetchDeepgramUsageUseCase")
struct FetchDeepgramUsageUseCaseTests {

    // MARK: - Success Path Tests

    @Test("execute returns DeepgramUsageStats with correct totalSeconds")
    func executeReturnsCorrectTotalSeconds() async throws {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        await mockRepo.configure(
            usageResult: (totalSeconds: 245.0, requestCount: 8),
            balanceResult: DeepgramBalance(amount: 100.0, units: "usd")
        )
        let useCase = FetchDeepgramUsageUseCase(deepgramAPIRepository: mockRepo)

        // Act
        let result = try await useCase.execute(apiKey: "dgp-test-key")

        // Assert
        #expect(result.totalSeconds == 245.0)
    }

    @Test("execute returns DeepgramUsageStats with correct requestCount")
    func executeReturnsCorrectRequestCount() async throws {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        await mockRepo.configure(
            usageResult: (totalSeconds: 180.0, requestCount: 12),
            balanceResult: DeepgramBalance(amount: 50.0, units: "usd")
        )
        let useCase = FetchDeepgramUsageUseCase(deepgramAPIRepository: mockRepo)

        // Act
        let result = try await useCase.execute(apiKey: "dgp-test-key")

        // Assert
        #expect(result.requestCount == 12)
    }

    @Test("execute returns DeepgramUsageStats with correct balance")
    func executeReturnsCorrectBalance() async throws {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        let expectedBalance = DeepgramBalance(amount: 187.50, units: "usd")
        await mockRepo.configure(
            usageResult: (totalSeconds: 60.0, requestCount: 3),
            balanceResult: expectedBalance
        )
        let useCase = FetchDeepgramUsageUseCase(deepgramAPIRepository: mockRepo)

        // Act
        let result = try await useCase.execute(apiKey: "dgp-test-key")

        // Assert
        #expect(result.balance == expectedBalance)
        #expect(result.balance.amount == 187.50)
        #expect(result.balance.units == "usd")
    }

    @Test("execute calls both fetchUsage and fetchBalance once")
    func executeCallsBothMethods() async throws {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        await mockRepo.configure(
            usageResult: (totalSeconds: 60.0, requestCount: 1),
            balanceResult: DeepgramBalance(amount: 10.0, units: "usd")
        )
        let useCase = FetchDeepgramUsageUseCase(deepgramAPIRepository: mockRepo)

        // Act
        _ = try await useCase.execute(apiKey: "test-key")

        // Assert
        #expect(await mockRepo.fetchUsageCallCount == 1)
        #expect(await mockRepo.fetchBalanceCallCount == 1)
    }

    @Test("execute passes apiKey to both repository methods")
    func executePassesApiKeyToBothMethods() async throws {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        await mockRepo.configure(
            usageResult: (totalSeconds: 30.0, requestCount: 2),
            balanceResult: DeepgramBalance(amount: 25.0, units: "usd")
        )
        let useCase = FetchDeepgramUsageUseCase(deepgramAPIRepository: mockRepo)

        // Act
        _ = try await useCase.execute(apiKey: "dgp-my-specific-key")

        // Assert
        #expect(await mockRepo.lastUsageApiKey == "dgp-my-specific-key")
        #expect(await mockRepo.lastBalanceApiKey == "dgp-my-specific-key")
    }

    @Test("execute sets periodStart to beginning of current month")
    func executeSetsPeriodStartToBeginningOfMonth() async throws {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        await mockRepo.configure(
            usageResult: (totalSeconds: 60.0, requestCount: 1),
            balanceResult: DeepgramBalance(amount: 10.0, units: "usd")
        )
        let useCase = FetchDeepgramUsageUseCase(deepgramAPIRepository: mockRepo)

        // Act
        let result = try await useCase.execute(apiKey: "test-key")

        // Assert — periodStart must be the 1st of the current month at 00:00:00
        let calendar = Calendar.current
        let now = Date()
        let expectedStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        #expect(result.periodStart == expectedStart)
    }

    @Test("execute passes start date as beginning of current month to fetchUsage")
    func executePassesStartDateToFetchUsage() async throws {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        await mockRepo.configure(
            usageResult: (totalSeconds: 60.0, requestCount: 1),
            balanceResult: DeepgramBalance(amount: 10.0, units: "usd")
        )
        let useCase = FetchDeepgramUsageUseCase(deepgramAPIRepository: mockRepo)

        // Act
        _ = try await useCase.execute(apiKey: "test-key")

        // Assert — start date passed to fetchUsage equals start of current month
        let calendar = Calendar.current
        let now = Date()
        let expectedStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let capturedStart = await mockRepo.lastUsageStartDate
        #expect(capturedStart == expectedStart)
    }

    @Test("execute passes end date after start date to fetchUsage")
    func executePassesEndDateAfterStart() async throws {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        await mockRepo.configure(
            usageResult: (totalSeconds: 60.0, requestCount: 1),
            balanceResult: DeepgramBalance(amount: 10.0, units: "usd")
        )
        let useCase = FetchDeepgramUsageUseCase(deepgramAPIRepository: mockRepo)

        // Act
        _ = try await useCase.execute(apiKey: "test-key")

        // Assert — end date must be after start date
        let capturedStart = await mockRepo.lastUsageStartDate
        let capturedEnd = await mockRepo.lastUsageEndDate
        if let start = capturedStart, let end = capturedEnd {
            #expect(end > start)
        } else {
            #expect(Bool(false), "Expected start and end dates to be captured")
        }
    }

    // MARK: - Error Propagation Tests

    @Test("execute propagates error from fetchUsage")
    func executePropagatesUsageError() async {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        await mockRepo.configure(usageError: TranscriptionError.authenticationFailed)
        let useCase = FetchDeepgramUsageUseCase(deepgramAPIRepository: mockRepo)

        // Act & Assert
        await #expect(throws: TranscriptionError.authenticationFailed) {
            try await useCase.execute(apiKey: "bad-key")
        }
    }

    @Test("execute propagates error from fetchBalance")
    func executePropagatesBalanceError() async {
        // Arrange
        let mockRepo = MockDeepgramAPIRepository()
        await mockRepo.configure(
            usageResult: (totalSeconds: 60.0, requestCount: 1),
            balanceError: TranscriptionError.authenticationFailed
        )
        let useCase = FetchDeepgramUsageUseCase(deepgramAPIRepository: mockRepo)

        // Act & Assert
        await #expect(throws: TranscriptionError.authenticationFailed) {
            try await useCase.execute(apiKey: "bad-key")
        }
    }
}

// MARK: - Mock Implementation

private actor MockDeepgramAPIRepository: DeepgramAPIRepository {
    var fetchUsageCallCount = 0
    var fetchBalanceCallCount = 0
    var lastUsageApiKey: String?
    var lastBalanceApiKey: String?
    var lastUsageStartDate: Date?
    var lastUsageEndDate: Date?

    var usageResult: (totalSeconds: Double, requestCount: Int)?
    var usageError: (any Error)?
    var balanceResult: DeepgramBalance?
    var balanceError: (any Error)?

    func configure(
        usageResult: (totalSeconds: Double, requestCount: Int)? = nil,
        usageError: (any Error)? = nil,
        balanceResult: DeepgramBalance? = nil,
        balanceError: (any Error)? = nil
    ) {
        self.usageResult = usageResult
        self.usageError = usageError
        self.balanceResult = balanceResult
        self.balanceError = balanceError
    }

    func fetchUsage(apiKey: String, start: Date, end: Date) async throws -> (totalSeconds: Double, requestCount: Int) {
        fetchUsageCallCount += 1
        lastUsageApiKey = apiKey
        lastUsageStartDate = start
        lastUsageEndDate = end
        if let error = usageError { throw error }
        return usageResult ?? (totalSeconds: 0.0, requestCount: 0)
    }

    func fetchBalance(apiKey: String) async throws -> DeepgramBalance {
        fetchBalanceCallCount += 1
        lastBalanceApiKey = apiKey
        if let error = balanceError { throw error }
        return balanceResult ?? DeepgramBalance(amount: 0.0, units: "usd")
    }
}
