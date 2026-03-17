import Foundation
import AIMeterDomain

/// Fetches monthly usage from 1st of current month, aggregated by API key and model
public final class FetchMonthlyUsageUseCase: Sendable {
    private let adminKeyRepository: any AdminKeyRepository
    private let orgUsageRepository: any OrgUsageRepository

    public init(
        adminKeyRepository: any AdminKeyRepository,
        orgUsageRepository: any OrgUsageRepository
    ) {
        self.adminKeyRepository = adminKeyRepository
        self.orgUsageRepository = orgUsageRepository
    }

    /// Fetches monthly usage with per-key and per-model breakdowns
    public func execute() async throws -> MonthlyUsageEntity {
        guard await adminKeyRepository.exists() else {
            throw DomainError.adminKeyNotFound
        }

        let now = Date()
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        // Parallel fetch: usage by api_key+model, cost by description
        async let usageBuckets = orgUsageRepository.fetchUsageReport(
            from: monthStart,
            to: now,
            bucketWidth: .day,
            groupBy: ["api_key_id", "model"]
        )
        async let costBuckets = orgUsageRepository.fetchCostReport(
            from: monthStart,
            to: now,
            groupBy: ["description"]
        )

        let usage = try await usageBuckets
        let costs = try await costBuckets

        return aggregate(usage: usage, costs: costs, from: monthStart, to: now)
    }

    // MARK: - Private

    private func aggregate(
        usage: [OrgUsageBucketEntity],
        costs: [OrgCostBucketEntity],
        from: Date,
        to: Date
    ) -> MonthlyUsageEntity {
        // 1. Total cost from cost_report
        let totalCostCents = costs.reduce(0) { $0 + $1.amountCents }

        // 2. Per-model cost (actual from cost_report grouped by description)
        var modelCostMap: [String: (input: Int, output: Int, cost: Int)] = [:]
        for cost in costs where cost.costType == "tokens" {
            let model = cost.model ?? "unknown"
            var existing = modelCostMap[model, default: (input: 0, output: 0, cost: 0)]
            existing.cost += cost.amountCents
            modelCostMap[model] = existing
        }
        // Add non-token costs (web_search etc.) to "unknown" model
        for cost in costs where cost.costType != "tokens" {
            var existing = modelCostMap["other", default: (input: 0, output: 0, cost: 0)]
            existing.cost += cost.amountCents
            modelCostMap["other"] = existing
        }

        // 3. Per-model tokens from usage_report
        var modelTokenMap: [String: (input: Int, output: Int)] = [:]
        for bucket in usage {
            let model = bucket.model ?? "unknown"
            let existing = modelTokenMap[model, default: (input: 0, output: 0)]
            modelTokenMap[model] = (
                input: existing.input + bucket.inputTokens,
                output: existing.output + bucket.outputTokens
            )
        }
        // Merge token data into model cost map
        for (model, tokens) in modelTokenMap {
            var existing = modelCostMap[model, default: (input: 0, output: 0, cost: 0)]
            existing.input += tokens.input
            existing.output += tokens.output
            modelCostMap[model] = existing
        }

        let byModel = modelCostMap.map { model, data in
            MonthlyUsageEntity.ModelUsage(
                model: model,
                inputTokens: data.input,
                outputTokens: data.output,
                costCents: data.cost
            )
        }.sorted { $0.costCents > $1.costCents }

        // 4. Per-API-key usage with proportional cost estimation
        var keyMap: [String: (input: Int, output: Int, models: [String: (input: Int, output: Int)])] = [:]
        for bucket in usage {
            guard let keyId = bucket.apiKeyId else { continue }
            let model = bucket.model ?? "unknown"
            var existing = keyMap[keyId, default: (input: 0, output: 0, models: [:])]
            existing.input += bucket.inputTokens
            existing.output += bucket.outputTokens
            let existingModel = existing.models[model, default: (input: 0, output: 0)]
            existing.models[model] = (
                input: existingModel.input + bucket.inputTokens,
                output: existingModel.output + bucket.outputTokens
            )
            keyMap[keyId] = existing
        }

        let totalTokensByModel = modelTokenMap.mapValues { $0.input + $0.output }

        let byApiKey = keyMap.map { keyId, data in
            // Estimate cost: for each model used by this key,
            // keyCost += (keyModelTokens / totalModelTokens) * modelCost
            var estimatedCost = 0
            for (model, keyTokens) in data.models {
                let totalForModel = totalTokensByModel[model] ?? 0
                let costForModel = modelCostMap[model]?.cost ?? 0
                if totalForModel > 0 {
                    estimatedCost += (keyTokens.input + keyTokens.output) * costForModel / totalForModel
                }
            }
            return MonthlyUsageEntity.ApiKeyUsage(
                apiKeyId: keyId,
                inputTokens: data.input,
                outputTokens: data.output,
                estimatedCostCents: estimatedCost
            )
        }.sorted { $0.estimatedCostCents > $1.estimatedCostCents }

        // 5. Daily costs from cost_report buckets
        let calendar = Calendar.current
        var dailyMap: [Date: Int] = [:]
        for cost in costs {
            let day = calendar.startOfDay(for: cost.startTime)
            dailyMap[day, default: 0] += cost.amountCents
        }
        let dailyCosts = dailyMap.map { date, cents in
            MonthlyUsageEntity.DailyCost(date: date, costCents: cents)
        }.sorted { $0.date < $1.date }

        return MonthlyUsageEntity(
            totalInputTokens: modelTokenMap.values.reduce(0) { $0 + $1.input },
            totalOutputTokens: modelTokenMap.values.reduce(0) { $0 + $1.output },
            totalCostCents: totalCostCents,
            currency: costs.first?.currency ?? "USD",
            periodStart: from,
            periodEnd: to,
            byApiKey: byApiKey,
            byModel: byModel,
            dailyCosts: dailyCosts
        )
    }
}
