import AIMeterDomain
import Foundation

/// Fetches combined Deepgram stats: usage (current month) + balance
public final class FetchDeepgramUsageUseCase: Sendable {
    private let deepgramAPIRepository: any DeepgramAPIRepository

    public init(deepgramAPIRepository: any DeepgramAPIRepository) {
        self.deepgramAPIRepository = deepgramAPIRepository
    }

    public func execute(apiKey: String) async throws -> DeepgramUsageStats {
        let now = Date()
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        async let usageResult = deepgramAPIRepository.fetchUsage(apiKey: apiKey, start: start, end: now)
        async let balanceResult = deepgramAPIRepository.fetchBalance(apiKey: apiKey)

        let usage = try await usageResult
        let balance = try await balanceResult

        return DeepgramUsageStats(
            totalSeconds: usage.totalSeconds,
            requestCount: usage.requestCount,
            balance: balance,
            periodStart: start
        )
    }
}
