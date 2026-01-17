import Foundation
@testable import AIMeter

final class UsageDTOBuilder {

    // MARK: - Properties
    private var sessionPercentage: Double? = 45.0
    private var weeklyPercentage: Double? = 30.0
    private var opusPercentage: Double? = 10.0
    private var sonnetPercentage: Double? = 25.0
    private var resetDate: Date = Date().addingTimeInterval(3600 * 5)

    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    // MARK: - Builder Methods
    func withSessionPercentage(_ value: Double?) -> Self {
        sessionPercentage = value
        return self
    }

    func withWeeklyPercentage(_ value: Double?) -> Self {
        weeklyPercentage = value
        return self
    }

    func withOpusPercentage(_ value: Double?) -> Self {
        opusPercentage = value
        return self
    }

    func withSonnetPercentage(_ value: Double?) -> Self {
        sonnetPercentage = value
        return self
    }

    func withResetDate(_ date: Date) -> Self {
        resetDate = date
        return self
    }

    func allSafe() -> Self {
        sessionPercentage = PercentageFixtures.safe
        weeklyPercentage = 30.0
        opusPercentage = 10.0
        sonnetPercentage = 25.0
        return self
    }

    func sessionCritical() -> Self {
        sessionPercentage = PercentageFixtures.critical
        return self
    }

    func onlySession() -> Self {
        weeklyPercentage = nil
        opusPercentage = nil
        sonnetPercentage = nil
        return self
    }

    func empty() -> Self {
        sessionPercentage = nil
        weeklyPercentage = nil
        opusPercentage = nil
        sonnetPercentage = nil
        return self
    }

    // MARK: - Build
    func build() -> UsageResponseDTO {
        let resetAt = isoFormatter.string(from: resetDate)

        return UsageResponseDTO(
            sessionLimit: sessionPercentage.map {
                UsageLimitDTO(percentageUsed: $0, resetAt: resetAt)
            },
            weeklyLimit: weeklyPercentage.map {
                UsageLimitDTO(percentageUsed: $0, resetAt: resetAt)
            },
            opusLimit: opusPercentage.map {
                UsageLimitDTO(percentageUsed: $0, resetAt: resetAt)
            },
            sonnetLimit: sonnetPercentage.map {
                UsageLimitDTO(percentageUsed: $0, resetAt: resetAt)
            }
        )
    }

    func buildJSON() -> String {
        let resetAt = isoFormatter.string(from: resetDate)
        var parts: [String] = []

        if let s = sessionPercentage {
            parts.append("""
            "session_limit": {"percentage_used": \(s), "reset_at": "\(resetAt)"}
            """)
        }
        if let w = weeklyPercentage {
            parts.append("""
            "weekly_limit": {"percentage_used": \(w), "reset_at": "\(resetAt)"}
            """)
        }
        if let o = opusPercentage {
            parts.append("""
            "opus_limit": {"percentage_used": \(o), "reset_at": "\(resetAt)"}
            """)
        }
        if let sn = sonnetPercentage {
            parts.append("""
            "sonnet_limit": {"percentage_used": \(sn), "reset_at": "\(resetAt)"}
            """)
        }

        return "{\(parts.joined(separator: ", "))}"
    }

    func buildData() -> Data {
        buildJSON().data(using: .utf8)!
    }
}
