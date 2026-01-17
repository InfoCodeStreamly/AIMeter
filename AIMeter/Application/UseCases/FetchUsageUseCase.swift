import Foundation

/// Use case for fetching current usage data
final class FetchUsageUseCase: Sendable {
    private let usageRepository: any UsageRepository
    private let sessionKeyRepository: any SessionKeyRepository

    init(
        usageRepository: any UsageRepository,
        sessionKeyRepository: any SessionKeyRepository
    ) {
        self.usageRepository = usageRepository
        self.sessionKeyRepository = sessionKeyRepository
    }

    /// Executes the use case
    /// - Returns: Array of usage entities
    /// - Throws: Domain errors if session key missing or API fails
    func execute() async throws -> [UsageEntity] {
        // Verify session key exists
        guard await sessionKeyRepository.exists() else {
            throw DomainError.sessionKeyNotFound
        }

        // Fetch usage data
        let entities = try await usageRepository.fetchUsage()

        // Cache results
        await usageRepository.cacheUsage(entities)

        return entities
    }
}
