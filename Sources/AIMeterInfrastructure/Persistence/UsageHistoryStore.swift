import AIMeterDomain
import Foundation

/// UserDefaults-based implementation of UsageHistoryRepository
public actor UsageHistoryStore: UsageHistoryRepository {
    private let historyKey = "usageHistory"
    private let lastSaveKey = "usageHistoryLastSave"
    private let defaults = UserDefaults.standard
    private let maxEntries = 700  // ~7 days at 15-minute intervals (96/day)
    private let saveIntervalMinutes = 15  // Save every 15 minutes

    public init() {}

    public func save(_ entry: UsageHistoryEntry) async {
        // Only save once per interval to avoid noise
        if let lastSave = defaults.object(forKey: lastSaveKey) as? Date {
            let minutesSinceLastSave = Date().timeIntervalSince(lastSave) / 60
            if minutesSinceLastSave < Double(saveIntervalMinutes) {
                return
            }
        }

        var history = loadHistory()
        history.append(entry)

        // Keep only recent entries
        if history.count > maxEntries {
            history = Array(history.suffix(maxEntries))
        }

        saveHistory(history)
        defaults.set(Date(), forKey: lastSaveKey)
    }

    public func getHistory(days: Int) async -> [UsageHistoryEntry] {
        let history = loadHistory()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        return history.filter { $0.timestamp >= cutoffDate }
            .sorted { $0.timestamp < $1.timestamp }
    }

    /// Returns daily aggregated history (one entry per day with max values)
    public func getDailyHistory(days: Int) async -> [UsageHistoryEntry] {
        let rawHistory = await getHistory(days: days)
        let calendar = Calendar.current

        // Group by day
        var dailyData: [Date: (session: Double, weekly: Double)] = [:]

        for entry in rawHistory {
            let dayStart = calendar.startOfDay(for: entry.timestamp)
            if let existing = dailyData[dayStart] {
                // Take max values for each day
                dailyData[dayStart] = (
                    session: max(existing.session, entry.sessionPercentage),
                    weekly: max(existing.weekly, entry.weeklyPercentage)
                )
            } else {
                dailyData[dayStart] = (entry.sessionPercentage, entry.weeklyPercentage)
            }
        }

        // Convert back to entries, sorted by date
        return dailyData.map { date, values in
            UsageHistoryEntry(
                timestamp: date,
                sessionPercentage: values.session,
                weeklyPercentage: values.weekly
            )
        }.sorted { $0.timestamp < $1.timestamp }
    }

    /// Returns history aggregated by time granularity (max values per interval)
    public func getAggregatedHistory(days: Int, granularity: TimeGranularity) async
        -> [UsageHistoryEntry]
    {
        let rawHistory = await getHistory(days: days)

        // For 15-minute granularity, return raw data
        if granularity == .fifteenMinutes {
            return rawHistory
        }

        let intervalSeconds = TimeInterval(granularity.rawValue * 60)

        // Group by floored interval
        var buckets: [Date: (session: Double, weekly: Double)] = [:]

        for entry in rawHistory {
            let floored = Date(
                timeIntervalSince1970:
                    floor(entry.timestamp.timeIntervalSince1970 / intervalSeconds) * intervalSeconds
            )

            if let existing = buckets[floored] {
                buckets[floored] = (
                    session: max(existing.session, entry.sessionPercentage),
                    weekly: max(existing.weekly, entry.weeklyPercentage)
                )
            } else {
                buckets[floored] = (entry.sessionPercentage, entry.weeklyPercentage)
            }
        }

        return buckets.map { date, values in
            UsageHistoryEntry(
                timestamp: date,
                sessionPercentage: values.session,
                weeklyPercentage: values.weekly
            )
        }.sorted { $0.timestamp < $1.timestamp }
    }

    public func clearOldEntries(olderThan days: Int) async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        var history = loadHistory()
        history = history.filter { $0.timestamp >= cutoffDate }
        saveHistory(history)
    }

    // MARK: - Private

    private func loadHistory() -> [UsageHistoryEntry] {
        guard let data = defaults.data(forKey: historyKey) else { return [] }
        return (try? JSONDecoder().decode([UsageHistoryEntry].self, from: data)) ?? []
    }

    private func saveHistory(_ history: [UsageHistoryEntry]) {
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: historyKey)
        }
    }
}
