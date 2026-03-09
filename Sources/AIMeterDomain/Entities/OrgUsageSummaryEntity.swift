import Foundation

/// Aggregated organization usage summary for a time period
public struct OrgUsageSummaryEntity: Sendable, Equatable {
    public let totalInputTokens: Int
    public let totalOutputTokens: Int
    public let totalCostCents: Int
    public let currency: String
    public let byModel: [ModelTokens]
    public let periodStart: Date
    public let periodEnd: Date

    public nonisolated init(
        totalInputTokens: Int,
        totalOutputTokens: Int,
        totalCostCents: Int,
        currency: String = "USD",
        byModel: [ModelTokens],
        periodStart: Date,
        periodEnd: Date
    ) {
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
        self.totalCostCents = totalCostCents
        self.currency = currency
        self.byModel = byModel
        self.periodStart = periodStart
        self.periodEnd = periodEnd
    }

    /// Total tokens (input + output)
    public var totalTokens: Int {
        totalInputTokens + totalOutputTokens
    }
}

// MARK: - Nested Types

extension OrgUsageSummaryEntity {
    /// Per-model token breakdown
    public struct ModelTokens: Sendable, Equatable, Identifiable {
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
            costCents: Int = 0
        ) {
            self.id = id
            self.model = model
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
            self.costCents = costCents
        }

        /// Total tokens for this model
        public var totalTokens: Int {
            inputTokens + outputTokens
        }
    }
}
