import Foundation
import AIMeterDomain
import AIMeterApplication

/// Raw API response for organization usage report
/// Endpoint: GET /v1/organizations/usage_report/messages
/// Docs: https://platform.claude.com/docs/en/api/admin-api/usage-cost/get-messages-usage-report
public struct OrgUsageAPIResponse: Sendable, Codable {
    public let data: [OrgUsageTimeBucket]
    public let hasMore: Bool
    public let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }
}

/// A single time bucket containing usage results
public struct OrgUsageTimeBucket: Sendable, Codable {
    public let startingAt: String
    public let endingAt: String
    public let results: [OrgUsageResultData]

    enum CodingKeys: String, CodingKey {
        case startingAt = "starting_at"
        case endingAt = "ending_at"
        case results
    }
}

/// Single usage result within a time bucket
/// Multiple results per bucket when group_by[] is specified
public struct OrgUsageResultData: Sendable, Codable {
    public let uncachedInputTokens: Int?
    public let outputTokens: Int?
    public let cacheReadInputTokens: Int?
    public let cacheCreation: CacheCreationData?
    public let model: String?
    public let apiKeyId: String?
    public let workspaceId: String?
    public let serviceTier: String?
    public let contextWindow: String?
    public let inferenceGeo: String?
    public let serverToolUse: ServerToolUseData?

    enum CodingKeys: String, CodingKey {
        case uncachedInputTokens = "uncached_input_tokens"
        case outputTokens = "output_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
        case cacheCreation = "cache_creation"
        case model
        case apiKeyId = "api_key_id"
        case workspaceId = "workspace_id"
        case serviceTier = "service_tier"
        case contextWindow = "context_window"
        case inferenceGeo = "inference_geo"
        case serverToolUse = "server_tool_use"
    }
}

/// Cache creation token breakdown
public struct CacheCreationData: Sendable, Codable {
    public let ephemeral1hInputTokens: Int?
    public let ephemeral5mInputTokens: Int?

    enum CodingKeys: String, CodingKey {
        case ephemeral1hInputTokens = "ephemeral_1h_input_tokens"
        case ephemeral5mInputTokens = "ephemeral_5m_input_tokens"
    }
}

/// Server-side tool usage metrics
public struct ServerToolUseData: Sendable, Codable {
    public let webSearchRequests: Int?

    enum CodingKeys: String, CodingKey {
        case webSearchRequests = "web_search_requests"
    }
}
