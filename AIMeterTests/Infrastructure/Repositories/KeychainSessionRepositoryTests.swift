import Testing
import Foundation
@testable import AIMeter

@Suite("KeychainSessionRepository", .tags(.keychain, .critical))
struct KeychainSessionRepositoryTests {

    // MARK: - Test Dependencies

    private func makeSUT(
        keychainService: MockKeychainService = MockKeychainService(),
        apiClient: MockClaudeAPIClient = MockClaudeAPIClient(),
        claudeCodeSync: MockClaudeCodeSyncService = MockClaudeCodeSyncService()
    ) -> (
        sut: KeychainSessionRepository,
        keychain: MockKeychainService,
        api: MockClaudeAPIClient,
        sync: MockClaudeCodeSyncService
    ) {
        let sut = KeychainSessionRepository(
            keychainService: keychainService,
            apiClient: apiClient,
            claudeCodeSyncService: claudeCodeSync
        )
        return (sut, keychainService, apiClient, claudeCodeSync)
    }

    // MARK: - save Tests

    @Test("save stores session key in keychain")
    func saveStoresSessionKey() async throws {
        // Given
        let (sut, keychain, _, _) = makeSUT()
        let sessionKey = SessionKeyFixtures.valid

        // When
        try await sut.save(sessionKey)

        // Then
        let saveCount = await keychain.saveCallCount
        #expect(saveCount == 1, "Should save to keychain once")
    }

    @Test("save stores correct value")
    func saveStoresCorrectValue() async throws {
        // Given
        let (sut, keychain, _, _) = makeSUT()
        let sessionKey = SessionKeyFixtures.valid

        // When
        try await sut.save(sessionKey)

        // Then
        let stored = await keychain.read(forKey: "sessionKey")
        #expect(stored == sessionKey.value, "Stored value should match session key")
    }

    // MARK: - get Tests

    @Test("get returns nil when keychain is empty")
    func getReturnsNilWhenEmpty() async {
        // Given
        let (sut, _, _, _) = makeSUT()

        // When
        let result = await sut.get()

        // Then
        #expect(result == nil, "Should return nil when no key stored")
    }

    @Test("get returns session key when stored")
    func getReturnsStoredKey() async throws {
        // Given
        let keychain = MockKeychainService()
        await keychain.preload(["sessionKey": SessionKeyFixtures.validRawKey])
        let (sut, _, _, _) = makeSUT(keychainService: keychain)

        // When
        let result = await sut.get()

        // Then
        #expect(result != nil, "Should return session key")
        #expect(result?.value == SessionKeyFixtures.validRawKey, "Value should match")
    }

    @Test("get returns nil for invalid stored value")
    func getReturnsNilForInvalidValue() async throws {
        // Given
        let keychain = MockKeychainService()
        await keychain.preload(["sessionKey": "invalid-key"])
        let (sut, _, _, _) = makeSUT(keychainService: keychain)

        // When
        let result = await sut.get()

        // Then
        #expect(result == nil, "Should return nil for invalid key format")
    }

    // MARK: - delete Tests

    @Test("delete removes all stored data")
    func deleteRemovesAllData() async throws {
        // Given
        let keychain = MockKeychainService()
        await keychain.preload([
            "sessionKey": SessionKeyFixtures.validRawKey,
            "oauthCredentials": "{}"
        ])
        let (sut, _, _, _) = makeSUT(keychainService: keychain)

        // When
        await sut.delete()

        // Then
        let sessionKeyExists = await keychain.exists(forKey: "sessionKey")
        let credentialsExists = await keychain.exists(forKey: "oauthCredentials")

        #expect(!sessionKeyExists, "Session key should be deleted")
        #expect(!credentialsExists, "OAuth credentials should be deleted")
    }

    @Test("delete clears cached values")
    func deleteClearsCachedValues() async throws {
        // Given
        let (sut, _, _, _) = makeSUT()

        // Pre-populate cache by saving
        let credentials = OAuthCredentialsFixtures.valid
        try await sut.saveOAuthCredentials(credentials)

        // When
        await sut.delete()

        // Then
        let cachedCredentials = await sut.getOAuthCredentials()
        #expect(cachedCredentials == nil, "Cached credentials should be cleared")
    }

    // MARK: - exists Tests

    @Test("exists returns false when keychain is empty")
    func existsReturnsFalseWhenEmpty() async {
        // Given
        let (sut, _, _, _) = makeSUT()

        // When
        let result = await sut.exists()

        // Then
        #expect(!result, "Should return false when no key stored")
    }

    @Test("exists returns true when key is stored")
    func existsReturnsTrueWhenStored() async throws {
        // Given
        let keychain = MockKeychainService()
        await keychain.preload(["sessionKey": SessionKeyFixtures.validRawKey])
        let (sut, _, _, _) = makeSUT(keychainService: keychain)

        // When
        let result = await sut.exists()

        // Then
        #expect(result, "Should return true when key is stored")
    }

