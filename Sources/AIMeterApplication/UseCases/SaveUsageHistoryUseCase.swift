import Foundation
import AIMeterDomain

/// Use case for saving usage history entry
public final class SaveUsageHistoryUseCase: Sendable {
    private let historyRepository: any UsageHistoryRepository

    public init(historyRepository: any UsageHistoryRepository) {
        self.historyRepository = historyRepository
    }

    /// Saves current usage as history entry
    public func execute(usages: [UsageEntity]) async {
        guard let entry = UsageHistoryEntry.from(usages: usages) else { return }
        await historyRepository.save(entry)
    }
}
