import Foundation

/// Repository protocol for Deepgram REST API operations
public protocol DeepgramAPIRepository: Sendable {
    /// Fetches the account balance for the given API key
    func fetchBalance(apiKey: String) async throws -> DeepgramBalance

    /// Fetches usage statistics for the given date range
    func fetchUsage(apiKey: String, start: Date, end: Date) async throws -> (totalSeconds: Double, requestCount: Int)
}
