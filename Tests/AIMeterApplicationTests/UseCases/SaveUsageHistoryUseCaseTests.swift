import AIMeterDomain
import Foundation
import Testing

@testable import AIMeterApplication

/// Tests for SaveUsageHistoryUseCase following Clean Architecture principles
@Suite
struct SaveUsageHistoryUseCaseTests {

    // MARK: - Success Path Tests

    @Test("Execute saves history entry when session and weekly limits present")
    func executeSavesWhenValidUsages() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let useCase = SaveUsageHistoryUseCase(historyRepository: mockRepo)

        let usages = [
            UsageEntity(
                type: .session, percentage: Percentage.clamped(45.5), resetTime: .defaultSession),
            UsageEntity(
                type: .weekly, percentage: Percentage.clamped(30.0), resetTime: .defaultSession),
        ]

        // Act
        await useCase.execute(usages: usages)

        // Assert
        #expect(await mockRepo.saveCallCount == 1)
        let saved = await mockRepo.lastSavedEntry
        #expect(saved != nil)
        #expect(saved?.sessionPercentage == 45.5)
        #expect(saved?.weeklyPercentage == 30.0)
    }

    @Test("Execute saves with all four usage types present")
    func executeSavesWithAllUsageTypes() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let useCase = SaveUsageHistoryUseCase(historyRepository: mockRepo)

        let usages = [
            UsageEntity(
                type: .session, percentage: Percentage.clamped(50.0), resetTime: .defaultSession),
            UsageEntity(
                type: .weekly, percentage: Percentage.clamped(40.0), resetTime: .defaultSession),
            UsageEntity(
                type: .opus, percentage: Percentage.clamped(80.0), resetTime: .defaultSession),
            UsageEntity(
                type: .sonnet, percentage: Percentage.clamped(60.0), resetTime: .defaultSession),
        ]

        // Act
        await useCase.execute(usages: usages)

        // Assert
        #expect(await mockRepo.saveCallCount == 1)
        let saved = await mockRepo.lastSavedEntry
        #expect(saved != nil)
        #expect(saved?.sessionPercentage == 50.0)
        #expect(saved?.weeklyPercentage == 40.0)
    }

    @Test("Execute saves zero percentages correctly")
    func executeSavesZeroPercentages() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let useCase = SaveUsageHistoryUseCase(historyRepository: mockRepo)

        let usages = [
            UsageEntity(
                type: .session, percentage: Percentage.clamped(0.0), resetTime: .defaultSession),
            UsageEntity(
                type: .weekly, percentage: Percentage.clamped(0.0), resetTime: .defaultSession),
        ]

        // Act
        await useCase.execute(usages: usages)

        // Assert
        #expect(await mockRepo.saveCallCount == 1)
        let saved = await mockRepo.lastSavedEntry
        #expect(saved?.sessionPercentage == 0.0)
        #expect(saved?.weeklyPercentage == 0.0)
    }

    @Test("Execute saves 100 percent usage correctly")
    func executeSaves100Percent() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let useCase = SaveUsageHistoryUseCase(historyRepository: mockRepo)

        let usages = [
            UsageEntity(
                type: .session, percentage: Percentage.clamped(100.0), resetTime: .defaultSession),
            UsageEntity(
                type: .weekly, percentage: Percentage.clamped(100.0), resetTime: .defaultSession),
        ]

        // Act
        await useCase.execute(usages: usages)

        // Assert
        #expect(await mockRepo.saveCallCount == 1)
        let saved = await mockRepo.lastSavedEntry
        #expect(saved?.sessionPercentage == 100.0)
        #expect(saved?.weeklyPercentage == 100.0)
    }

    // MARK: - Edge Case Tests

    @Test("Execute does nothing when session limit missing")
    func executeDoesNothingWhenNoSession() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let useCase = SaveUsageHistoryUseCase(historyRepository: mockRepo)

        let usages = [
            UsageEntity(
                type: .weekly, percentage: Percentage.clamped(30.0), resetTime: .defaultSession),
            UsageEntity(
                type: .opus, percentage: Percentage.clamped(50.0), resetTime: .defaultSession),
        ]

        // Act
        await useCase.execute(usages: usages)

        // Assert
        #expect(await mockRepo.saveCallCount == 0)
        #expect(await mockRepo.lastSavedEntry == nil)
    }

    @Test("Execute does nothing when weekly limit missing")
    func executeDoesNothingWhenNoWeekly() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let useCase = SaveUsageHistoryUseCase(historyRepository: mockRepo)

        let usages = [
            UsageEntity(
                type: .session, percentage: Percentage.clamped(45.0), resetTime: .defaultSession),
            UsageEntity(
                type: .sonnet, percentage: Percentage.clamped(60.0), resetTime: .defaultSession),
        ]

        // Act
        await useCase.execute(usages: usages)

        // Assert
        #expect(await mockRepo.saveCallCount == 0)
        #expect(await mockRepo.lastSavedEntry == nil)
    }

    @Test("Execute does nothing when empty array provided")
    func executeDoesNothingWhenEmptyArray() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let useCase = SaveUsageHistoryUseCase(historyRepository: mockRepo)

        // Act
        await useCase.execute(usages: [])

        // Assert
        #expect(await mockRepo.saveCallCount == 0)
        #expect(await mockRepo.lastSavedEntry == nil)
    }

    @Test("Execute does nothing when only opus and sonnet present")
    func executeDoesNothingWithOnlyModelLimits() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let useCase = SaveUsageHistoryUseCase(historyRepository: mockRepo)

        let usages = [
            UsageEntity(
                type: .opus, percentage: Percentage.clamped(80.0), resetTime: .defaultSession),
            UsageEntity(
                type: .sonnet, percentage: Percentage.clamped(70.0), resetTime: .defaultSession),
        ]

        // Act
        await useCase.execute(usages: usages)

        // Assert
        #expect(await mockRepo.saveCallCount == 0)
        #expect(await mockRepo.lastSavedEntry == nil)
    }

    @Test("Execute handles duplicate usage types by using first occurrence")
    func executeHandlesDuplicateTypes() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let useCase = SaveUsageHistoryUseCase(historyRepository: mockRepo)

        let usages = [
            UsageEntity(
                type: .session, percentage: Percentage.clamped(45.0), resetTime: .defaultSession),
            UsageEntity(
                type: .session, percentage: Percentage.clamped(55.0), resetTime: .defaultSession),  // duplicate
            UsageEntity(
                type: .weekly, percentage: Percentage.clamped(30.0), resetTime: .defaultSession),
        ]

        // Act
        await useCase.execute(usages: usages)

        // Assert
        #expect(await mockRepo.saveCallCount == 1)
        let saved = await mockRepo.lastSavedEntry
        // Should use first occurrence (45.0)
        #expect(saved?.sessionPercentage == 45.0)
    }
}

// MARK: - Mock Implementation

/// Mock implementation of UsageHistoryRepository for testing
private actor MockUsageHistoryRepository: UsageHistoryRepository {
    var saveCallCount = 0
    var getHistoryCallCount = 0
    var getDailyHistoryCallCount = 0
    var clearOldEntriesCallCount = 0

    var lastSavedEntry: UsageHistoryEntry?
    var getHistoryResult: [UsageHistoryEntry] = []
    var getDailyHistoryResult: [UsageHistoryEntry] = []

    func save(_ entry: UsageHistoryEntry) async {
        saveCallCount += 1
        lastSavedEntry = entry
    }

    func getHistory(days: Int) async -> [UsageHistoryEntry] {
        getHistoryCallCount += 1
        return getHistoryResult
    }

    func getDailyHistory(days: Int) async -> [UsageHistoryEntry] {
        getDailyHistoryCallCount += 1
        return getDailyHistoryResult
    }

    func getAggregatedHistory(days: Int, granularity: TimeGranularity) async -> [UsageHistoryEntry]
    {
        getHistoryCallCount += 1
        return getHistoryResult
    }

    func clearOldEntries(olderThan days: Int) async {
        clearOldEntriesCallCount += 1
    }
}
