import Foundation
import SwiftUI
import AIMeterDomain

/// Display data for extra usage (pay-as-you-go) in UI
public struct ExtraUsageDisplayData: Sendable, Identifiable {
    public let id: UUID
    public let isEnabled: Bool
    public let usedCredits: String
    public let monthlyLimit: String
    public let remainingCredits: String
    public let percentage: Int
    public let status: UsageStatus

    public init(
        id: UUID = UUID(),
        isEnabled: Bool,
        usedCredits: String,
        monthlyLimit: String,
        remainingCredits: String,
        percentage: Int,
        status: UsageStatus
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.usedCredits = usedCredits
        self.monthlyLimit = monthlyLimit
        self.remainingCredits = remainingCredits
        self.percentage = percentage
        self.status = status
    }

    /// Creates display data from domain entity
    public init(from entity: ExtraUsageEntity) {
        self.id = UUID()
        self.isEnabled = entity.isEnabled
        self.usedCredits = entity.formattedUsedCredits
        self.monthlyLimit = entity.formattedMonthlyLimit
        self.remainingCredits = entity.formattedRemainingCredits
        self.percentage = Int(entity.utilization.value)
        self.status = entity.status
    }

    // MARK: - UI Properties

    /// Color based on status
    public var color: Color {
        status.color
    }

    /// Percentage text (e.g., "12%")
    public var percentageText: String {
        "\(percentage)%"
    }

    /// Usage summary text (e.g., "$12.50 / $100.00")
    public var usageSummary: String {
        "\(usedCredits) / \(monthlyLimit)"
    }

    /// SF Symbol icon name
    public var icon: String {
        status.icon
    }
}
