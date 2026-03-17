import Foundation
import AIMeterDomain
import AIMeterApplication

/// Raw API response for organization cost report
/// Endpoint: GET /v1/organizations/cost_report
/// Docs: https://platform.claude.com/docs/en/api/admin-api/usage-cost/get-cost-report
public struct OrgCostAPIResponse: Sendable, Codable {
    public let data: [OrgCostTimeBucket]
    public let hasMore: Bool
    public let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }
}

/// A single time bucket containing cost results
public struct OrgCostTimeBucket: Sendable, Codable {
    public let startingAt: String
    public let endingAt: String
    public let results: [OrgCostResultData]

    enum CodingKeys: String, CodingKey {
        case startingAt = "starting_at"
        case endingAt = "ending_at"
        case results
    }
}

/// Single cost result within a time bucket
/// Multiple results per bucket when group_by[] is specified
/// Note: `amount` is a decimal string in lowest currency units (cents)
/// e.g., "123.45" in USD = $1.2345
public struct OrgCostResultData: Sendable, Codable {
    public let amount: String
    public let currency: String?
    public let model: String?
    public let costType: String?
    public let tokenType: String?
    public let description: String?
    public let workspaceId: String?
    public let serviceTier: String?
    public let contextWindow: String?
    public let inferenceGeo: String?

    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case model
        case costType = "cost_type"
        case tokenType = "token_type"
        case description
        case workspaceId = "workspace_id"
        case serviceTier = "service_tier"
        case contextWindow = "context_window"
        case inferenceGeo = "inference_geo"
    }
}
