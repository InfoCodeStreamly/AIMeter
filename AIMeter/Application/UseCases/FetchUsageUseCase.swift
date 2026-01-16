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
        // Get session key
        guard let sessionKey = await sessionKeyRepository.get() else {
            throw DomainError.sessionKeyNotFound
        }

        // Get organization ID (cached or fetch)
        // For OAuth tokens, org ID is nil
        var organizationId: OrganizationId? = await sessionKeyRepository.getCachedOrganizationId()

        if organizationId == nil {
            // Try to fetch - will return nil for OAuth tokens
            organizationId = try await sessionKeyRepository.fetchOrganizationId(using: sessionKey)
            if let orgId = organizationId {
                await sessionKeyRepository.cacheOrganizationId(orgId)
            }
        }

        // Fetch usage data (organizationId can be nil for OAuth)
        let entities = try await usageRepository.fetchUsage(organizationId: organizationId)

        // Cache results
        await usageRepository.cacheUsage(entities)

        return entities
    }
}
