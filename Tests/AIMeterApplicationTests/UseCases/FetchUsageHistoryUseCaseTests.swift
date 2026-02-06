import Testing
@testable import AIMeterApplication
import AIMeterDomain
import Foundation

/// Tests for FetchUsageHistoryUseCase following Clean Architecture principles
@Suite
struct FetchUsageHistoryUseCaseTests {

    // MARK: - Success Path Tests

    @Test("Execute fetches daily history with default 7 days")
    func executeFetchesWithDefaultDays() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let expectedEntries = createSampleHistory(days: 7)
        await mockRepo.configure(getDailyHistoryResult: expectedEntries)

        let useCase = FetchUsageHistoryUseCase(historyRepository: mockRepo)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result.count == 7)
        #expect(await mockRepo.getDailyHistoryCallCount == 1)
        #expect(await mockRepo.lastRequestedDays == 7)
    }

    @Test("Execute fetches daily history with custom days parameter")
    func executeFetchesWithCustomDays() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let expectedEntries = createSampleHistory(days: 14)
        await mockRepo.configure(getDailyHistoryResult: expectedEntries)

        let useCase = FetchUsageHistoryUseCase(historyRepository: mockRepo)

        // Act
        let result = await useCase.execute(days: 14)

        // Assert
        #expect(result.count == 14)
        #expect(await mockRepo.getDailyHistoryCallCount == 1)
        #expect(await mockRepo.lastRequestedDays == 14)
    }

    @Test("Execute returns empty array when no history available")
    func executeReturnsEmptyWhenNoHistory() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        await mockRepo.configure(getDailyHistoryResult: [])

        let useCase = FetchUsageHistoryUseCase(historyRepository: mockRepo)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result.isEmpty)
        #expect(await mockRepo.getDailyHistoryCallCount == 1)
    }

    @Test("Execute returns sorted entries by timestamp")
    func executeReturnsSortedEntries() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let now = Date()

        let unsortedEntries = [
            UsageHistoryEntry(
                timestamp: now.addingTimeInterval(-86400 * 2),
                sessionPercentage: 30.0,
                weeklyPercentage: 25.0
            ),
            UsageHistoryEntry(
                timestamp: now,
                sessionPercentage: 50.0,
                weeklyPercentage: 45.0
            ),
            UsageHistoryEntry(
                timestamp: now.addingTimeInterval(-86400),
                sessionPercentage: 40.0,
                weeklyPercentage: 35.0
            )
        ]
        await mockRepo.configure(getDailyHistoryResult: unsortedEntries)

        let useCase = FetchUsageHistoryUseCase(historyRepository: mockRepo)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result.count == 3)
        #expect(result[0].sessionPercentage == 30.0)
        #expect(result[1].sessionPercentage == 50.0)
        #expect(result[2].sessionPercentage == 40.0)
    }

    @Test("Execute handles single day history")
    func executeHandlesSingleDay() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let singleEntry = [
            UsageHistoryEntry(
                timestamp: Date(),
                sessionPercentage: 60.0,
                weeklyPercentage: 55.0
            )
        ]
        await mockRepo.configure(getDailyHistoryResult: singleEntry)

        let useCase = FetchUsageHistoryUseCase(historyRepository: mockRepo)

        // Act
        let result = await useCase.execute(days: 1)

        // Assert
        #expect(result.count == 1)
        #expect(result[0].sessionPercentage == 60.0)
        #expect(await mockRepo.lastRequestedDays == 1)
    }

    @Test("Execute handles 30 days history")
    func executeHandles30Days() async throws {
        // Arrange
        let mockRepo = MockUsageHistoryRepository()
        let entries = createSampleHistory(days: 30)
        await mockRepo.configure(getDailyHistoryResult: entries)

        let useCase = FetchUsageHistoryUseCase(historyRepository: mockRepo)

        // Act
        let result = await useCase.execute(days: 30)

        // Assert
        #expect(result.count == 30)
        #expect(await mockRepo.getDailyHistoryCallCount == 1)
        #expect(await mockRepo.lastRequestedDays == 30)
    }

    // MARK: - Helper Methods

    private func createSampleHistory(days: Int) -> [UsageHistoryEntry] {
        let now = Date()
        var entries: [UsageHistoryEntry] = []
        for dayOffset in 0..<days {
            let timestamp = now.addingTimeInterval(-86400 * Double(dayOffset))
            let session = Double(10 + dayOffset * 5)
            let weekly = Double(5 + dayOffset * 3)
            let entry = UsageHistoryEntry(
                timestamp: timestamp,
                sessionPercentage: session,
                weeklyPercentage: weekly
            )
            entries.append(entry)
        }
        return entries
    }
}

// MARK: - Mock Implementation

/// Mock implementation of UsageHistoryRepository for testing
private actor MockUsageHistoryRepository: UsageHistoryRepository {
    var saveCallCount = 0
    var getHistoryCallCount = 0
    var getDailyHistoryCallCount = 0
    var clearOldEntriesCallCount = 0

    var getDailyHistoryResult: [UsageHistoryEntry] = []
    var getHistoryResult: [UsageHistoryEntry] = []
    var lastSavedEntry: UsageHistoryEntry?
    var lastRequestedDays: Int?
    var lastClearDays: Int?

    func configure(getDailyHistoryResult: [UsageHistoryEntry]? = nil) {
        if let getDailyHistoryResult { self.getDailyHistoryResult = getDailyHistoryResult }
    }

    func save(_ entry: UsageHistoryEntry) async {
        saveCallCount += 1
        lastSavedEntry = entry
    }

    func getHistory(days: Int) async -> [UsageHistoryEntry] {
        getHistoryCallCount += 1
        lastRequestedDays = days
        return getHistoryResult
    }

    func getDailyHistory(days: Int) async -> [UsageHistoryEntry] {
        getDailyHistoryCallCount += 1
        lastRequestedDays = days
        return getDailyHistoryResult
    }

    func clearOldEntries(olderThan days: Int) async {
        clearOldEntriesCallCount += 1
        lastClearDays = days
    }
}
