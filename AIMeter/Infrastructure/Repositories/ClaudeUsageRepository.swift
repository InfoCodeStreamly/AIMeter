import Foundation

/// Implementation of UsageRepository using Claude API
actor ClaudeUsageRepository: UsageRepository {
    private let apiClient: ClaudeAPIClient
    private let keychainService: KeychainService
    private var cachedEntities: [UsageEntity] = []

    private let sessionKeyKey = "sessionKey"

    init(
        apiClient: ClaudeAPIClient,
        keychainService: KeychainService
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
    }

    func fetchUsage(organizationId: OrganizationId?) async throws -> [UsageEntity] {
        // Get session key from keychain
        guard let sessionKey = await keychainService.read(forKey: sessionKeyKey) else {
            throw DomainError.sessionKeyNotFound
        }

        // Fetch from API (organizationId is nil for OAuth tokens)
        let response = try await apiClient.fetchUsage(
            organizationId: organizationId?.value,
            sessionKey: sessionKey
        )

        // Map to domain entities
        let entities = APIUsageMapper.toDomain(response)

        // Cache results
        cachedEntities = entities

        return entities
    }

    func getCachedUsage() async -> [UsageEntity] {
        cachedEntities
    }

    func cacheUsage(_ entities: [UsageEntity]) async {
        cachedEntities = entities
    }
}
