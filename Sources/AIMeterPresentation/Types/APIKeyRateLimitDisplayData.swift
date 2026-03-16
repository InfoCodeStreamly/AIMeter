import Foundation
import AIMeterDomain

/// Pre-formatted display data for API key rate limits
public struct APIKeyRateLimitDisplayData: Sendable, Equatable {
    public let requestsRemaining: String
    public let inputTokensRemaining: String
    public let outputTokensRemaining: String
    public let requestsPercent: Int
    public let inputTokensPercent: Int
    public let outputTokensPercent: Int
    public let nextResetLabel: String

    /// Creates display data from domain entity
    public init(from entity: APIKeyRateLimitEntity) {
        self.requestsRemaining = "\(Self.formatRequests(entity.requestsRemaining))/\(Self.formatRequests(entity.requestsLimit))"
        self.inputTokensRemaining = "\(Self.formatTokenCount(entity.inputTokensRemaining))/\(Self.formatTokenCount(entity.inputTokensLimit))"
        self.outputTokensRemaining = "\(Self.formatTokenCount(entity.outputTokensRemaining))/\(Self.formatTokenCount(entity.outputTokensLimit))"
        self.requestsPercent = Self.clampedPercent(entity.requestsUsagePercent)
        self.inputTokensPercent = Self.clampedPercent(entity.inputTokensUsagePercent)
        self.outputTokensPercent = Self.clampedPercent(entity.outputTokensUsagePercent)
        self.nextResetLabel = Self.formatResetLabel(
            entity.requestsResetTime,
            entity.inputTokensResetTime,
            entity.outputTokensResetTime
        )
    }

    // MARK: - Formatting

    private static func formatTokenCount(_ count: Int) -> String {
        switch count {
        case 1_000_000...:
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        case 1_000...:
            return String(format: "%.0fK", Double(count) / 1_000.0)
        default:
            return "\(count)"
        }
    }

    private static func formatRequests(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    private static func clampedPercent(_ value: Double) -> Int {
        Int(min(100, max(0, value)))
    }

    private static func formatResetLabel(_ dates: Date?...) -> String {
        let earliest = dates.compactMap { $0 }.min()
        guard let reset = earliest else { return "" }

        let seconds = Int(reset.timeIntervalSinceNow)
        guard seconds > 0 else { return "resets now" }

        if seconds < 60 {
            return "resets in \(seconds)s"
        } else {
            let minutes = seconds / 60
            return "resets in \(minutes)m"
        }
    }
}
