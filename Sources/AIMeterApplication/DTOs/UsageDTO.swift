import Foundation
import AIMeterDomain

/// Data Transfer Object for usage data from API
public struct UsageDTO: Sendable, Codable {
    public let type: String
    public let percentageUsed: Double
    public let resetAt: String

    enum CodingKeys: String, CodingKey {
        case type
        case percentageUsed = "percentage_used"
        case resetAt = "reset_at"
    }
}

/// Response wrapper from Claude API
public struct UsageResponseDTO: Sendable, Codable {
    public let sessionLimit: UsageLimitDTO?
    public let weeklyLimit: UsageLimitDTO?
    public let opusLimit: UsageLimitDTO?
    public let sonnetLimit: UsageLimitDTO?

    enum CodingKeys: String, CodingKey {
        case sessionLimit = "session_limit"
        case weeklyLimit = "weekly_limit"
        case opusLimit = "opus_limit"
        case sonnetLimit = "sonnet_limit"
    }
}

/// Individual limit data from API
public struct UsageLimitDTO: Sendable, Codable {
    public let percentageUsed: Double
    public let resetAt: String

    enum CodingKeys: String, CodingKey {
        case percentageUsed = "percentage_used"
        case resetAt = "reset_at"
    }
}
