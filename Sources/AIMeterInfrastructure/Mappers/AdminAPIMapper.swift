import Foundation
import AIMeterDomain
import AIMeterApplication

/// Maps Admin API responses to domain entities
enum AdminAPIMapper {

    // MARK: - ISO8601 Parser

    private nonisolated static func parseDate(_ string: String) -> Date? {
        // Try with fractional seconds first, then without
        if let date = try? Date(string, strategy: .iso8601.year().month().day()
            .time(includingFractionalSeconds: true).timeZone(separator: .omitted)) {
            return date
        }
        if let date = try? Date(string, strategy: .iso8601) {
            return date
        }
        return nil
    }

    // MARK: - Usage Buckets

    /// Maps usage API response (nested format) to domain entities
    nonisolated static func toUsageBuckets(_ response: OrgUsageAPIResponse) -> [OrgUsageBucketEntity] {
        response.data.flatMap { bucket in
            guard let startTime = parseDate(bucket.startingAt),
                  let endTime = parseDate(bucket.endingAt) else {
                return [OrgUsageBucketEntity]()
            }

            return bucket.results.map { result in
                let cacheCreationTokens = (result.cacheCreation?.ephemeral1hInputTokens ?? 0)
                    + (result.cacheCreation?.ephemeral5mInputTokens ?? 0)

                return OrgUsageBucketEntity(
                    startTime: startTime,
                    endTime: endTime,
                    model: result.model,
                    apiKeyId: result.apiKeyId,
                    workspaceId: result.workspaceId,
                    inputTokens: result.uncachedInputTokens ?? 0,
                    outputTokens: result.outputTokens ?? 0,
                    cacheReadTokens: result.cacheReadInputTokens ?? 0,
                    cacheCreationTokens: cacheCreationTokens
                )
            }
        }
    }

    // MARK: - Cost Buckets

    /// Maps cost API response (nested format) to domain entities
    /// Note: API returns amount as decimal string in cents
    nonisolated static func toCostBuckets(_ response: OrgCostAPIResponse) -> [OrgCostBucketEntity] {
        response.data.flatMap { bucket in
            guard let startTime = parseDate(bucket.startingAt),
                  let endTime = parseDate(bucket.endingAt) else {
                return [OrgCostBucketEntity]()
            }

            return bucket.results.map { result in
                let amountCents = Int(Double(result.amount) ?? 0)

                return OrgCostBucketEntity(
                    startTime: startTime,
                    endTime: endTime,
                    workspaceId: result.workspaceId,
                    costDescription: result.description,
                    model: result.model,
                    costType: result.costType,
                    amountCents: amountCents,
                    currency: result.currency ?? "USD"
                )
            }
        }
    }

    // MARK: - User Activities

    /// Maps Claude Code analytics response to domain entities
    nonisolated static func toUserActivities(
        _ response: ClaudeCodeAnalyticsAPIResponse
    ) -> [ClaudeCodeUserActivityEntity] {
        response.data.compactMap { user in
            let email: String
            if user.actor.type == "user_actor" {
                email = user.actor.emailAddress ?? "unknown"
            } else {
                email = user.actor.apiKeyName ?? "api-key"
            }

            let editAccepted = (user.toolActions?.editTool?.accepted ?? 0)
                + (user.toolActions?.multiEditTool?.accepted ?? 0)
            let editRejected = (user.toolActions?.editTool?.rejected ?? 0)
                + (user.toolActions?.multiEditTool?.rejected ?? 0)

            let models = (user.modelBreakdown ?? []).map { breakdown in
                ClaudeCodeUserActivityEntity.ModelUsage(
                    model: breakdown.model,
                    inputTokens: breakdown.tokens?.input ?? 0,
                    outputTokens: breakdown.tokens?.output ?? 0,
                    estimatedCostCents: breakdown.estimatedCost?.amount ?? 0
                )
            }

            return ClaudeCodeUserActivityEntity(
                date: parseDate(user.date) ?? Date(),
                email: email,
                customerType: user.customerType ?? "api",
                terminalType: user.terminalType ?? "",
                sessions: user.coreMetrics.numSessions ?? 0,
                linesAdded: user.coreMetrics.linesOfCode?.added ?? 0,
                linesRemoved: user.coreMetrics.linesOfCode?.removed ?? 0,
                commits: user.coreMetrics.commitsByClaudeCode ?? 0,
                pullRequests: user.coreMetrics.pullRequestsByClaudeCode ?? 0,
                editAccepted: editAccepted,
                editRejected: editRejected,
                writeAccepted: user.toolActions?.writeTool?.accepted ?? 0,
                writeRejected: user.toolActions?.writeTool?.rejected ?? 0,
                models: models
            )
        }
    }

    // MARK: - Summary Aggregation

    /// Aggregates usage buckets + cost buckets into a summary entity
    nonisolated static func toUsageSummary(
        buckets: [OrgUsageBucketEntity],
        costs: [OrgCostBucketEntity],
        from: Date,
        to: Date
    ) -> OrgUsageSummaryEntity {
        var modelMap: [String: (input: Int, output: Int)] = [:]
        for bucket in buckets {
            let model = bucket.model ?? "unknown"
            let existing = modelMap[model, default: (input: 0, output: 0)]
            modelMap[model] = (
                input: existing.input + bucket.inputTokens,
                output: existing.output + bucket.outputTokens
            )
        }

        let totalCostCents = costs.reduce(0) { $0 + $1.amountCents }

        let byModel = modelMap.map { model, tokens in
            OrgUsageSummaryEntity.ModelTokens(
                model: model,
                inputTokens: tokens.input,
                outputTokens: tokens.output
            )
        }.sorted { $0.totalTokens > $1.totalTokens }

        return OrgUsageSummaryEntity(
            totalInputTokens: modelMap.values.reduce(0) { $0 + $1.input },
            totalOutputTokens: modelMap.values.reduce(0) { $0 + $1.output },
            totalCostCents: totalCostCents,
            currency: costs.first?.currency ?? "USD",
            byModel: byModel,
            periodStart: from,
            periodEnd: to
        )
    }
}
