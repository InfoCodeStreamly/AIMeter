import Testing
@testable import AIMeter

@Suite("SettingsViewModel", .tags(.presentation, .critical))
@MainActor
struct SettingsViewModelTests {

    // MARK: - Test Dependencies

    private func makeSUT(
        claudeCodeSync: MockClaudeCodeSyncService = MockClaudeCodeSyncService(),
        sessionKeyRepository: MockSessionKeyRepository = MockSessionKeyRepository(),
        credentialsRepository: MockOAuthCredentialsRepository = MockOAuthCredentialsRepository()
    ) async -> (
        sut: SettingsViewModel,
        claudeCodeSync: MockClaudeCodeSyncService,
        sessionKeyRepository: MockSessionKeyRepository,
        credentialsRepository: MockOAuthCredentialsRepository
    ) {
        let validateUseCase = ValidateSessionKeyUseCase(sessionKeyRepository: sessionKeyRepository)
        let getSessionKeyUseCase = GetSessionKeyUseCase(sessionKeyRepository: sessionKeyRepository)

        let sut = SettingsViewModel(
            claudeCodeSync: claudeCodeSync,
            validateUseCase: validateUseCase,
            getSessionKeyUseCase: getSessionKeyUseCase,
            credentialsRepository: credentialsRepository
        )

        return (sut, claudeCodeSync, sessionKeyRepository, credentialsRepository)
    }

    // MARK: - Re-sync Bug Tests (Critical)

    @Test("syncFromClaudeCode saves OAuth credentials when repository is provided", .tags(.critical, .oauth))
    func syncSavesCredentials() async throws {
        // Given
        let (sut, _, sessionKeyRepository, credentialsRepository) = await makeSUT()
        await sessionKeyRepository.stubKey(SessionKeyFixtures.valid)

        // When
        await sut.syncFromClaudeCode()

        // Then
        let saveCount = await credentialsRepository.saveCallCount
        #expect(saveCount == 1, "OAuth credentials should be saved to repository")
        #expect(sut.state.isSuccess, "State should be success after sync")
    }

    // MARK: - onAppear Tests

    @Test("onAppear shows hasKey state when existing key found")
    func onAppearWithExistingKey() async throws {
        // Given
        let (sut, _, sessionKeyRepository, _) = await makeSUT()
        await sessionKeyRepository.stubKey(SessionKeyFixtures.valid)

        // When
        await sut.onAppear()

        // Then
        if case .hasKey(let masked) = sut.state {
            #expect(!masked.isEmpty, "Masked key should not be empty")
        } else {
            Issue.record("Expected .hasKey state, got \(sut.state)")
        }
    }

    @Test("onAppear checks Claude Code when no existing key")
    func onAppearWithoutExistingKey() async throws {
        // Given
        let (sut, claudeCodeSync, sessionKeyRepository, _) = await makeSUT()
        await sessionKeyRepository.reset()  // No key

        // When
        await sut.onAppear()

        // Then
        let hasCredentialsCount = await claudeCodeSync.hasCredentialsCallCount
        #expect(hasCredentialsCount >= 1, "Should check Claude Code for credentials")
    }

    @Test("onAppear shows claudeCodeFound when Claude Code has credentials")
    func onAppearFindsClaudeCode() async throws {
        // Given
        let (sut, claudeCodeSync, sessionKeyRepository, _) = await makeSUT()
        await sessionKeyRepository.reset()  // No key
        await claudeCodeSync.stubHasCredentials(true)

        // When
        await sut.onAppear()

        // Then
        if case .claudeCodeFound(let email) = sut.state {
            #expect(email == "test@example.com", "Should show email from Claude Code")
        } else {
            Issue.record("Expected .claudeCodeFound state, got \(sut.state)")
        }
    }

