import Testing
@testable import AIMeterInfrastructure
import AIMeterDomain
import Foundation

/// Tests for AdminAPIMapper — all 4 mapping methods.
@Suite("AdminAPIMapper")
struct AdminAPIMapperTests {

    // MARK: - toUsageBuckets Tests

    @Test("toUsageBuckets maps response data to domain entities")
    func toUsageBucketsMapsResponseData() {
        let response = OrgUsageAPIResponse(
            data: [
                OrgUsageBucketData(
                    snapshotStartTime: "2026-01-01T00:00:00Z",
                    snapshotEndTime: "2026-01-01T01:00:00Z",
                    model: "claude-3-opus-20240229",
                    workspaceId: "ws-abc",
                    inputTokens: 1000,
                    outputTokens: 500,
                    cacheReadInputTokens: 200,
                    cacheCreationInputTokens: 100
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toUsageBuckets(response)

        #expect(entities.count == 1)
        #expect(entities[0].model == "claude-3-opus-20240229")
        #expect(entities[0].workspaceId == "ws-abc")
        #expect(entities[0].inputTokens == 1000)
        #expect(entities[0].outputTokens == 500)
        #expect(entities[0].cacheReadTokens == 200)
        #expect(entities[0].cacheCreationTokens == 100)
    }

    @Test("toUsageBuckets returns empty array for empty data")
    func toUsageBucketsReturnsEmptyForEmptyData() {
        let response = OrgUsageAPIResponse(data: [], hasMore: false, nextPage: nil)
        let entities = AdminAPIMapper.toUsageBuckets(response)
        #expect(entities.isEmpty)
    }

    @Test("toUsageBuckets skips buckets with invalid start time")
    func toUsageBucketsSkipsInvalidStartTime() {
        let response = OrgUsageAPIResponse(
            data: [
                OrgUsageBucketData(
                    snapshotStartTime: "invalid-date",
                    snapshotEndTime: "2026-01-01T01:00:00Z",
                    model: nil,
                    workspaceId: nil,
                    inputTokens: 100,
                    outputTokens: 50,
                    cacheReadInputTokens: nil,
                    cacheCreationInputTokens: nil
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toUsageBuckets(response)
        #expect(entities.isEmpty)
    }

    @Test("toUsageBuckets skips buckets with invalid end time")
    func toUsageBucketsSkipsInvalidEndTime() {
        let response = OrgUsageAPIResponse(
            data: [
                OrgUsageBucketData(
                    snapshotStartTime: "2026-01-01T00:00:00Z",
                    snapshotEndTime: "not-a-date",
                    model: nil,
                    workspaceId: nil,
                    inputTokens: 100,
                    outputTokens: 50,
                    cacheReadInputTokens: nil,
                    cacheCreationInputTokens: nil
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toUsageBuckets(response)
        #expect(entities.isEmpty)
    }

    @Test("toUsageBuckets uses zero for nil token counts")
    func toUsageBucketsUsesZeroForNilTokens() {
        let response = OrgUsageAPIResponse(
            data: [
                OrgUsageBucketData(
                    snapshotStartTime: "2026-01-01T00:00:00Z",
                    snapshotEndTime: "2026-01-01T01:00:00Z",
                    model: nil,
                    workspaceId: nil,
                    inputTokens: nil,
                    outputTokens: nil,
                    cacheReadInputTokens: nil,
                    cacheCreationInputTokens: nil
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toUsageBuckets(response)

        #expect(entities.count == 1)
        #expect(entities[0].inputTokens == 0)
        #expect(entities[0].outputTokens == 0)
        #expect(entities[0].cacheReadTokens == 0)
        #expect(entities[0].cacheCreationTokens == 0)
    }

    @Test("toUsageBuckets parses ISO8601 dates correctly")
    func toUsageBucketsParsesISO8601Dates() {
        let response = OrgUsageAPIResponse(
            data: [
                OrgUsageBucketData(
                    snapshotStartTime: "2026-01-01T00:00:00Z",
                    snapshotEndTime: "2026-01-01T01:00:00Z",
                    model: nil,
                    workspaceId: nil,
                    inputTokens: 100,
                    outputTokens: 50,
                    cacheReadInputTokens: nil,
                    cacheCreationInputTokens: nil
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toUsageBuckets(response)

        #expect(entities.count == 1)
        // Start time should be before end time
        #expect(entities[0].startTime < entities[0].endTime)
    }

    // MARK: - toCostBuckets Tests

    @Test("toCostBuckets maps response data to domain entities")
    func toCostBucketsMapsResponseData() {
        let response = OrgCostAPIResponse(
            data: [
                OrgCostBucketData(
                    snapshotStartTime: "2026-01-01T00:00:00Z",
                    snapshotEndTime: "2026-01-01T01:00:00Z",
                    workspaceId: "ws-abc",
                    description: "Claude API usage",
                    amount: "1250"
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toCostBuckets(response)

        #expect(entities.count == 1)
        #expect(entities[0].workspaceId == "ws-abc")
        #expect(entities[0].costDescription == "Claude API usage")
        #expect(entities[0].amountCents == 1250)
        #expect(entities[0].currency == "USD")
    }

    @Test("toCostBuckets parses decimal amount string correctly")
    func toCostBucketsParseDecimalAmount() {
        let response = OrgCostAPIResponse(
            data: [
                OrgCostBucketData(
                    snapshotStartTime: "2026-01-01T00:00:00Z",
                    snapshotEndTime: "2026-01-01T01:00:00Z",
                    workspaceId: nil,
                    description: nil,
                    amount: "1250.75"
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toCostBuckets(response)

        #expect(entities.count == 1)
        // Int(Double("1250.75") ?? 0) = 1250
        #expect(entities[0].amountCents == 1250)
    }

    @Test("toCostBuckets returns empty array for empty data")
    func toCostBucketsReturnsEmptyForEmptyData() {
        let response = OrgCostAPIResponse(data: [], hasMore: false, nextPage: nil)
        let entities = AdminAPIMapper.toCostBuckets(response)
        #expect(entities.isEmpty)
    }

    @Test("toCostBuckets skips buckets with invalid dates")
    func toCostBucketsSkipsInvalidDates() {
        let response = OrgCostAPIResponse(
            data: [
                OrgCostBucketData(
                    snapshotStartTime: "bad-date",
                    snapshotEndTime: "also-bad",
                    workspaceId: nil,
                    description: nil,
                    amount: "100"
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toCostBuckets(response)
        #expect(entities.isEmpty)
    }

    @Test("toCostBuckets uses zero for unparseable amount")
    func toCostBucketsUsesZeroForUnparseableAmount() {
        let response = OrgCostAPIResponse(
            data: [
                OrgCostBucketData(
                    snapshotStartTime: "2026-01-01T00:00:00Z",
                    snapshotEndTime: "2026-01-01T01:00:00Z",
                    workspaceId: nil,
                    description: nil,
                    amount: "not-a-number"
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toCostBuckets(response)
        #expect(entities.count == 1)
        #expect(entities[0].amountCents == 0)
    }

    // MARK: - toUserActivities Tests

    @Test("toUserActivities maps user_actor to email address")
    func toUserActivitiesMapsUserActorEmail() {
        let response = ClaudeCodeAnalyticsAPIResponse(
            data: [
                ClaudeCodeUserData(
                    date: "2026-01-01",
                    actor: ActorData(type: "user_actor", emailAddress: "user@example.com", apiKeyName: nil),
                    organizationId: nil,
                    customerType: nil,
                    terminalType: nil,
                    coreMetrics: CoreMetrics(
                        numSessions: 1,
                        linesOfCode: nil,
                        commitsByClaudeCode: nil,
                        pullRequestsByClaudeCode: nil
                    ),
                    toolActions: nil,
                    modelBreakdown: nil
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toUserActivities(response)

        #expect(entities.count == 1)
        #expect(entities[0].email == "user@example.com")
    }

    @Test("toUserActivities maps api_key actor to api key name")
    func toUserActivitiesMapsApiKeyActorName() {
        let response = ClaudeCodeAnalyticsAPIResponse(
            data: [
                ClaudeCodeUserData(
                    date: "2026-01-01",
                    actor: ActorData(type: "api_key_actor", emailAddress: nil, apiKeyName: "prod-key"),
                    organizationId: nil,
                    customerType: nil,
                    terminalType: nil,
                    coreMetrics: CoreMetrics(
                        numSessions: nil,
                        linesOfCode: nil,
                        commitsByClaudeCode: nil,
                        pullRequestsByClaudeCode: nil
                    ),
                    toolActions: nil,
                    modelBreakdown: nil
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toUserActivities(response)

        #expect(entities.count == 1)
        #expect(entities[0].email == "prod-key")
    }

    @Test("toUserActivities sums edit and multi_edit accepted counts")
    func toUserActivitiesSumsEditAccepted() {
        let response = ClaudeCodeAnalyticsAPIResponse(
            data: [
                ClaudeCodeUserData(
                    date: "2026-01-01",
                    actor: ActorData(type: "user_actor", emailAddress: "u@e.com", apiKeyName: nil),
                    organizationId: nil,
                    customerType: nil,
                    terminalType: nil,
                    coreMetrics: CoreMetrics(
                        numSessions: nil, linesOfCode: nil,
                        commitsByClaudeCode: nil, pullRequestsByClaudeCode: nil
                    ),
                    toolActions: ToolActions(
                        editTool: ToolMetric(accepted: 30, rejected: 3),
                        multiEditTool: ToolMetric(accepted: 15, rejected: 2),
                        writeTool: nil,
                        notebookEditTool: nil
                    ),
                    modelBreakdown: nil
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toUserActivities(response)

        // editAccepted = editTool.accepted + multiEditTool.accepted = 30 + 15 = 45
        #expect(entities[0].editAccepted == 45)
        // editRejected = editTool.rejected + multiEditTool.rejected = 3 + 2 = 5
        #expect(entities[0].editRejected == 5)
    }

    @Test("toUserActivities maps model breakdown to ModelUsage entities")
    func toUserActivitiesMapsModelBreakdown() {
        let response = ClaudeCodeAnalyticsAPIResponse(
            data: [
                ClaudeCodeUserData(
                    date: "2026-01-01",
                    actor: ActorData(type: "user_actor", emailAddress: "u@e.com", apiKeyName: nil),
                    organizationId: nil,
                    customerType: nil,
                    terminalType: nil,
                    coreMetrics: CoreMetrics(
                        numSessions: nil, linesOfCode: nil,
                        commitsByClaudeCode: nil, pullRequestsByClaudeCode: nil
                    ),
                    toolActions: nil,
                    modelBreakdown: [
                        ModelBreakdownData(
                            model: "claude-3-opus-20240229",
                            tokens: TokenData(input: 1000, output: 500, cacheRead: nil, cacheCreation: nil),
                            estimatedCost: CostData(currency: "USD", amount: 200)
                        )
                    ]
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toUserActivities(response)

        #expect(entities[0].models.count == 1)
        #expect(entities[0].models[0].model == "claude-3-opus-20240229")
        #expect(entities[0].models[0].inputTokens == 1000)
        #expect(entities[0].models[0].outputTokens == 500)
        #expect(entities[0].models[0].estimatedCostCents == 200)
    }

    @Test("toUserActivities returns empty array for empty data")
    func toUserActivitiesReturnsEmptyForEmptyData() {
        let response = ClaudeCodeAnalyticsAPIResponse(data: [], hasMore: false, nextPage: nil)
        let entities = AdminAPIMapper.toUserActivities(response)
        #expect(entities.isEmpty)
    }

    // MARK: - toUsageSummary Tests

    @Test("toUsageSummary aggregates tokens by model")
    func toUsageSummaryAggregatesTokensByModel() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end   = Date(timeIntervalSince1970: 1_700_086_400)

        let buckets = [
            OrgUsageBucketEntity(
                startTime: start, endTime: end,
                model: "claude-3-opus", inputTokens: 1000, outputTokens: 500
            ),
            OrgUsageBucketEntity(
                startTime: start, endTime: end,
                model: "claude-3-opus", inputTokens: 500, outputTokens: 250
            )
        ]
        let costs: [OrgCostBucketEntity] = []

        let summary = AdminAPIMapper.toUsageSummary(buckets: buckets, costs: costs, from: start, to: end)

        #expect(summary.totalInputTokens == 1500)
        #expect(summary.totalOutputTokens == 750)
        #expect(summary.byModel.count == 1)
        #expect(summary.byModel[0].model == "claude-3-opus")
        #expect(summary.byModel[0].inputTokens == 1500)
    }

    @Test("toUsageSummary sums total cost from cost buckets")
    func toUsageSummarySumsTotalCost() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end   = Date(timeIntervalSince1970: 1_700_086_400)

        let costs = [
            OrgCostBucketEntity(startTime: start, endTime: end, amountCents: 500, currency: "USD"),
            OrgCostBucketEntity(startTime: start, endTime: end, amountCents: 750, currency: "USD")
        ]

        let summary = AdminAPIMapper.toUsageSummary(buckets: [], costs: costs, from: start, to: end)

        #expect(summary.totalCostCents == 1250)
        #expect(summary.currency == "USD")
    }

    @Test("toUsageSummary uses unknown for bucket without model")
    func toUsageSummaryUsesUnknownForNilModel() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end   = Date(timeIntervalSince1970: 1_700_086_400)

        let buckets = [
            OrgUsageBucketEntity(
                startTime: start, endTime: end,
                model: nil, inputTokens: 100, outputTokens: 50
            )
        ]

        let summary = AdminAPIMapper.toUsageSummary(buckets: buckets, costs: [], from: start, to: end)

        #expect(summary.byModel.count == 1)
        #expect(summary.byModel[0].model == "unknown")
    }

    @Test("toUsageSummary returns empty summary for empty input")
    func toUsageSummaryReturnsEmptyForEmptyInput() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end   = Date(timeIntervalSince1970: 1_700_086_400)

        let summary = AdminAPIMapper.toUsageSummary(buckets: [], costs: [], from: start, to: end)

        #expect(summary.totalInputTokens == 0)
        #expect(summary.totalOutputTokens == 0)
        #expect(summary.totalCostCents == 0)
        #expect(summary.byModel.isEmpty)
    }

    @Test("toUsageSummary sorts by model by total tokens descending")
    func toUsageSummarySortsByModelByTotalTokensDescending() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end   = Date(timeIntervalSince1970: 1_700_086_400)

        let buckets = [
            OrgUsageBucketEntity(
                startTime: start, endTime: end,
                model: "haiku", inputTokens: 100, outputTokens: 50
            ),
            OrgUsageBucketEntity(
                startTime: start, endTime: end,
                model: "opus", inputTokens: 5000, outputTokens: 2500
            ),
            OrgUsageBucketEntity(
                startTime: start, endTime: end,
                model: "sonnet", inputTokens: 1000, outputTokens: 500
            )
        ]

        let summary = AdminAPIMapper.toUsageSummary(buckets: buckets, costs: [], from: start, to: end)

        // Sorted descending: opus (7500) > sonnet (1500) > haiku (150)
        #expect(summary.byModel[0].model == "opus")
        #expect(summary.byModel[1].model == "sonnet")
        #expect(summary.byModel[2].model == "haiku")
    }
}
