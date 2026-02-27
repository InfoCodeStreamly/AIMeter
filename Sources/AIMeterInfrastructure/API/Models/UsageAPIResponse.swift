import Foundation
import AIMeterDomain
import AIMeterApplication

/// Raw API response for usage data from OAuth endpoint
/// Endpoint: api.anthropic.com/api/oauth/usage
public struct UsageAPIResponse: Sendable, Codable {
    public let fiveHour: UsagePeriodData?
    public let sevenDay: UsagePeriodData?
    public let sevenDayOpus: UsagePeriodData?
    public let sevenDaySonnet: UsagePeriodData?
    public let sevenDayOauthApps: UsagePeriodData?
    public let extraUsage: ExtraUsageData?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOpus = "seven_day_opus"
        case sevenDaySonnet = "seven_day_sonnet"
        case sevenDayOauthApps = "seven_day_oauth_apps"
        case extraUsage = "extra_usage"
    }
}

/// Usage period data
/// Fields: utilization (0-100), resets_at (ISO8601)
public struct UsagePeriodData: Sendable, Codable {
    public let utilization: Double?
    public let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

/// Extra usage data (pay-as-you-go)
public struct ExtraUsageData: Sendable, Codable {
    public let isEnabled: Bool?
    public let monthlyLimit: Double?
    public let usedCredits: Double?
    public let utilization: Double?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case utilization
    }
}
