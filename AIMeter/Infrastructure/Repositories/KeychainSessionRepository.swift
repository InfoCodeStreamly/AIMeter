import Foundation

/// Implementation of SessionKeyRepository using Keychain
actor KeychainSessionRepository: SessionKeyRepository {
    private let keychainService: KeychainService
    private let apiClient: ClaudeAPIClient

    private let sessionKeyKey = "sessionKey"
    private let organizationIdKey = "organizationId"

    private var cachedOrganizationId: OrganizationId?

    init(
        keychainService: KeychainService,
        apiClient: ClaudeAPIClient
    ) {
        self.keychainService = keychainService
        self.apiClient = apiClient
    }

    func save(_ key: SessionKey) async throws {
        try await keychainService.save(key.value, forKey: sessionKeyKey)
    }

    func get() async -> SessionKey? {
        guard let value = await keychainService.read(forKey: sessionKeyKey) else {
            return nil
        }
        return try? SessionKey.create(value)
    }

    func delete() async {
        try? await keychainService.delete(forKey: sessionKeyKey)
        try? await keychainService.delete(forKey: organizationIdKey)
        cachedOrganizationId = nil
    }

    func exists() async -> Bool {
        await keychainService.exists(forKey: sessionKeyKey)
    }

    func fetchOrganizationId(using key: SessionKey) async throws -> OrganizationId? {
        // For OAuth tokens, validate by fetching usage (no org ID needed)
        if APIEndpoints.isOAuthToken(key.value) {
            _ = try await apiClient.validateKey(key.value)
            return nil // OAuth doesn't use org ID
        }

        // For session keys, fetch organization
        let response = try await apiClient.fetchOrganizations(sessionKey: key.value)
        return try APIUsageMapper.toOrganizationId(response)
    }

    func getCachedOrganizationId() async -> OrganizationId? {
        // Try memory cache first
        if let cached = cachedOrganizationId {
            return cached
        }

        // Try keychain
        guard let value = await keychainService.read(forKey: organizationIdKey) else {
            return nil
        }

        guard let orgId = try? OrganizationId.create(value) else {
            return nil
        }

        // Update memory cache
        cachedOrganizationId = orgId
        return orgId
    }

    func cacheOrganizationId(_ id: OrganizationId) async {
        // Save to keychain
        try? await keychainService.save(id.value, forKey: organizationIdKey)
        // Update memory cache
        cachedOrganizationId = id
    }
}
