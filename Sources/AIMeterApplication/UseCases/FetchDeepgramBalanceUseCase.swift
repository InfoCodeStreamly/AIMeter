import Foundation
import AIMeterDomain

/// Use case for fetching Deepgram account balance
public final class FetchDeepgramBalanceUseCase: Sendable {
    private let deepgramAPIRepository: any DeepgramAPIRepository

    public init(deepgramAPIRepository: any DeepgramAPIRepository) {
        self.deepgramAPIRepository = deepgramAPIRepository
    }

    /// Fetches the current account balance
    /// - Parameter apiKey: Deepgram API key
    /// - Returns: Account balance information
    public func execute(apiKey: String) async throws -> DeepgramBalance {
        try await deepgramAPIRepository.fetchBalance(apiKey: apiKey)
    }
}
