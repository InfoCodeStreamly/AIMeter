import Foundation

/// Implementation of UsageRepository using Claude OAuth API
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

    func fetchUsage() async throws -> [UsageEntity] {
        // Get OAuth token from keychain
        guard let token = await keychainService.read(forKey: sessionKeyKey) else {
            throw DomainError.sessionKeyNotFound
        }

        // Fetch from OAuth API
        let response = try await apiClient.fetchUsage(token: token)

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
