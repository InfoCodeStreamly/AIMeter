import Foundation

/// Aggregated monthly usage with per-API-key and per-model breakdowns
public struct MonthlyUsageEntity: Sendable, Equatable {
    public let totalInputTokens: Int
    public let totalOutputTokens: Int
    public let totalCostCents: Int
    public let currency: String
    public let periodStart: Date
    public let periodEnd: Date
    public let byApiKey: [ApiKeyUsage]
    public let byModel: [ModelUsage]
    public let dailyCosts: [DailyCost]

    public nonisolated init(
        totalInputTokens: Int,
        totalOutputTokens: Int,
        totalCostCents: Int,
        currency: String = "USD",
        periodStart: Date,
        periodEnd: Date,
        byApiKey: [ApiKeyUsage] = [],
        byModel: [ModelUsage] = [],
        dailyCosts: [DailyCost] = []
    ) {
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
        self.totalCostCents = totalCostCents
        self.currency = currency
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.byApiKey = byApiKey
        self.byModel = byModel
        self.dailyCosts = dailyCosts
    }

    public var totalTokens: Int {
        totalInputTokens + totalOutputTokens
    }
}

// MARK: - Nested Types

extension MonthlyUsageEntity {
    /// Per-API-key usage with estimated cost (proportional from token share)
    public struct ApiKeyUsage: Sendable, Equatable, Identifiable {
        public let id: UUID
        public let apiKeyId: String
        public let apiKeyName: String?
        public let inputTokens: Int
        public let outputTokens: Int
        public let estimatedCostCents: Int

        public nonisolated init(
            id: UUID = UUID(),
            apiKeyId: String,
            apiKeyName: String? = nil,
            inputTokens: Int,
            outputTokens: Int,
            estimatedCostCents: Int
        ) {
            self.id = id
            self.apiKeyId = apiKeyId
            self.apiKeyName = apiKeyName
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
            self.estimatedCostCents = estimatedCostCents
        }

        public var totalTokens: Int {
            inputTokens + outputTokens
        }
    }

    /// Per-model usage with actual cost from cost_report
    public struct ModelUsage: Sendable, Equatable, Identifiable {
        public let id: UUID
        public let model: String
        public let inputTokens: Int
        public let outputTokens: Int
        public let costCents: Int

        public nonisolated init(
            id: UUID = UUID(),
            model: String,
            inputTokens: Int,
            outputTokens: Int,
            costCents: Int
        ) {
            self.id = id
            self.model = model
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
            self.costCents = costCents
        }

        public var totalTokens: Int {
            inputTokens + outputTokens
        }
    }

    /// Daily cost data point for chart
    public struct DailyCost: Sendable, Equatable, Identifiable {
        public let id: UUID
        public let date: Date
        public let costCents: Int

        public nonisolated init(
            id: UUID = UUID(),
            date: Date,
            costCents: Int
        ) {
            self.id = id
            self.date = date
            self.costCents = costCents
        }
    }
}
