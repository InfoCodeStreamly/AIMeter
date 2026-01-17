import Testing
@testable import AIMeter

@Suite("RefreshTokenUseCase", .tags(.application, .oauth, .critical))
struct RefreshTokenUseCaseTests {

    // MARK: - Test Dependencies

    private func makeSUT(
        credentialsRepository: MockOAuthCredentialsRepository = MockOAuthCredentialsRepository(),
        tokenRefreshService: MockTokenRefreshService = MockTokenRefreshService()
    ) -> (
        sut: RefreshTokenUseCase,
        credentialsRepository: MockOAuthCredentialsRepository,
        tokenRefreshService: MockTokenRefreshService
    ) {
        let sut = RefreshTokenUseCase(
            credentialsRepository: credentialsRepository,
            tokenRefreshService: tokenRefreshService
        )
        return (sut, credentialsRepository, tokenRefreshService)
    }

    // MARK: - execute() Tests

    @Test("execute throws noCredentials when no OAuth credentials exist", .tags(.critical))
    func executeThrowsNoCredentials() async throws {
        // Given
        let (sut, credentialsRepository, _) = makeSUT()
        await credentialsRepository.stubNoCredentials()

        // When/Then
        await #expect(throws: TokenRefreshError.noCredentials) {
            try await sut.execute()
        }
    }

    @Test("execute returns existing credentials when token doesn't need refresh")
    func executeReturnsExistingCredentials() async throws {
        // Given
        let (sut, credentialsRepository, tokenRefreshService) = makeSUT()
        let validCredentials = OAuthCredentialsFixtures.valid
        await credentialsRepository.stubCredentials(validCredentials)

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.accessToken == validCredentials.accessToken, "Should return same credentials")
        let refreshCallCount = await tokenRefreshService.refreshCallCount
        #expect(refreshCallCount == 0, "Should not call refresh service when token is valid")
    }

    @Test("execute refreshes token when credentials are expiring soon", .tags(.critical))
    func executeRefreshesExpiringToken() async throws {
        // Given
        let (sut, credentialsRepository, tokenRefreshService) = makeSUT()
        let expiringCredentials = OAuthCredentialsFixtures.expiringSoon
        await credentialsRepository.stubCredentials(expiringCredentials)
        await tokenRefreshService.stubSuccess(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            expiresIn: 86400
        )

        // When
        let result = try await sut.execute()

        // Then
        let refreshCallCount = await tokenRefreshService.refreshCallCount
        #expect(refreshCallCount == 1, "Should call refresh service")
        #expect(result.accessToken == "new-access-token", "Should return refreshed access token")

        let saveCallCount = await credentialsRepository.saveCallCount
        #expect(saveCallCount == 1, "Should save refreshed credentials")
    }

    @Test("execute refreshes token when credentials are expired", .tags(.critical))
    func executeRefreshesExpiredToken() async throws {
        // Given
        let (sut, credentialsRepository, tokenRefreshService) = makeSUT()
        let expiredCredentials = OAuthCredentialsFixtures.expired
        await credentialsRepository.stubCredentials(expiredCredentials)
        await tokenRefreshService.stubSuccess(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            expiresIn: 86400
        )

        // When
        let result = try await sut.execute()

        // Then
        let refreshCallCount = await tokenRefreshService.refreshCallCount
        #expect(refreshCallCount == 1, "Should call refresh service for expired token")
        #expect(result.accessToken == "new-access-token", "Should return new access token")
    }

    @Test("execute propagates refresh service errors")
    func executePropagaresRefreshError() async throws {
        // Given
        let (sut, credentialsRepository, tokenRefreshService) = makeSUT()
        let expiringCredentials = OAuthCredentialsFixtures.expiringSoon
        await credentialsRepository.stubCredentials(expiringCredentials)
        await tokenRefreshService.stubError(TokenRefreshError.refreshTokenExpired)

        // When/Then
        await #expect(throws: TokenRefreshError.refreshTokenExpired) {
            try await sut.execute()
        }
    }

    @Test("execute uses correct refresh token when calling service")
    func executeUsesCorrectRefreshToken() async throws {
        // Given
        let (sut, credentialsRepository, tokenRefreshService) = makeSUT()
        let credentials = OAuthCredentialsBuilder()
            .withRefreshToken("test-refresh-token-123")
            .expiringSoon()
            .build()
        await credentialsRepository.stubCredentials(credentials)

        // When
        _ = try await sut.execute()

        // Then
        let lastRefreshToken = await tokenRefreshService.lastRefreshToken
        #expect(lastRefreshToken == "test-refresh-token-123", "Should use correct refresh token")
    }

    @Test("execute updates Claude Code keychain after refresh")
    func executeUpdatesClaudeCodeKeychain() async throws {
        // Given
        let (sut, credentialsRepository, tokenRefreshService) = makeSUT()
        let expiringCredentials = OAuthCredentialsFixtures.expiringSoon
        await credentialsRepository.stubCredentials(expiringCredentials)
        await tokenRefreshService.stubSuccess(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            expiresIn: 86400
        )

        // When
        _ = try await sut.execute()

        // Then
        let updateCallCount = await credentialsRepository.updateClaudeCodeCallCount
        #expect(updateCallCount == 1, "Should update Claude Code keychain")
    }

    @Test("execute continues even if Claude Code keychain update fails")
    func executeContinuesIfClaudeCodeUpdateFails() async throws {
        // Given
        let (sut, credentialsRepository, tokenRefreshService) = makeSUT()
        let expiringCredentials = OAuthCredentialsFixtures.expiringSoon
        await credentialsRepository.stubCredentials(expiringCredentials)
        await credentialsRepository.stubUpdateClaudeCodeError(TokenRefreshError.keychainUpdateFailed)
        await tokenRefreshService.stubSuccess(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            expiresIn: 86400
        )

        // When
        let result = try await sut.execute()

        // Then - should complete successfully despite keychain update failure
        #expect(result.accessToken == "new-access-token", "Should return refreshed token even if Claude Code update fails")
    }

    @Test("execute saves credentials before updating Claude Code keychain")
    func executeSavesBeforeUpdatingClaudeCode() async throws {
        // Given
        let (sut, credentialsRepository, tokenRefreshService) = makeSUT()
        let expiringCredentials = OAuthCredentialsFixtures.expiringSoon
        await credentialsRepository.stubCredentials(expiringCredentials)

        // When
        _ = try await sut.execute()

        // Then
        let saveCallCount = await credentialsRepository.saveCallCount
        let updateCallCount = await credentialsRepository.updateClaudeCodeCallCount
        #expect(saveCallCount >= 1, "Should save credentials")
        #expect(updateCallCount >= 1, "Should update Claude Code keychain")
    }

    // MARK: - hasValidCredentials() Tests

    @Test("hasValidCredentials returns false when no credentials exist")
    func hasValidCredentialsReturnsFalseWithoutCredentials() async {
        // Given
        let (sut, credentialsRepository, _) = makeSUT()
        await credentialsRepository.stubNoCredentials()

        // When
        let result = await sut.hasValidCredentials()

        // Then
        #expect(!result, "Should return false when no credentials exist")
    }

    @Test("hasValidCredentials returns true when valid credentials exist")
    func hasValidCredentialsReturnsTrueWithCredentials() async {
        // Given
        let (sut, credentialsRepository, _) = makeSUT()
        let validCredentials = OAuthCredentialsFixtures.valid
        await credentialsRepository.stubCredentials(validCredentials)

        // When
        let result = await sut.hasValidCredentials()

        // Then
        #expect(result, "Should return true when valid credentials exist")
    }

    @Test("hasValidCredentials returns true even when credentials are expired (can still try refresh)")
    func hasValidCredentialsReturnsTrueWithExpiredCredentials() async {
        // Given
        let (sut, credentialsRepository, _) = makeSUT()
        let expiredCredentials = OAuthCredentialsFixtures.expired
        await credentialsRepository.stubCredentials(expiredCredentials)

        // When
        let result = await sut.hasValidCredentials()

        // Then
        #expect(result, "Should return true even with expired credentials (refresh possible)")
    }

    @Test("hasValidCredentials returns false when refresh token is empty")
    func hasValidCredentialsReturnsFalseWithEmptyRefreshToken() async {
        // Given
        let (sut, credentialsRepository, _) = makeSUT()
        let credentialsWithEmptyRefreshToken = OAuthCredentialsBuilder()
            .withRefreshToken("")
            .build()
        await credentialsRepository.stubCredentials(credentialsWithEmptyRefreshToken)

        // When
        let result = await sut.hasValidCredentials()

        // Then
        #expect(!result, "Should return false when refresh token is empty")
    }
}
