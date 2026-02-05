import Foundation

/// Domain entity representing extra usage (pay-as-you-go) data
public struct ExtraUsageEntity: Sendable, Equatable {
    public let isEnabled: Bool
    public let monthlyLimit: Double
    public let usedCredits: Double
    public let utilization: Percentage

    public init(
        isEnabled: Bool,
        monthlyLimit: Double,
        usedCredits: Double,
        utilization: Percentage
    ) {
        self.isEnabled = isEnabled
        self.monthlyLimit = monthlyLimit
        self.usedCredits = usedCredits
        self.utilization = utilization
    }

    /// Usage status based on utilization
    public var status: UsageStatus {
        utilization.toStatus()
    }

    /// Formatted used credits string
    public var formattedUsedCredits: String {
        String(format: "$%.2f", usedCredits)
    }

    /// Formatted monthly limit string
    public var formattedMonthlyLimit: String {
        String(format: "$%.2f", monthlyLimit)
    }

    /// Remaining credits
    public var remainingCredits: Double {
        max(0, monthlyLimit - usedCredits)
    }

    /// Formatted remaining credits string
    public var formattedRemainingCredits: String {
        String(format: "$%.2f", remainingCredits)
    }
}

// MARK: - Factory Methods

extension ExtraUsageEntity {
    /// Creates a disabled extra usage entity
    public static func disabled() -> ExtraUsageEntity {
        ExtraUsageEntity(
            isEnabled: false,
            monthlyLimit: 0,
            usedCredits: 0,
            utilization: .zero
        )
    }
}
