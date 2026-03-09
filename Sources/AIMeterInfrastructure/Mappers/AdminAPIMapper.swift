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

    /// Maps usage API response to domain entities
    nonisolated static func toUsageBuckets(_ response: OrgUsageAPIResponse) -> [OrgUsageBucketEntity] {
        response.data.compactMap { bucket in
            guard let startTime = parseDate(bucket.snapshotStartTime),
                  let endTime = parseDate(bucket.snapshotEndTime) else {
                return nil
            }
            return OrgUsageBucketEntity(
                startTime: startTime,
                endTime: endTime,
                model: bucket.model,
                workspaceId: bucket.workspaceId,
                inputTokens: bucket.inputTokens ?? 0,
                outputTokens: bucket.outputTokens ?? 0,
                cacheReadTokens: bucket.cacheReadInputTokens ?? 0,
                cacheCreationTokens: bucket.cacheCreationInputTokens ?? 0
            )
        }
    }

    // MARK: - Cost Buckets

    /// Maps cost API response to domain entities
    /// Note: API returns amount as decimal string in cents
    nonisolated static func toCostBuckets(_ response: OrgCostAPIResponse) -> [OrgCostBucketEntity] {
        response.data.compactMap { bucket in
            guard let startTime = parseDate(bucket.snapshotStartTime),
                  let endTime = parseDate(bucket.snapshotEndTime) else {
                return nil
            }
            // Amount comes as decimal string in cents (e.g., "1250.00" or "1250")
            let amountCents = Int(Double(bucket.amount) ?? 0)

            return OrgCostBucketEntity(
                startTime: startTime,
                endTime: endTime,
                workspaceId: bucket.workspaceId,
                costDescription: bucket.description,
                amountCents: amountCents,
                currency: "USD"
            )
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
