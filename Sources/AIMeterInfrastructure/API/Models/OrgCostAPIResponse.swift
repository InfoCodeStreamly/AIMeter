import Foundation
import AIMeterDomain
import AIMeterApplication

/// Raw API response for organization cost report
/// Endpoint: /v1/organizations/cost_report
public struct OrgCostAPIResponse: Sendable, Codable {
    public let data: [OrgCostBucketData]
    public let hasMore: Bool
    public let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }
}

/// Single cost bucket from the API
/// Note: `amount` is a decimal string in cents (e.g., "1250" = $12.50)
public struct OrgCostBucketData: Sendable, Codable {
    public let snapshotStartTime: String
    public let snapshotEndTime: String
    public let workspaceId: String?
    public let description: String?
    public let amount: String

    enum CodingKeys: String, CodingKey {
        case snapshotStartTime = "snapshot_start_time"
        case snapshotEndTime = "snapshot_end_time"
        case workspaceId = "workspace_id"
        case description
        case amount
    }
}
