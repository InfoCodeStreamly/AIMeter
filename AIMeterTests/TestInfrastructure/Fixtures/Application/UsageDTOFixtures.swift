import Foundation
@testable import AIMeter

enum UsageDTOFixtures {

    // MARK: - Base Values (SSOT)
    static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static var futureResetAt: String {
        isoDateFormatter.string(from: ResetTimeFixtures.inFiveHours)
    }

    static var weeklyResetAt: String {
        isoDateFormatter.string(from: ResetTimeFixtures.inSevenDays)
    }

    // MARK: - UsageDTO Objects
    static var sessionDTO: UsageDTO {
        UsageDTO(
            type: "session",
            percentageUsed: PercentageFixtures.safe,
            resetAt: futureResetAt
        )
    }

    static var weeklyDTO: UsageDTO {
        UsageDTO(
            type: "weekly",
            percentageUsed: 30.0,
            resetAt: weeklyResetAt
        )
    }

    // MARK: - UsageLimitDTO Objects
    static var sessionLimitSafe: UsageLimitDTO {
        UsageLimitDTO(
            percentageUsed: PercentageFixtures.safe,
            resetAt: futureResetAt
        )
    }

    static var sessionLimitCritical: UsageLimitDTO {
        UsageLimitDTO(
            percentageUsed: PercentageFixtures.critical,
            resetAt: futureResetAt
        )
    }

    static var weeklyLimitSafe: UsageLimitDTO {
        UsageLimitDTO(
            percentageUsed: 30.0,
            resetAt: weeklyResetAt
        )
    }

    static var opusLimitSafe: UsageLimitDTO {
        UsageLimitDTO(
            percentageUsed: 10.0,
            resetAt: weeklyResetAt
        )
    }

    static var sonnetLimitSafe: UsageLimitDTO {
        UsageLimitDTO(
            percentageUsed: 25.0,
            resetAt: weeklyResetAt
        )
    }

    // MARK: - UsageResponseDTO Objects
    static var responseSafe: UsageResponseDTO {
        UsageResponseDTO(
            sessionLimit: sessionLimitSafe,
            weeklyLimit: weeklyLimitSafe,
            opusLimit: opusLimitSafe,
            sonnetLimit: sonnetLimitSafe
        )
    }

    static var responseCritical: UsageResponseDTO {
        UsageResponseDTO(
            sessionLimit: sessionLimitCritical,
            weeklyLimit: weeklyLimitSafe,
            opusLimit: opusLimitSafe,
            sonnetLimit: sonnetLimitSafe
        )
    }

    static var responsePartial: UsageResponseDTO {
        UsageResponseDTO(
            sessionLimit: sessionLimitSafe,
            weeklyLimit: nil,
            opusLimit: nil,
            sonnetLimit: nil
        )
    }

    static var responseEmpty: UsageResponseDTO {
        UsageResponseDTO(
            sessionLimit: nil,
            weeklyLimit: nil,
            opusLimit: nil,
            sonnetLimit: nil
        )
    }
}
