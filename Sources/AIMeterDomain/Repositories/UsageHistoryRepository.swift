import Foundation

/// Repository protocol for usage history data operations
public protocol UsageHistoryRepository: Sendable {
    /// Saves a usage history entry
    func save(_ entry: UsageHistoryEntry) async

    /// Gets history entries for the last N days
    func getHistory(days: Int) async -> [UsageHistoryEntry]

    /// Gets daily aggregated history (one entry per day with max values)
    func getDailyHistory(days: Int) async -> [UsageHistoryEntry]

    /// Gets history aggregated by time granularity (max values per interval)
    func getAggregatedHistory(days: Int, granularity: TimeGranularity) async -> [UsageHistoryEntry]

    /// Clears old history entries (older than specified days)
    func clearOldEntries(olderThan days: Int) async
}
