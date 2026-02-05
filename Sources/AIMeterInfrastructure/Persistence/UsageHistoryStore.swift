import Foundation
import AIMeterDomain

/// UserDefaults-based implementation of UsageHistoryRepository
public actor UsageHistoryStore: UsageHistoryRepository {
    private let historyKey = "usageHistory"
    private let defaults = UserDefaults.standard
    private let maxEntries = 500 // Keep at most 500 entries

    public init() {}

    public func save(_ entry: UsageHistoryEntry) async {
        var history = loadHistory()
        history.append(entry)

        // Keep only recent entries
        if history.count > maxEntries {
            history = Array(history.suffix(maxEntries))
        }

        saveHistory(history)
    }

    public func getHistory(days: Int) async -> [UsageHistoryEntry] {
        let history = loadHistory()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        return history.filter { $0.timestamp >= cutoffDate }
            .sorted { $0.timestamp < $1.timestamp }
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
