import Foundation

/// Data Transfer Object for usage data from API
struct UsageDTO: Sendable, Codable {
    let type: String
    let percentageUsed: Double
    let resetAt: String

    enum CodingKeys: String, CodingKey {
        case type
        case percentageUsed = "percentage_used"
        case resetAt = "reset_at"
    }
}

/// Response wrapper from Claude API
struct UsageResponseDTO: Sendable, Codable {
    let sessionLimit: UsageLimitDTO?
    let weeklyLimit: UsageLimitDTO?
    let opusLimit: UsageLimitDTO?
    let sonnetLimit: UsageLimitDTO?

    enum CodingKeys: String, CodingKey {
        case sessionLimit = "session_limit"
        case weeklyLimit = "weekly_limit"
        case opusLimit = "opus_limit"
        case sonnetLimit = "sonnet_limit"
    }
}

/// Individual limit data from API
struct UsageLimitDTO: Sendable, Codable {
    let percentageUsed: Double
    let resetAt: String

    enum CodingKeys: String, CodingKey {
        case percentageUsed = "percentage_used"
        case resetAt = "reset_at"
    }
}
