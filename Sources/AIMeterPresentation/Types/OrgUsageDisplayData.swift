import Foundation
import SwiftUI
import AIMeterDomain

/// Display data for organization usage summary
public struct OrgUsageSummaryDisplayData: Sendable, Equatable {
    public let totalInputTokens: String
    public let totalOutputTokens: String
    public let totalCostFormatted: String
    public let byModel: [OrgModelUsageDisplay]
    public let periodLabel: String

    /// Creates display data from domain entity
    public init(from entity: OrgUsageSummaryEntity) {
        self.totalInputTokens = Self.formatTokenCount(entity.totalInputTokens)
        self.totalOutputTokens = Self.formatTokenCount(entity.totalOutputTokens)
        self.totalCostFormatted = String(format: "$%.2f", Double(entity.totalCostCents) / 100.0)
        self.byModel = entity.byModel.map { OrgModelUsageDisplay(from: $0) }
        self.periodLabel = "Today"
    }

    // MARK: - Token Formatting

    private static func formatTokenCount(_ count: Int) -> String {
        switch count {
        case 1_000_000...:
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        case 1_000...:
            return String(format: "%.0fK", Double(count) / 1_000.0)
        default:
            return "\(count)"
        }
    }
}

/// Display data for per-model usage
public struct OrgModelUsageDisplay: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let model: String
    public let displayName: String
    public let inputTokens: String
    public let outputTokens: String
    public let costFormatted: String

    public init(from modelTokens: OrgUsageSummaryEntity.ModelTokens) {
        self.id = modelTokens.id
        self.model = modelTokens.model
        self.displayName = Self.humanReadableModel(modelTokens.model)
        self.inputTokens = Self.formatTokenCount(modelTokens.inputTokens)
        self.outputTokens = Self.formatTokenCount(modelTokens.outputTokens)
        self.costFormatted = modelTokens.costCents > 0
            ? String(format: "$%.2f", Double(modelTokens.costCents) / 100.0)
            : ""
    }

    // MARK: - Formatting

    private static func humanReadableModel(_ model: String) -> String {
        if model.contains("opus") { return "Opus" }
        if model.contains("sonnet") { return "Sonnet" }
        if model.contains("haiku") { return "Haiku" }
        return model
    }

    private static func formatTokenCount(_ count: Int) -> String {
        switch count {
        case 1_000_000...:
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        case 1_000...:
            return String(format: "%.0fK", Double(count) / 1_000.0)
        default:
            return "\(count)"
        }
    }
}
