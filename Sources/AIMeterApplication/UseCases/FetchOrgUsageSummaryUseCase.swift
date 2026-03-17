import Foundation
import AIMeterDomain

/// Fetches today's organization usage + cost and aggregates into a summary
public final class FetchOrgUsageSummaryUseCase: Sendable {
    private let adminKeyRepository: any AdminKeyRepository
    private let orgUsageRepository: any OrgUsageRepository

    public init(
        adminKeyRepository: any AdminKeyRepository,
        orgUsageRepository: any OrgUsageRepository
    ) {
        self.adminKeyRepository = adminKeyRepository
        self.orgUsageRepository = orgUsageRepository
    }

    /// Fetches today's usage grouped by model + cost, returns aggregated summary
    public func execute() async throws -> OrgUsageSummaryEntity {
        guard await adminKeyRepository.exists() else {
            throw DomainError.adminKeyNotFound
        }

        let now = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)

        async let usageBuckets = orgUsageRepository.fetchUsageReport(
            from: todayStart,
            to: now,
            bucketWidth: .hour,
            groupBy: ["model"]
        )
        async let costBuckets = orgUsageRepository.fetchCostReport(
            from: todayStart,
            to: now,
            groupBy: nil
        )

        let usage = try await usageBuckets
        let costs = try await costBuckets

        return aggregate(usage: usage, costs: costs, from: todayStart, to: now)
    }

    // MARK: - Private

    private func aggregate(
        usage: [OrgUsageBucketEntity],
        costs: [OrgCostBucketEntity],
        from: Date,
        to: Date
    ) -> OrgUsageSummaryEntity {
        // Aggregate tokens by model
        var modelMap: [String: (input: Int, output: Int)] = [:]
        for bucket in usage {
            let model = bucket.model ?? "unknown"
            let existing = modelMap[model, default: (input: 0, output: 0)]
            modelMap[model] = (
                input: existing.input + bucket.inputTokens,
                output: existing.output + bucket.outputTokens
            )
        }

        let totalCostCents = costs.reduce(0) { $0 + $1.amountCents }
        let currency = costs.first?.currency ?? "USD"

        let byModel = modelMap.map { model, tokens in
            OrgUsageSummaryEntity.ModelTokens(
                model: model,
                inputTokens: tokens.input,
                outputTokens: tokens.output
            )
        }.sorted { $0.inputTokens + $0.outputTokens > $1.inputTokens + $1.outputTokens }

        return OrgUsageSummaryEntity(
            totalInputTokens: modelMap.values.reduce(0) { $0 + $1.input },
            totalOutputTokens: modelMap.values.reduce(0) { $0 + $1.output },
            totalCostCents: totalCostCents,
            currency: currency,
            byModel: byModel,
            periodStart: from,
            periodEnd: to
        )
    }
}
