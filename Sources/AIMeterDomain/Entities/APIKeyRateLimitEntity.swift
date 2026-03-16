import Foundation

/// Rate limit status from Anthropic API response headers
public struct APIKeyRateLimitEntity: Sendable, Equatable {
    public let requestsLimit: Int
    public let requestsRemaining: Int
    public let requestsResetTime: Date?

    public let inputTokensLimit: Int
    public let inputTokensRemaining: Int
    public let inputTokensResetTime: Date?

    public let outputTokensLimit: Int
    public let outputTokensRemaining: Int
    public let outputTokensResetTime: Date?

    public nonisolated init(
        requestsLimit: Int,
        requestsRemaining: Int,
        requestsResetTime: Date? = nil,
        inputTokensLimit: Int,
        inputTokensRemaining: Int,
        inputTokensResetTime: Date? = nil,
        outputTokensLimit: Int,
        outputTokensRemaining: Int,
        outputTokensResetTime: Date? = nil
    ) {
        self.requestsLimit = requestsLimit
        self.requestsRemaining = requestsRemaining
        self.requestsResetTime = requestsResetTime
        self.inputTokensLimit = inputTokensLimit
        self.inputTokensRemaining = inputTokensRemaining
        self.inputTokensResetTime = inputTokensResetTime
        self.outputTokensLimit = outputTokensLimit
        self.outputTokensRemaining = outputTokensRemaining
        self.outputTokensResetTime = outputTokensResetTime
    }

    /// Requests usage percentage (0-100)
    public var requestsUsagePercent: Double {
        guard requestsLimit > 0 else { return 0 }
        return Double(requestsLimit - requestsRemaining) / Double(requestsLimit) * 100.0
    }

    /// Input tokens usage percentage (0-100)
    public var inputTokensUsagePercent: Double {
        guard inputTokensLimit > 0 else { return 0 }
        return Double(inputTokensLimit - inputTokensRemaining) / Double(inputTokensLimit) * 100.0
    }

    /// Output tokens usage percentage (0-100)
    public var outputTokensUsagePercent: Double {
        guard outputTokensLimit > 0 else { return 0 }
        return Double(outputTokensLimit - outputTokensRemaining) / Double(outputTokensLimit) * 100.0
    }
}
