import Foundation

/// Domain entity representing Claude usage data
struct UsageEntity: Sendable, Equatable, Identifiable {
    let id: UUID
    let type: UsageType
    let percentage: Percentage
    let resetTime: ResetTime
    let lastUpdated: Date

    /// Creates a new usage entity
    nonisolated init(
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
    var status: UsageStatus {
        percentage.toStatus()
    }

    /// Whether usage is critical (>80%)
    var isCritical: Bool {
        status == .critical
    }

    /// Whether reset time has passed
    var isExpired: Bool {
        resetTime.isExpired
    }

    /// Creates updated entity with new percentage
    nonisolated func withPercentage(_ newPercentage: Percentage) -> UsageEntity {
        UsageEntity(
            id: id,
            type: type,
            percentage: newPercentage,
            resetTime: resetTime,
            lastUpdated: Date()
        )
    }

    /// Creates updated entity with new reset time
    nonisolated func withResetTime(_ newResetTime: ResetTime) -> UsageEntity {
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
    nonisolated static func defaultSession() -> UsageEntity {
        UsageEntity(
            type: .session,
            percentage: .zero,
            resetTime: .defaultSession
        )
    }

    /// Creates default weekly usage entity
    nonisolated static func defaultWeekly() -> UsageEntity {
        UsageEntity(
            type: .weekly,
            percentage: .zero,
            resetTime: .defaultWeekly
        )
    }

    /// Creates default Opus usage entity
    nonisolated static func defaultOpus() -> UsageEntity {
        UsageEntity(
            type: .opus,
            percentage: .zero,
            resetTime: .defaultWeekly
        )
    }

    /// Creates default Sonnet usage entity
    nonisolated static func defaultSonnet() -> UsageEntity {
        UsageEntity(
            type: .sonnet,
            percentage: .zero,
            resetTime: .defaultWeekly
        )
    }

    /// Creates all default usage entities
    nonisolated static func allDefaults() -> [UsageEntity] {
        [
            defaultSession(),
            defaultWeekly(),
            defaultOpus(),
            defaultSonnet()
        ]
    }
}
