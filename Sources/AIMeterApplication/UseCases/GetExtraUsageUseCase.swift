import Foundation
import AIMeterDomain

/// Use case for getting cached extra usage (pay-as-you-go) data
public final class GetExtraUsageUseCase: Sendable {
    private let usageRepository: any UsageRepository

    public init(usageRepository: any UsageRepository) {
        self.usageRepository = usageRepository
    }

    /// Executes the use case
    /// - Returns: Extra usage entity if available and enabled
    public func execute() async -> ExtraUsageEntity? {
        await usageRepository.getExtraUsage()
    }
}