    // MARK: - validateToken Tests

    @Test("validateToken calls API client")
    func validateTokenCallsAPIClient() async throws {
        // Given
        let (sut, _, api, _) = makeSUT()
        let token = SessionKeyFixtures.validOAuthToken

        // When
        try await sut.validateToken(token)

        // Then
        let validateCount = await api.validateTokenCallCount
        #expect(validateCount == 1, "Should call validateToken on API client")
    }

    @Test("validateToken throws on validation failure")
    func validateTokenThrowsOnFailure() async throws {
        // Given
        let (sut, _, api, _) = makeSUT()
        await api.stubValidateTokenError(InfrastructureError.unauthorized)
        let token = SessionKeyFixtures.validOAuthToken

        // When/Then
        await #expect(throws: InfrastructureError.self) {
            try await sut.validateToken(token)
        }
    }

    // MARK: - getOAuthCredentials Tests

    @Test("getOAuthCredentials returns nil when nothing stored")
    func getOAuthCredentialsReturnsNilWhenEmpty() async {
        // Given
        let (sut, _, _, _) = makeSUT()

        // When
        let result = await sut.getOAuthCredentials()

        // Then
        #expect(result == nil, "Should return nil when nothing stored")
    }

    @Test("getOAuthCredentials returns cached credentials from memory")
    func getOAuthCredentialsReturnsMemoryCached() async throws {
        // Given
        let (sut, _, _, _) = makeSUT()
        let credentials = OAuthCredentialsFixtures.valid

        // Save to populate cache
        try await sut.saveOAuthCredentials(credentials)

        // When
        let result = await sut.getOAuthCredentials()

        // Then
        #expect(result?.accessToken == credentials.accessToken, "Should return cached credentials")
    }

    @Test("getOAuthCredentials loads from keychain when not in memory")
    func getOAuthCredentialsLoadsFromKeychain() async throws {
        // Given
        let keychain = MockKeychainService()
        let credentials = OAuthCredentialsFixtures.valid
        let data = try JSONEncoder().encode(credentials)
        let jsonString = String(data: data, encoding: .utf8)!
        await keychain.preload(["oauthCredentials": jsonString])

        let (sut, _, _, _) = makeSUT(keychainService: keychain)

        // When
        let result = await sut.getOAuthCredentials()

        // Then
        #expect(result?.accessToken == credentials.accessToken, "Should load from keychain")
    }

    // MARK: - saveOAuthCredentials Tests

    @Test("saveOAuthCredentials saves to keychain")
    func saveOAuthCredentialsSavesToKeychain() async throws {
        // Given
        let (sut, keychain, _, _) = makeSUT()
        let credentials = OAuthCredentialsFixtures.valid

        // When
        try await sut.saveOAuthCredentials(credentials)

        // Then
        let saveCount = await keychain.saveCallCount
        #expect(saveCount >= 1, "Should save to keychain")
    }

    @Test("saveOAuthCredentials also updates session key")
    func saveOAuthCredentialsUpdatesSessionKey() async throws {
        // Given
        let (sut, keychain, _, _) = makeSUT()
        let credentials = OAuthCredentialsFixtures.valid

        // When
        try await sut.saveOAuthCredentials(credentials)

        // Then
        let storedSessionKey = await keychain.read(forKey: "sessionKey")
        #expect(storedSessionKey == credentials.accessToken, "Session key should match access token")
    }

    @Test("saveOAuthCredentials updates memory cache")
    func saveOAuthCredentialsUpdatesCache() async throws {
        // Given
        let (sut, _, _, _) = makeSUT()
        let credentials = OAuthCredentialsFixtures.valid

        // When
        try await sut.saveOAuthCredentials(credentials)

        // Then
        let cached = await sut.getOAuthCredentials()
        #expect(cached?.accessToken == credentials.accessToken, "Cache should be updated")
    }

    // MARK: - updateClaudeCodeKeychain Tests

    @Test("updateClaudeCodeKeychain calls sync service")
    func updateClaudeCodeKeychainCallsSyncService() async throws {
        // Given
        let (sut, _, _, sync) = makeSUT()
        let credentials = OAuthCredentialsFixtures.valid

        // When
        try await sut.updateClaudeCodeKeychain(credentials)

        // Then
        let updateCount = await sync.updateCredentialsCallCount
        #expect(updateCount == 1, "Should call sync service")
    }

    @Test("updateClaudeCodeKeychain propagates errors")
    func updateClaudeCodeKeychainPropagatesErrors() async throws {
        // Given
        let sync = MockClaudeCodeSyncService()
        await sync.stubUpdateCredentialsError(ClaudeCodeSyncError.noCredentialsFound)
        let (sut, _, _, _) = makeSUT(claudeCodeSync: sync)
        let credentials = OAuthCredentialsFixtures.valid

        // When/Then
        await #expect(throws: ClaudeCodeSyncError.self) {
            try await sut.updateClaudeCodeKeychain(credentials)
        }
    }
}
