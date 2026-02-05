import Foundation
import AIMeterDomain

/// Implementation of UsageRepository using Claude OAuth API
public actor ClaudeUsageRepository: UsageRepository {
    private let apiClient: any ClaudeAPIClientProtocol
    private let keychainService: any KeychainServiceProtocol
    private var cachedEntities: [UsageEntity] = []
    private var cachedExtraUsage: ExtraUsageEntity?

    private let sessionKeyKey = "sessionKey"

    public init(
        apiClient: any ClaudeAPIClientProtocol,
        keychainService: any KeychainServiceProtocol
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
    }

    public func fetchUsage() async throws -> [UsageEntity] {
        guard let token = await keychainService.read(forKey: sessionKeyKey) else {
            throw DomainError.sessionKeyNotFound
        }

        let response = try await apiClient.fetchUsage(token: token)
        let entities = APIUsageMapper.toDomain(response)
        cachedEntities = entities

        // Also cache extra usage if available
        cachedExtraUsage = APIUsageMapper.toExtraUsageEntity(response.extraUsage)

        return entities
    }

    /// Returns cached extra usage (pay-as-you-go) data
    public func getExtraUsage() async -> ExtraUsageEntity? {
        cachedExtraUsage
    }

    public func getCachedUsage() async -> [UsageEntity] {
        cachedEntities
    }

    public func cacheUsage(_ entities: [UsageEntity]) async {
        cachedEntities = entities
    }
}
