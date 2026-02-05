import Foundation

/// Domain entity representing a single usage history data point
public struct UsageHistoryEntry: Sendable, Equatable, Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let sessionPercentage: Double
    public let weeklyPercentage: Double

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        sessionPercentage: Double,
        weeklyPercentage: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.sessionPercentage = sessionPercentage
        self.weeklyPercentage = weeklyPercentage
    }

    /// Creates entry from current usage entities
    public static func from(usages: [UsageEntity]) -> UsageHistoryEntry? {
        guard let session = usages.first(where: { $0.type == .session }),
              let weekly = usages.first(where: { $0.type == .weekly }) else {
            return nil
        }

        return UsageHistoryEntry(
            sessionPercentage: session.percentage.value,
            weeklyPercentage: weekly.percentage.value
        )
    }
}
