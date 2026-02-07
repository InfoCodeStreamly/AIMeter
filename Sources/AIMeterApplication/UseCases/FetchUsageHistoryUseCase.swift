import AIMeterDomain
import Foundation

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

    /// Fetches raw hourly history for the specified number of days
    /// - Parameter days: Number of days to fetch
    /// - Returns: Array of hourly history entries sorted by timestamp
    public func executeHourly(days: Int = 7) async -> [UsageHistoryEntry] {
        await historyRepository.getHistory(days: days)
    }

    /// Fetches history aggregated by time granularity
    /// - Parameters:
    ///   - days: Number of days to fetch
    ///   - granularity: Time interval for aggregation (15min, 1h, 3h, 6h)
    /// - Returns: Array of aggregated history entries sorted by timestamp
    public func executeWithGranularity(days: Int = 7, granularity: TimeGranularity) async
        -> [UsageHistoryEntry]
    {
        await historyRepository.getAggregatedHistory(days: days, granularity: granularity)
    }
}