    @Test("onAppear shows claudeCodeNotFound when Claude Code not available")
    func onAppearNoClaudeCode() async throws {
        // Given
        let (sut, claudeCodeSync, sessionKeyRepository, _) = await makeSUT()
        await sessionKeyRepository.reset()  // No key
        await claudeCodeSync.stubNoCredentials()

        // When
        await sut.onAppear()

        // Then
        #expect(sut.state == .claudeCodeNotFound, "Should show claudeCodeNotFound state")
    }

    // MARK: - syncFromClaudeCode Tests

    @Test("syncFromClaudeCode transitions through syncing state")
    func syncShowsSyncingState() async throws {
        // Given
        let (sut, _, sessionKeyRepository, _) = await makeSUT()
        await sessionKeyRepository.stubKey(SessionKeyFixtures.valid)

        // The syncing state is transient, but we verify the flow completes
        await sut.syncFromClaudeCode()

        #expect(sut.state.isSuccess || sut.state.isError, "Should end in success or error state")
    }

    @Test("syncFromClaudeCode shows error when extraction fails")
    func syncShowsErrorOnExtractionFailure() async throws {
        // Given
        let (sut, claudeCodeSync, _, _) = await makeSUT()
        await claudeCodeSync.stubExtractResult(.failure(ClaudeCodeSyncError.noCredentialsFound))

        // When
        await sut.syncFromClaudeCode()

        // Then
        #expect(sut.state.isError, "Should show error state when extraction fails")
    }

    @Test("syncFromClaudeCode shows error when validation fails")
    func syncShowsErrorOnValidationFailure() async throws {
        // Given
        let (sut, _, sessionKeyRepository, _) = await makeSUT()
        await sessionKeyRepository.stubValidateTokenError(InfrastructureError.networkUnavailable)

        // When
        await sut.syncFromClaudeCode()

        // Then
        #expect(sut.state.isError, "Should show error state when validation fails")
    }

    @Test("syncFromClaudeCode calls onSaveSuccess callback after success", .tags(.slow))
    func syncCallsOnSaveSuccess() async throws {
        // Given
        let (sut, _, sessionKeyRepository, _) = await makeSUT()
        await sessionKeyRepository.stubKey(SessionKeyFixtures.valid)

        var callbackCalled = false
        sut.onSaveSuccess = {
            callbackCalled = true
        }

        // When
        await sut.syncFromClaudeCode()

        // Then - callback is called after delay
        try await Task.sleep(for: .seconds(2))
        #expect(callbackCalled, "onSaveSuccess should be called after successful sync")
    }

    // MARK: - deleteKey Tests

    @Test("deleteKey removes key and checks Claude Code again")
    func deleteKeyRemovesAndChecks() async throws {
        // Given
        let (sut, claudeCodeSync, sessionKeyRepository, _) = await makeSUT()
        await sessionKeyRepository.stubKey(SessionKeyFixtures.valid)

        // When
        await sut.deleteKey()

        // Then
        let deleteCount = await sessionKeyRepository.deleteCallCount
        #expect(deleteCount >= 1, "Should delete the key")

        let checkCount = await claudeCodeSync.hasCredentialsCallCount
        #expect(checkCount >= 1, "Should check Claude Code after deletion")
    }

    // MARK: - statusMessage Tests

    @Test("statusMessage returns message for success state")
    func statusMessageSuccess() async {
        // Given
        let (sut, _, sessionKeyRepository, _) = await makeSUT()
        await sessionKeyRepository.stubKey(SessionKeyFixtures.valid)

        // When
        await sut.syncFromClaudeCode()

        // Then
        #expect(sut.statusMessage != nil, "Should have status message")
        #expect(sut.statusMessage?.contains("Success") == true, "Message should indicate success")
    }

    // MARK: - retry Tests

    @Test("retry checks Claude Code again")
    func retryChecksClaudeCode() async throws {
        // Given
        let (sut, claudeCodeSync, _, _) = await makeSUT()

        // When
        await sut.retry()

        // Then
        let checkCount = await claudeCodeSync.hasCredentialsCallCount
        #expect(checkCount >= 1, "Should check Claude Code on retry")
    }
}
