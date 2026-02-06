import Testing
@testable import AIMeterApplication
import AIMeterDomain
import Foundation

/// Tests for GetExtraUsageUseCase following Clean Architecture principles
@Suite
struct GetExtraUsageUseCaseTests {

    // MARK: - Success Path Tests

    @Test("Execute returns extra usage when available")
    func executeReturnsExtraUsage() async throws {
        // Arrange
        let mockRepo = MockUsageRepository()
        let expectedExtra = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 15.0,
            utilization: Percentage.clamped(15.0)
        )
        await mockRepo.configure(extraUsage: expectedExtra)

        let useCase = GetExtraUsageUseCase(usageRepository: mockRepo)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result != nil)
        #expect(result?.isEnabled == true)
        #expect(result?.usedCredits == 15.0)
        #expect(result?.monthlyLimit == 100.0)
        #expect(await mockRepo.getExtraUsageCallCount == 1)
    }

    @Test("Execute returns nil when extra usage not available")
    func executeReturnsNilWhenNotAvailable() async throws {
        // Arrange
        let mockRepo = MockUsageRepository()
        await mockRepo.configure(extraUsage: nil)

        let useCase = GetExtraUsageUseCase(usageRepository: mockRepo)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result == nil)
        #expect(await mockRepo.getExtraUsageCallCount == 1)
    }

    @Test("Execute returns zero usage correctly")
    func executeReturnsZeroUsage() async throws {
        // Arrange
        let mockRepo = MockUsageRepository()
        let expectedExtra = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 0,
            utilization: Percentage.clamped(0)
        )
        await mockRepo.configure(extraUsage: expectedExtra)

        let useCase = GetExtraUsageUseCase(usageRepository: mockRepo)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result != nil)
        #expect(result?.isEnabled == true)
        #expect(result?.usedCredits == 0)
        #expect(result?.monthlyLimit == 100.0)
    }

    @Test("Execute returns full usage correctly")
    func executeReturnsFullUsage() async throws {
        // Arrange
        let mockRepo = MockUsageRepository()
        let expectedExtra = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 100.0,
            utilization: Percentage.clamped(100.0)
        )
        await mockRepo.configure(extraUsage: expectedExtra)

        let useCase = GetExtraUsageUseCase(usageRepository: mockRepo)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result != nil)
        #expect(result?.usedCredits == 100.0)
        #expect(result?.monthlyLimit == 100.0)
        #expect(result?.utilization.value == 100.0)
    }

    @Test("Execute returns over-limit usage correctly")
    func executeReturnsOverLimitUsage() async throws {
        // Arrange
        let mockRepo = MockUsageRepository()
        let expectedExtra = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 120.0,
            utilization: Percentage.clamped(120.0) // Should be clamped to 100
        )
        await mockRepo.configure(extraUsage: expectedExtra)

        let useCase = GetExtraUsageUseCase(usageRepository: mockRepo)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result != nil)
        #expect(result?.usedCredits == 120.0)
        #expect(result?.monthlyLimit == 100.0)
        // Percentage should be clamped to 100
        #expect(result?.utilization.value == 100.0)
    }

    @Test("Execute returns correct utilization percentage")
    func executeReturnsCorrectUtilization() async throws {
        // Arrange
        let mockRepo = MockUsageRepository()
        let expectedExtra = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 25.0,
            utilization: Percentage.clamped(25.0)
        )
        await mockRepo.configure(extraUsage: expectedExtra)

        let useCase = GetExtraUsageUseCase(usageRepository: mockRepo)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result != nil)
        #expect(result?.utilization.value == 25.0)
    }

    @Test("Execute delegates to repository correctly")
    func executeDelegatesToRepository() async throws {
        // Arrange
        let mockRepo = MockUsageRepository()
        let useCase = GetExtraUsageUseCase(usageRepository: mockRepo)

        // Act
        _ = await useCase.execute()

        // Assert
        #expect(await mockRepo.getExtraUsageCallCount == 1)
        // Verify ONLY getExtraUsage was called, not other methods
        #expect(await mockRepo.fetchUsageCallCount == 0)
        #expect(await mockRepo.getCachedUsageCallCount == 0)
        #expect(await mockRepo.cacheUsageCallCount == 0)
    }

    @Test("Execute can be called multiple times")
    func executeCanBeCalledMultipleTimes() async throws {
        // Arrange
        let mockRepo = MockUsageRepository()
        let expectedExtra = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 30.0,
            utilization: Percentage.clamped(30.0)
        )
        await mockRepo.configure(extraUsage: expectedExtra)

        let useCase = GetExtraUsageUseCase(usageRepository: mockRepo)

        // Act
        let result1 = await useCase.execute()
        let result2 = await useCase.execute()
        let result3 = await useCase.execute()

        // Assert
        #expect(result1 != nil)
        #expect(result2 != nil)
        #expect(result3 != nil)
        #expect(await mockRepo.getExtraUsageCallCount == 3)
    }
}

// MARK: - Mock Implementation

/// Mock implementation of UsageRepository for testing
private actor MockUsageRepository: UsageRepository {
    var fetchUsageCallCount = 0
    var cacheUsageCallCount = 0
    var getCachedUsageCallCount = 0
    var getExtraUsageCallCount = 0

    var extraUsageResult: ExtraUsageEntity?

    func configure(extraUsage: ExtraUsageEntity?) {
        self.extraUsageResult = extraUsage
    }

    func fetchUsage() async throws -> [UsageEntity] {
        fetchUsageCallCount += 1
        return []
    }

    func getCachedUsage() async -> [UsageEntity] {
        getCachedUsageCallCount += 1
        return []
    }

    func cacheUsage(_ entities: [UsageEntity]) async {
        cacheUsageCallCount += 1
    }

    func getExtraUsage() async -> ExtraUsageEntity? {
        getExtraUsageCallCount += 1
        return extraUsageResult
    }
}
