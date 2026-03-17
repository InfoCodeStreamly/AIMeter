import Foundation
import AIMeterDomain

/// Display data for monthly usage card
public struct MonthlyUsageDisplayData: Sendable, Equatable {
    public let totalCostFormatted: String
    public let totalInputTokens: String
    public let totalOutputTokens: String
    public let periodLabel: String
    public let topSpender: String?
    public let topModel: String?
    public let byApiKey: [ApiKeyUsageDisplay]
    public let byModel: [ModelUsageDisplay]
    public let dailyCosts: [DailyCostDisplay]

    public init(from entity: MonthlyUsageEntity) {
        self.totalCostFormatted = String(format: "$%.2f", Double(entity.totalCostCents) / 100.0)
        self.totalInputTokens = Self.formatTokenCount(entity.totalInputTokens)
        self.totalOutputTokens = Self.formatTokenCount(entity.totalOutputTokens)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        self.periodLabel = formatter.string(from: entity.periodStart)

        // Top spender
        if let top = entity.byApiKey.first, entity.byApiKey.count > 1 {
            let pct = entity.totalCostCents > 0
                ? top.estimatedCostCents * 100 / entity.totalCostCents
                : 0
            let name = top.apiKeyName ?? Self.maskedKeyId(top.apiKeyId)
            let cost = String(format: "$%.2f", Double(top.estimatedCostCents) / 100.0)
            self.topSpender = "\(name) — \(cost) (\(pct)%)"
        } else {
            self.topSpender = nil
        }

        // Top model
        if let top = entity.byModel.first, top.costCents > 0 {
            let pct = entity.totalCostCents > 0
                ? top.costCents * 100 / entity.totalCostCents
                : 0
            let name = Self.humanReadableModel(top.model)
            let cost = String(format: "$%.2f", Double(top.costCents) / 100.0)
            self.topModel = "\(name) — \(cost) (\(pct)%)"
        } else {
            self.topModel = nil
        }

        self.byApiKey = entity.byApiKey.map { ApiKeyUsageDisplay(from: $0, totalCost: entity.totalCostCents) }
        self.byModel = entity.byModel.map { ModelUsageDisplay(from: $0, totalCost: entity.totalCostCents) }
        self.dailyCosts = entity.dailyCosts.map { DailyCostDisplay(from: $0) }
    }

    // MARK: - Formatting

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

    private static func maskedKeyId(_ keyId: String) -> String {
        let suffix = String(keyId.suffix(8))
        return "...\(suffix)"
    }

    static func humanReadableModel(_ model: String) -> String {
        if model.contains("opus") { return "Opus" }
        if model.contains("sonnet") { return "Sonnet" }
        if model.contains("haiku") { return "Haiku" }
        if model == "other" { return "Other" }
        return model
    }
}

// MARK: - Nested Display Types

extension MonthlyUsageDisplayData {
    public struct ApiKeyUsageDisplay: Sendable, Equatable, Identifiable {
        public let id: UUID
        public let apiKeyId: String
        public let displayName: String
        public let costFormatted: String
        public let percentage: Int
        public let tokensFormatted: String

        init(from entity: MonthlyUsageEntity.ApiKeyUsage, totalCost: Int) {
            self.id = entity.id
            self.apiKeyId = entity.apiKeyId
            self.displayName = entity.apiKeyName ?? MonthlyUsageDisplayData.maskedKeyId(entity.apiKeyId)
            self.costFormatted = String(format: "$%.2f", Double(entity.estimatedCostCents) / 100.0)
            self.percentage = totalCost > 0 ? entity.estimatedCostCents * 100 / totalCost : 0
            self.tokensFormatted = MonthlyUsageDisplayData.formatTokenCount(entity.totalTokens)
        }
    }

    public struct ModelUsageDisplay: Sendable, Equatable, Identifiable {
        public let id: UUID
        public let model: String
        public let displayName: String
        public let costFormatted: String
        public let percentage: Int

        init(from entity: MonthlyUsageEntity.ModelUsage, totalCost: Int) {
            self.id = entity.id
            self.model = entity.model
            self.displayName = MonthlyUsageDisplayData.humanReadableModel(entity.model)
            self.costFormatted = String(format: "$%.2f", Double(entity.costCents) / 100.0)
            self.percentage = totalCost > 0 ? entity.costCents * 100 / totalCost : 0
        }
    }

    public struct DailyCostDisplay: Sendable, Equatable, Identifiable {
        public let id: UUID
        public let date: Date
        public let dateLabel: String
        public let costCents: Int
        public let costFormatted: String

        init(from entity: MonthlyUsageEntity.DailyCost) {
            self.id = entity.id
            self.date = entity.date
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            self.dateLabel = formatter.string(from: entity.date)
            self.costCents = entity.costCents
            self.costFormatted = String(format: "$%.2f", Double(entity.costCents) / 100.0)
        }
    }
}
