import Foundation
import AIMeterDomain
import AIMeterApplication

/// Raw API response for organization usage report
/// Endpoint: /v1/organizations/usage_report/messages
public struct OrgUsageAPIResponse: Sendable, Codable {
    public let data: [OrgUsageBucketData]
    public let hasMore: Bool
    public let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }
}

/// Single usage bucket from the API
public struct OrgUsageBucketData: Sendable, Codable {
    public let snapshotStartTime: String
    public let snapshotEndTime: String
    public let model: String?
    public let workspaceId: String?
    public let inputTokens: Int?
    public let outputTokens: Int?
    public let cacheReadInputTokens: Int?
    public let cacheCreationInputTokens: Int?

    enum CodingKeys: String, CodingKey {
        case snapshotStartTime = "snapshot_start_time"
        case snapshotEndTime = "snapshot_end_time"
        case model
        case workspaceId = "workspace_id"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
        case cacheCreationInputTokens = "cache_creation_input_tokens"
    }
}
