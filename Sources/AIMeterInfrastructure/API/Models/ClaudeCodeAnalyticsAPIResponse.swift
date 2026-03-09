import Foundation
import AIMeterDomain
import AIMeterApplication

/// Raw API response for Claude Code analytics
/// Endpoint: /v1/organizations/usage_report/claude_code
public struct ClaudeCodeAnalyticsAPIResponse: Sendable, Codable {
    public let data: [ClaudeCodeUserData]
    public let hasMore: Bool
    public let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }
}

/// Single user's activity data for a day
public struct ClaudeCodeUserData: Sendable, Codable {
    public let date: String
    public let actor: ActorData
    public let organizationId: String?
    public let customerType: String?
    public let terminalType: String?
    public let coreMetrics: CoreMetrics
    public let toolActions: ToolActions?
    public let modelBreakdown: [ModelBreakdownData]?

    enum CodingKeys: String, CodingKey {
        case date
        case actor
        case organizationId = "organization_id"
        case customerType = "customer_type"
        case terminalType = "terminal_type"
        case coreMetrics = "core_metrics"
        case toolActions = "tool_actions"
        case modelBreakdown = "model_breakdown"
    }
}

/// Actor identification (user or API key)
public struct ActorData: Sendable, Codable {
    public let type: String
    public let emailAddress: String?
    public let apiKeyName: String?

    enum CodingKeys: String, CodingKey {
        case type
        case emailAddress = "email_address"
        case apiKeyName = "api_key_name"
    }
}

/// Core productivity metrics
public struct CoreMetrics: Sendable, Codable {
    public let numSessions: Int?
    public let linesOfCode: LinesOfCode?
    public let commitsByClaudeCode: Int?
    public let pullRequestsByClaudeCode: Int?

    enum CodingKeys: String, CodingKey {
        case numSessions = "num_sessions"
        case linesOfCode = "lines_of_code"
        case commitsByClaudeCode = "commits_by_claude_code"
        case pullRequestsByClaudeCode = "pull_requests_by_claude_code"
    }
}

/// Lines of code added/removed
public struct LinesOfCode: Sendable, Codable {
    public let added: Int?
    public let removed: Int?
}

/// Tool acceptance/rejection metrics
public struct ToolActions: Sendable, Codable {
    public let editTool: ToolMetric?
    public let multiEditTool: ToolMetric?
    public let writeTool: ToolMetric?
    public let notebookEditTool: ToolMetric?

    enum CodingKeys: String, CodingKey {
        case editTool = "edit_tool"
        case multiEditTool = "multi_edit_tool"
        case writeTool = "write_tool"
        case notebookEditTool = "notebook_edit_tool"
    }
}

/// Single tool metric (accepted/rejected count)
public struct ToolMetric: Sendable, Codable {
    public let accepted: Int?
    public let rejected: Int?
}

/// Per-model usage breakdown
public struct ModelBreakdownData: Sendable, Codable {
    public let model: String
    public let tokens: TokenData?
    public let estimatedCost: CostData?

    enum CodingKeys: String, CodingKey {
        case model
        case tokens
        case estimatedCost = "estimated_cost"
    }
}

/// Token usage data
public struct TokenData: Sendable, Codable {
    public let input: Int?
    public let output: Int?
    public let cacheRead: Int?
    public let cacheCreation: Int?

    enum CodingKeys: String, CodingKey {
        case input
        case output
        case cacheRead = "cache_read"
        case cacheCreation = "cache_creation"
    }
}

/// Cost data
public struct CostData: Sendable, Codable {
    public let currency: String?
    public let amount: Int?
}
