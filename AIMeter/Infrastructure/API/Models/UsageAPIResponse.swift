import Foundation

/// Raw API response for usage data from OAuth endpoint
/// Endpoint: api.anthropic.com/api/oauth/usage
struct UsageAPIResponse: Sendable, Codable {
    let fiveHour: UsagePeriodData?
    let sevenDay: UsagePeriodData?
    let sevenDayOpus: UsagePeriodData?
    let sevenDaySonnet: UsagePeriodData?
    let sevenDayOauthApps: UsagePeriodData?
    let extraUsage: ExtraUsageData?

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
struct UsagePeriodData: Sendable, Codable {
    let utilization: Double
    let resetsAt: String

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

/// Extra usage data (pay-as-you-go)
struct ExtraUsageData: Sendable, Codable {
    let isEnabled: Bool?
    let monthlyLimit: Double?
    let usedCredits: Double?
    let utilization: Double?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case utilization
    }
}
