import Testing
@testable import AIMeterInfrastructure
import Foundation

/// Tests for ClaudeCodeAnalyticsAPIResponse JSON decoding — including nested structures.
@Suite("ClaudeCodeAnalyticsAPIResponse")
struct ClaudeCodeAnalyticsAPIResponseTests {

    // MARK: - Top-Level Response Decoding Tests

    @Test("decodes complete response with all fields")
    func decodesCompleteResponse() throws {
        let json = """
        {
          "data": [
            {
              "date": "2026-01-01",
              "actor": {
                "type": "user_actor",
                "email_address": "user@example.com",
                "api_key_name": null
              },
              "organization_id": "org-abc123",
              "customer_type": "enterprise",
              "terminal_type": "vscode",
              "core_metrics": {
                "num_sessions": 5,
                "lines_of_code": {
                  "added": 200,
                  "removed": 50
                },
                "commits_by_claude_code": 3,
                "pull_requests_by_claude_code": 1
              },
              "tool_actions": {
                "edit_tool": { "accepted": 45, "rejected": 5 },
                "multi_edit_tool": { "accepted": 10, "rejected": 2 },
                "write_tool": { "accepted": 8, "rejected": 1 },
                "notebook_edit_tool": { "accepted": 2, "rejected": 0 }
              },
              "model_breakdown": [
                {
                  "model": "claude-3-opus-20240229",
                  "tokens": { "input": 1000, "output": 500, "cache_read": 100, "cache_creation": 50 },
                  "estimated_cost": { "currency": "USD", "amount": 200 }
                }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ClaudeCodeAnalyticsAPIResponse.self, from: json)

        #expect(response.data.count == 1)
        #expect(response.hasMore == false)
        #expect(response.nextPage == nil)

        let user = response.data[0]
        #expect(user.date == "2026-01-01")
        #expect(user.actor.type == "user_actor")
        #expect(user.actor.emailAddress == "user@example.com")
        #expect(user.organizationId == "org-abc123")
        #expect(user.customerType == "enterprise")
        #expect(user.terminalType == "vscode")
    }

    @Test("decodes empty data array")
    func decodesEmptyDataArray() throws {
        let json = """
        {
          "data": [],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ClaudeCodeAnalyticsAPIResponse.self, from: json)

        #expect(response.data.isEmpty)
    }

