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
                OrgUsageTimeBucket(
                    startingAt: "2026-01-01T00:00:00Z",
                    endingAt: "2026-01-01T01:00:00Z",
                    results: [
                        OrgUsageResultData(
                            uncachedInputTokens: 1000,
                            outputTokens: 500,
                            cacheReadInputTokens: 200,
                            cacheCreation: CacheCreationData(
                                ephemeral1hInputTokens: 80,
                                ephemeral5mInputTokens: 20
                            ),
                            model: "claude-3-opus-20240229",
                            apiKeyId: nil,
                            workspaceId: "ws-abc",
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil,
                            serverToolUse: nil
                        )
                    ]
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
        #expect(entities[0].cacheCreationTokens == 100) // 80 + 20
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
                OrgUsageTimeBucket(
                    startingAt: "invalid-date",
                    endingAt: "2026-01-01T01:00:00Z",
                    results: [
                        OrgUsageResultData(
                            uncachedInputTokens: 100,
                            outputTokens: 50,
                            cacheReadInputTokens: nil,
                            cacheCreation: nil,
                            model: nil,
                            apiKeyId: nil,
                            workspaceId: nil,
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil,
                            serverToolUse: nil
                        )
                    ]
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
                OrgUsageTimeBucket(
                    startingAt: "2026-01-01T00:00:00Z",
                    endingAt: "not-a-date",
                    results: [
                        OrgUsageResultData(
                            uncachedInputTokens: 100,
                            outputTokens: 50,
                            cacheReadInputTokens: nil,
                            cacheCreation: nil,
                            model: nil,
                            apiKeyId: nil,
                            workspaceId: nil,
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil,
                            serverToolUse: nil
                        )
                    ]
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
                OrgUsageTimeBucket(
                    startingAt: "2026-01-01T00:00:00Z",
                    endingAt: "2026-01-01T01:00:00Z",
                    results: [
                        OrgUsageResultData(
                            uncachedInputTokens: nil,
                            outputTokens: nil,
                            cacheReadInputTokens: nil,
                            cacheCreation: nil,
                            model: nil,
                            apiKeyId: nil,
                            workspaceId: nil,
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil,
                            serverToolUse: nil
                        )
                    ]
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
                OrgUsageTimeBucket(
                    startingAt: "2026-01-01T00:00:00Z",
                    endingAt: "2026-01-01T01:00:00Z",
                    results: [
                        OrgUsageResultData(
                            uncachedInputTokens: 100,
                            outputTokens: 50,
                            cacheReadInputTokens: nil,
                            cacheCreation: nil,
                            model: nil,
                            apiKeyId: nil,
                            workspaceId: nil,
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil,
                            serverToolUse: nil
                        )
                    ]
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

    @Test("toUsageBuckets maps multiple results per bucket to separate entities")
    func toUsageBucketsMapsMultipleResultsPerBucket() {
        let response = OrgUsageAPIResponse(
            data: [
                OrgUsageTimeBucket(
                    startingAt: "2026-01-01T00:00:00Z",
                    endingAt: "2026-01-01T01:00:00Z",
                    results: [
                        OrgUsageResultData(
                            uncachedInputTokens: 1000,
                            outputTokens: 500,
                            cacheReadInputTokens: nil,
                            cacheCreation: nil,
                            model: "claude-sonnet-4-6",
                            apiKeyId: "apikey_01abc",
                            workspaceId: nil,
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil,
                            serverToolUse: nil
                        ),
                        OrgUsageResultData(
                            uncachedInputTokens: 2000,
                            outputTokens: 800,
                            cacheReadInputTokens: nil,
                            cacheCreation: nil,
                            model: "claude-haiku-4-5",
                            apiKeyId: "apikey_02def",
                            workspaceId: nil,
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil,
                            serverToolUse: nil
                        )
                    ]
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toUsageBuckets(response)

        #expect(entities.count == 2)
        #expect(entities[0].model == "claude-sonnet-4-6")
        #expect(entities[0].inputTokens == 1000)
        #expect(entities[1].model == "claude-haiku-4-5")
        #expect(entities[1].inputTokens == 2000)
    }

    @Test("toUsageBuckets sums ephemeral cache creation tokens")
    func toUsageBucketsSumsCacheCreationTokens() {
        let response = OrgUsageAPIResponse(
            data: [
                OrgUsageTimeBucket(
                    startingAt: "2026-01-01T00:00:00Z",
                    endingAt: "2026-01-01T01:00:00Z",
                    results: [
                        OrgUsageResultData(
                            uncachedInputTokens: nil,
                            outputTokens: nil,
                            cacheReadInputTokens: nil,
                            cacheCreation: CacheCreationData(
                                ephemeral1hInputTokens: 300,
                                ephemeral5mInputTokens: 150
                            ),
                            model: nil,
                            apiKeyId: nil,
                            workspaceId: nil,
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil,
                            serverToolUse: nil
                        )
                    ]
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toUsageBuckets(response)

        #expect(entities.count == 1)
        #expect(entities[0].cacheCreationTokens == 450) // 300 + 150
    }

    // MARK: - toCostBuckets Tests

    @Test("toCostBuckets maps response data to domain entities")
    func toCostBucketsMapsResponseData() {
        let response = OrgCostAPIResponse(
            data: [
                OrgCostTimeBucket(
                    startingAt: "2026-01-01T00:00:00Z",
                    endingAt: "2026-01-01T01:00:00Z",
                    results: [
                        OrgCostResultData(
                            amount: "1250",
                            currency: nil,
                            model: nil,
                            costType: nil,
                            tokenType: nil,
                            description: "Claude API usage",
                            workspaceId: "ws-abc",
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil
                        )
                    ]
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
                OrgCostTimeBucket(
                    startingAt: "2026-01-01T00:00:00Z",
                    endingAt: "2026-01-01T01:00:00Z",
                    results: [
                        OrgCostResultData(
                            amount: "1250.75",
                            currency: nil,
                            model: nil,
                            costType: nil,
                            tokenType: nil,
                            description: nil,
                            workspaceId: nil,
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil
                        )
                    ]
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
                OrgCostTimeBucket(
                    startingAt: "bad-date",
                    endingAt: "also-bad",
                    results: [
                        OrgCostResultData(
                            amount: "100",
                            currency: nil,
                            model: nil,
                            costType: nil,
                            tokenType: nil,
                            description: nil,
                            workspaceId: nil,
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil
                        )
                    ]
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
                OrgCostTimeBucket(
                    startingAt: "2026-01-01T00:00:00Z",
                    endingAt: "2026-01-01T01:00:00Z",
                    results: [
                        OrgCostResultData(
                            amount: "not-a-number",
                            currency: nil,
                            model: nil,
                            costType: nil,
                            tokenType: nil,
                            description: nil,
                            workspaceId: nil,
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil
                        )
                    ]
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toCostBuckets(response)
        #expect(entities.count == 1)
        #expect(entities[0].amountCents == 0)
    }

    @Test("toCostBuckets maps multiple results per bucket to separate entities")
    func toCostBucketsMapsMultipleResultsPerBucket() {
        let response = OrgCostAPIResponse(
            data: [
                OrgCostTimeBucket(
                    startingAt: "2026-01-01T00:00:00Z",
                    endingAt: "2026-01-02T00:00:00Z",
                    results: [
                        OrgCostResultData(
                            amount: "500",
                            currency: "USD",
                            model: "claude-sonnet-4-6",
                            costType: "tokens",
                            tokenType: "uncached_input_tokens",
                            description: nil,
                            workspaceId: nil,
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil
                        ),
                        OrgCostResultData(
                            amount: "200",
                            currency: "USD",
                            model: nil,
                            costType: "web_search",
                            tokenType: nil,
                            description: nil,
                            workspaceId: nil,
                            serviceTier: nil,
                            contextWindow: nil,
                            inferenceGeo: nil
                        )
                    ]
                )
            ],
            hasMore: false,
            nextPage: nil
        )

        let entities = AdminAPIMapper.toCostBuckets(response)

        #expect(entities.count == 2)
        #expect(entities[0].amountCents == 500)
        #expect(entities[1].amountCents == 200)
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
