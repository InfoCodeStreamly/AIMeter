import Foundation

/// Deepgram usage statistics for the current billing period
public struct DeepgramUsageStats: Sendable, Equatable {
    public let totalSeconds: Double
    public let requestCount: Int
    public let balance: DeepgramBalance
    public let periodStart: Date

    public init(totalSeconds: Double, requestCount: Int, balance: DeepgramBalance, periodStart: Date) {
        self.totalSeconds = totalSeconds
        self.requestCount = requestCount
        self.balance = balance
        self.periodStart = periodStart
    }

    /// "36.5 sec" or "2.1 min" or "1.5 hrs"
    public var formattedDuration: String {
        if totalSeconds < 60 {
            return String(format: "%.1f sec", totalSeconds)
        } else if totalSeconds < 3600 {
            return String(format: "%.1f min", totalSeconds / 60)
        } else {
            return String(format: "%.1f hrs", totalSeconds / 3600)
        }
    }
}
