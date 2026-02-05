import Foundation
import AIMeterDomain

/// Use case for fetching usage history
public final class FetchUsageHistoryUseCase: Sendable {
    private let historyRepository: any UsageHistoryRepository

    public init(historyRepository: any UsageHistoryRepository) {
        self.historyRepository = historyRepository
    }

    /// Fetches history for the specified number of days
    /// - Parameter days: Number of days to fetch (default: 7)
    /// - Returns: Array of history entries sorted by timestamp
    public func execute(days: Int = 7) async -> [UsageHistoryEntry] {
        await historyRepository.getHistory(days: days)
    }
}
