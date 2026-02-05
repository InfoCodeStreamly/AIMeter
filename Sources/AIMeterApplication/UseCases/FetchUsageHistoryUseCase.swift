import Foundation
import AIMeterDomain

/// Use case for fetching usage history
public final class FetchUsageHistoryUseCase: Sendable {
    private let historyRepository: any UsageHistoryRepository

    public init(historyRepository: any UsageHistoryRepository) {
        self.historyRepository = historyRepository
    }

    /// Fetches daily aggregated history for the specified number of days
    /// Returns one entry per day with max usage values
    /// - Parameter days: Number of days to fetch (default: 7)
    /// - Returns: Array of daily history entries sorted by timestamp
    public func execute(days: Int = 7) async -> [UsageHistoryEntry] {
        await historyRepository.getDailyHistory(days: days)
    }
}
