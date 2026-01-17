import Foundation

/// Domain entity representing Claude usage data
public struct UsageEntity: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let type: UsageType
    public let percentage: Percentage
    public let resetTime: ResetTime
    public let lastUpdated: Date

    /// Creates a new usage entity
    public nonisolated init(
        id: UUID = UUID(),
        type: UsageType,
        percentage: Percentage,
        resetTime: ResetTime,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.percentage = percentage
        self.resetTime = resetTime
        self.lastUpdated = lastUpdated
    }

    /// Usage status based on percentage
    public var status: UsageStatus {
        percentage.toStatus()
    }

    /// Whether usage is critical (>80%)
    public var isCritical: Bool {
        status == .critical
    }

    /// Whether reset time has passed
    public var isExpired: Bool {
        resetTime.isExpired
    }

    /// Creates updated entity with new percentage
    public nonisolated func withPercentage(_ newPercentage: Percentage) -> UsageEntity {
        UsageEntity(
            id: id,
            type: type,
            percentage: newPercentage,
            resetTime: resetTime,
            lastUpdated: Date()
        )
    }

    /// Creates updated entity with new reset time
    public nonisolated func withResetTime(_ newResetTime: ResetTime) -> UsageEntity {
        UsageEntity(
            id: id,
            type: type,
            percentage: percentage,
            resetTime: newResetTime,
            lastUpdated: Date()
        )
    }
}

// MARK: - Factory Methods

extension UsageEntity {
    /// Creates default session usage entity
    public nonisolated static func defaultSession() -> UsageEntity {
        UsageEntity(
            type: .session,
            percentage: .zero,
            resetTime: .defaultSession
        )
    }

    /// Creates default weekly usage entity
    public nonisolated static func defaultWeekly() -> UsageEntity {
        UsageEntity(
            type: .weekly,
            percentage: .zero,
            resetTime: .defaultWeekly
        )
    }

    /// Creates default Opus usage entity
    public nonisolated static func defaultOpus() -> UsageEntity {
        UsageEntity(
            type: .opus,
            percentage: .zero,
            resetTime: .defaultWeekly
        )
    }

    /// Creates default Sonnet usage entity
    public nonisolated static func defaultSonnet() -> UsageEntity {
        UsageEntity(
            type: .sonnet,
            percentage: .zero,
            resetTime: .defaultWeekly
        )
    }

    /// Creates all default usage entities
    public nonisolated static func allDefaults() -> [UsageEntity] {
        [
            defaultSession(),
            defaultWeekly(),
            defaultOpus(),
            defaultSonnet()
        ]
    }
}