    @Test("decodes pagination fields")
    func decodesPaginationFields() throws {
        let json = """
        {
          "data": [],
          "has_more": true,
          "next_page": "cursor_xyz"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ClaudeCodeAnalyticsAPIResponse.self, from: json)

        #expect(response.hasMore == true)
        #expect(response.nextPage == "cursor_xyz")
    }

    // MARK: - ActorData Decoding Tests

    @Test("decodes user_actor with email address")
    func decodesUserActorWithEmail() throws {
        let json = """
        {
          "type": "user_actor",
          "email_address": "dev@example.com",
          "api_key_name": null
        }
        """.data(using: .utf8)!

        let actor = try JSONDecoder().decode(ActorData.self, from: json)

        #expect(actor.type == "user_actor")
        #expect(actor.emailAddress == "dev@example.com")
        #expect(actor.apiKeyName == nil)
    }

    @Test("decodes api_key actor with api_key_name")
    func decodesApiKeyActorWithName() throws {
        let json = """
        {
          "type": "api_key_actor",
          "email_address": null,
          "api_key_name": "production-key"
        }
        """.data(using: .utf8)!

        let actor = try JSONDecoder().decode(ActorData.self, from: json)

        #expect(actor.type == "api_key_actor")
        #expect(actor.emailAddress == nil)
        #expect(actor.apiKeyName == "production-key")
    }

    // MARK: - CoreMetrics Decoding Tests

    @Test("decodes core_metrics with all fields")
    func decodesCoreMetricsComplete() throws {
        let json = """
        {
          "num_sessions": 7,
          "lines_of_code": { "added": 300, "removed": 80 },
          "commits_by_claude_code": 5,
          "pull_requests_by_claude_code": 2
        }
        """.data(using: .utf8)!

        let metrics = try JSONDecoder().decode(CoreMetrics.self, from: json)

        #expect(metrics.numSessions == 7)
        #expect(metrics.linesOfCode?.added == 300)
        #expect(metrics.linesOfCode?.removed == 80)
        #expect(metrics.commitsByClaudeCode == 5)
        #expect(metrics.pullRequestsByClaudeCode == 2)
    }

    @Test("decodes core_metrics with all optional fields nil")
    func decodesCoreMetricsAllNil() throws {
        let json = "{}".data(using: .utf8)!

        let metrics = try JSONDecoder().decode(CoreMetrics.self, from: json)

        #expect(metrics.numSessions == nil)
        #expect(metrics.linesOfCode == nil)
        #expect(metrics.commitsByClaudeCode == nil)
        #expect(metrics.pullRequestsByClaudeCode == nil)
    }

    // MARK: - ToolActions Decoding Tests

    @Test("decodes tool_actions with all tools")
    func decodesToolActionsComplete() throws {
        let json = """
        {
          "edit_tool": { "accepted": 45, "rejected": 5 },
          "multi_edit_tool": { "accepted": 10, "rejected": 2 },
          "write_tool": { "accepted": 8, "rejected": 1 },
          "notebook_edit_tool": { "accepted": 2, "rejected": 0 }
        }
        """.data(using: .utf8)!

        let actions = try JSONDecoder().decode(ToolActions.self, from: json)

        #expect(actions.editTool?.accepted == 45)
        #expect(actions.editTool?.rejected == 5)
        #expect(actions.multiEditTool?.accepted == 10)
        #expect(actions.writeTool?.accepted == 8)
        #expect(actions.notebookEditTool?.accepted == 2)
    }

    @Test("decodes tool_actions with optional tools nil")
    func decodesToolActionsWithNilTools() throws {
        let json = """
        {
          "edit_tool": { "accepted": 20, "rejected": 3 }
        }
        """.data(using: .utf8)!

        let actions = try JSONDecoder().decode(ToolActions.self, from: json)

        #expect(actions.editTool?.accepted == 20)
        #expect(actions.multiEditTool == nil)
        #expect(actions.writeTool == nil)
        #expect(actions.notebookEditTool == nil)
    }

    // MARK: - ModelBreakdownData Decoding Tests

    @Test("decodes model_breakdown with all fields")
    func decodesModelBreakdownComplete() throws {
        let json = """
        {
          "model": "claude-3-opus-20240229",
          "tokens": { "input": 1000, "output": 500, "cache_read": 100, "cache_creation": 50 },
          "estimated_cost": { "currency": "USD", "amount": 200 }
        }
        """.data(using: .utf8)!

        let breakdown = try JSONDecoder().decode(ModelBreakdownData.self, from: json)

        #expect(breakdown.model == "claude-3-opus-20240229")
        #expect(breakdown.tokens?.input == 1000)
        #expect(breakdown.tokens?.output == 500)
        #expect(breakdown.tokens?.cacheRead == 100)
        #expect(breakdown.tokens?.cacheCreation == 50)
        #expect(breakdown.estimatedCost?.currency == "USD")
        #expect(breakdown.estimatedCost?.amount == 200)
    }

    @Test("decodes model_breakdown with nil tokens and cost")
    func decodesModelBreakdownWithNilFields() throws {
        let json = """
        {
          "model": "claude-3-haiku-20240307"
        }
        """.data(using: .utf8)!

        let breakdown = try JSONDecoder().decode(ModelBreakdownData.self, from: json)

        #expect(breakdown.model == "claude-3-haiku-20240307")
        #expect(breakdown.tokens == nil)
        #expect(breakdown.estimatedCost == nil)
    }

    // MARK: - ClaudeCodeUserData Optional Fields Tests

    @Test("decodes user data with minimal required fields")
    func decodesUserDataMinimalFields() throws {
        let json = """
        {
          "data": [
            {
              "date": "2026-01-01",
              "actor": {
                "type": "user_actor"
              },
              "core_metrics": {}
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ClaudeCodeAnalyticsAPIResponse.self, from: json)

        let user = response.data[0]
        #expect(user.date == "2026-01-01")
        #expect(user.actor.type == "user_actor")
        #expect(user.organizationId == nil)
        #expect(user.customerType == nil)
        #expect(user.terminalType == nil)
        #expect(user.toolActions == nil)
        #expect(user.modelBreakdown == nil)
    }

    @Test("decodes user data with empty model_breakdown array")
    func decodesUserDataWithEmptyModelBreakdown() throws {
        let json = """
        {
          "data": [
            {
              "date": "2026-01-01",
              "actor": { "type": "user_actor" },
              "core_metrics": {},
              "model_breakdown": []
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ClaudeCodeAnalyticsAPIResponse.self, from: json)

        #expect(response.data[0].modelBreakdown?.isEmpty == true)
    }

    @Test("snake_case field names decode correctly in nested structures")
    func snakeCaseFieldsDecodeCorrectlyInNestedStructures() throws {
        let json = """
        {
          "data": [
            {
              "date": "2026-01-01",
              "actor": {
                "type": "api_key_actor",
                "email_address": null,
                "api_key_name": "my-key"
              },
              "organization_id": "org-1",
              "customer_type": "api",
              "terminal_type": "cursor",
              "core_metrics": {
                "num_sessions": 3,
                "lines_of_code": { "added": 100, "removed": 20 },
                "commits_by_claude_code": 2,
                "pull_requests_by_claude_code": 0
              },
              "tool_actions": {
                "edit_tool": { "accepted": 10, "rejected": 1 },
                "write_tool": { "accepted": 5, "rejected": 0 }
              },
              "model_breakdown": [
                {
                  "model": "claude-3-haiku-20240307",
                  "tokens": { "input": 500, "output": 250, "cache_read": 0, "cache_creation": 0 },
                  "estimated_cost": { "currency": "USD", "amount": 50 }
                }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ClaudeCodeAnalyticsAPIResponse.self, from: json)

        let user = response.data[0]
        #expect(user.actor.apiKeyName == "my-key")
        #expect(user.organizationId == "org-1")
        #expect(user.customerType == "api")
        #expect(user.coreMetrics.numSessions == 3)
        #expect(user.coreMetrics.linesOfCode?.added == 100)
        #expect(user.coreMetrics.commitsByClaudeCode == 2)
        #expect(user.coreMetrics.pullRequestsByClaudeCode == 0)
        #expect(user.toolActions?.editTool?.accepted == 10)
        #expect(user.modelBreakdown?.first?.model == "claude-3-haiku-20240307")
        #expect(user.modelBreakdown?.first?.tokens?.input == 500)
    }
}
