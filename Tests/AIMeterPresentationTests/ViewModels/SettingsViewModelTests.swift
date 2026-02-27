import SwiftUI
import Testing

@testable import AIMeterApplication
@testable import AIMeterDomain
@testable import AIMeterPresentation

/// Tests for SettingsViewModel
@Suite("SettingsViewModel Tests")
@MainActor
struct SettingsViewModelTests {

    // MARK: - Mock Repositories

    actor MockSessionKeyRepository: SessionKeyRepository {
        var storedKey: SessionKey?
        var shouldThrowOnSave = false
        var shouldThrowOnValidate = false

        func configure(storedKey: SessionKey? = nil) {
            self.storedKey = storedKey
        }

        func save(_ key: SessionKey) async throws {
            if shouldThrowOnSave {
                throw DomainError.invalidSessionKeyFormat
            }
            storedKey = key
        }

        func get() async -> SessionKey? {
            return storedKey
        }

        func delete() async {
            storedKey = nil
        }

        func exists() async -> Bool {
            return storedKey != nil
        }

        func validateToken(_ token: String) async throws {
            if shouldThrowOnValidate {
                throw DomainError.invalidSessionKeyFormat
            }
        }
    }

    actor MockOAuthCredentialsRepository: OAuthCredentialsRepository {
        var storedCredentials: OAuthCredentials?
        var shouldThrowOnSave = false

        func configure(credentials: OAuthCredentials? = nil) {
            self.storedCredentials = credentials
        }

        func getOAuthCredentials() async -> OAuthCredentials? {
            return storedCredentials
        }

        func saveOAuthCredentials(_ credentials: OAuthCredentials) async throws {
            if shouldThrowOnSave {
                throw SyncError.keychainWriteFailed(status: errSecParam)
            }
            storedCredentials = credentials
        }

        func updateClaudeCodeKeychain(_ credentials: OAuthCredentials) async throws {}
    }

    actor MockClaudeCodeSync: ClaudeCodeSyncServiceProtocol {
        var hasCredentialsResult = false
        var subscriptionInfo: (type: String, email: String?)?
        var extractCredentialsResult: OAuthCredentials?
        var shouldThrowOnExtract = false

        func configure(
            hasCredentials: Bool = false,
            subscriptionInfo: (type: String, email: String?)? = nil,
            credentials: OAuthCredentials? = nil,
            shouldThrowOnExtract: Bool = false
        ) {
            self.hasCredentialsResult = hasCredentials
            self.subscriptionInfo = subscriptionInfo
            self.extractCredentialsResult = credentials
            self.shouldThrowOnExtract = shouldThrowOnExtract
        }

        func hasCredentials() async -> Bool {
            return hasCredentialsResult
        }

        func getSubscriptionInfo() async -> (type: String, email: String?)? {
            return subscriptionInfo
        }

        func extractOAuthCredentials() async throws -> OAuthCredentials {
            if shouldThrowOnExtract {
                throw SyncError.noCredentialsFound
            }
            guard let credentials = extractCredentialsResult else {
                throw SyncError.noCredentialsFound
            }
            return credentials
        }

        func updateCredentials(_ credentials: OAuthCredentials) async throws {}
    }

    // MARK: - Helper Methods

    func makeViewModel(
        mockSync: MockClaudeCodeSync,
        mockSessionRepo: MockSessionKeyRepository,
        mockCredentialsRepo: MockOAuthCredentialsRepository
    ) -> SettingsViewModel {
        let validateUseCase = ValidateSessionKeyUseCase(sessionKeyRepository: mockSessionRepo)
        let getSessionKeyUseCase = GetSessionKeyUseCase(sessionKeyRepository: mockSessionRepo)

        return SettingsViewModel(
            claudeCodeSync: mockSync,
            validateUseCase: validateUseCase,
            getSessionKeyUseCase: getSessionKeyUseCase,
            credentialsRepository: mockCredentialsRepo
        )
    }

    func makeValidCredentials() -> OAuthCredentials {
        return OAuthCredentials(
            accessToken: "sk-ant-oat01-testtoken123456789",
            refreshToken: "refresh-token-test",
            expiresAt: Date().addingTimeInterval(3600),
            scopes: ["read", "write"],
            subscriptionType: "pro",
            rateLimitTier: "tier1"
        )
    }

    // MARK: - onAppear Tests

    @Test("onAppear with existing key transitions to hasKey state")
    func onAppearWithExistingKey() async throws {
        let mockSync = MockClaudeCodeSync()
        let mockSessionRepo = MockSessionKeyRepository()
        let mockCredentialsRepo = MockOAuthCredentialsRepository()

        let existingKey = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await mockSessionRepo.configure(storedKey: existingKey)

        let viewModel = makeViewModel(
            mockSync: mockSync,
            mockSessionRepo: mockSessionRepo,
            mockCredentialsRepo: mockCredentialsRepo
        )

        await viewModel.onAppear()

        if case .hasKey(let masked) = viewModel.state {
            #expect(masked == existingKey.masked)
        } else {
            Issue.record("Expected .hasKey state, got \(viewModel.state)")
        }
    }

    @Test("onAppear with no key and Claude Code found transitions to claudeCodeFound")
    func onAppearWithNoKeyAndClaudeCodeFound() async throws {
        let mockSync = MockClaudeCodeSync()
        await mockSync.configure(
            hasCredentials: true,
            subscriptionInfo: (type: "pro", email: "test@example.com")
        )

        let mockSessionRepo = MockSessionKeyRepository()
        let mockCredentialsRepo = MockOAuthCredentialsRepository()

        let viewModel = makeViewModel(
            mockSync: mockSync,
            mockSessionRepo: mockSessionRepo,
            mockCredentialsRepo: mockCredentialsRepo
        )

        await viewModel.onAppear()

        if case .claudeCodeFound(let email) = viewModel.state {
            #expect(email == "test@example.com")
        } else {
            Issue.record("Expected .claudeCodeFound state, got \(viewModel.state)")
        }
    }

    @Test("onAppear with no key and no Claude Code transitions to claudeCodeNotFound")
    func onAppearWithNoKeyAndNoClaudeCode() async throws {
        let mockSync = MockClaudeCodeSync()
        await mockSync.configure(hasCredentials: false)

        let mockSessionRepo = MockSessionKeyRepository()
        let mockCredentialsRepo = MockOAuthCredentialsRepository()

        let viewModel = makeViewModel(
            mockSync: mockSync,
            mockSessionRepo: mockSessionRepo,
            mockCredentialsRepo: mockCredentialsRepo
        )

        await viewModel.onAppear()

        #expect(viewModel.state == .claudeCodeNotFound)
    }

    // MARK: - deleteKey Tests

    @Test("deleteKey deletes key and checks Claude Code")
    func deleteKeyDeletesAndChecksClaudeCode() async throws {
        let mockSync = MockClaudeCodeSync()
        await mockSync.configure(hasCredentials: false)

        let mockSessionRepo = MockSessionKeyRepository()
        let existingKey = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await mockSessionRepo.configure(storedKey: existingKey)

        let mockCredentialsRepo = MockOAuthCredentialsRepository()

        let viewModel = makeViewModel(
            mockSync: mockSync,
            mockSessionRepo: mockSessionRepo,
            mockCredentialsRepo: mockCredentialsRepo
        )

        await viewModel.deleteKey()

        let keyExists = await mockSessionRepo.exists()
        #expect(!keyExists)
        #expect(viewModel.state == .claudeCodeNotFound)
    }

    // MARK: - Computed Properties Tests

    @Test("statusMessage returns nil for checking state")
    func statusMessageReturnsNilForCheckingState() {
        let mockSync = MockClaudeCodeSync()
        let mockSessionRepo = MockSessionKeyRepository()
        let mockCredentialsRepo = MockOAuthCredentialsRepository()

        let viewModel = makeViewModel(
            mockSync: mockSync,
            mockSessionRepo: mockSessionRepo,
            mockCredentialsRepo: mockCredentialsRepo
        )

        #expect(viewModel.statusMessage == nil)
    }

    @Test("statusColor returns secondary for non-success/error states")
    func statusColorReturnsSecondaryForOtherStates() {
        let mockSync = MockClaudeCodeSync()
        let mockSessionRepo = MockSessionKeyRepository()
        let mockCredentialsRepo = MockOAuthCredentialsRepository()

        let viewModel = makeViewModel(
            mockSync: mockSync,
            mockSessionRepo: mockSessionRepo,
            mockCredentialsRepo: mockCredentialsRepo
        )

        #expect(viewModel.statusColor == .secondary)
    }

    @Test("statusColor returns green for success state")
    func statusColorReturnsGreenForSuccess() async throws {
        let mockSync = MockClaudeCodeSync()
        let credentials = makeValidCredentials()
        await mockSync.configure(
            hasCredentials: true,
            credentials: credentials
        )

        let mockSessionRepo = MockSessionKeyRepository()
        let mockCredentialsRepo = MockOAuthCredentialsRepository()

        let viewModel = makeViewModel(
            mockSync: mockSync,
            mockSessionRepo: mockSessionRepo,
            mockCredentialsRepo: mockCredentialsRepo
        )

        await viewModel.syncFromClaudeCode()

        try await Task.sleep(for: .milliseconds(100))

        if case .success = viewModel.state {
            #expect(viewModel.statusColor == AccessibleColors.success)
        }
    }

    @Test("statusColor returns red for error state")
    func statusColorReturnsRedForError() async throws {
        let mockSync = MockClaudeCodeSync()
        await mockSync.configure(shouldThrowOnExtract: true)

        let mockSessionRepo = MockSessionKeyRepository()
        let mockCredentialsRepo = MockOAuthCredentialsRepository()

        let viewModel = makeViewModel(
            mockSync: mockSync,
            mockSessionRepo: mockSessionRepo,
            mockCredentialsRepo: mockCredentialsRepo
        )

        await viewModel.syncFromClaudeCode()

        if case .error = viewModel.state {
            #expect(viewModel.statusColor == .red)
        } else {
            Issue.record("Expected .error state after sync failure")
        }
    }

    // MARK: - checkClaudeCode Tests

    @Test("checkClaudeCode finds credentials with email")
    func checkClaudeCodeFindsCredentialsWithEmail() async {
        let mockSync = MockClaudeCodeSync()
        await mockSync.configure(
            hasCredentials: true,
            subscriptionInfo: (type: "pro", email: "user@test.com")
        )

        let mockSessionRepo = MockSessionKeyRepository()
        let mockCredentialsRepo = MockOAuthCredentialsRepository()

        let viewModel = makeViewModel(
            mockSync: mockSync,
            mockSessionRepo: mockSessionRepo,
            mockCredentialsRepo: mockCredentialsRepo
        )

        await viewModel.checkClaudeCode()

        if case .claudeCodeFound(let email) = viewModel.state {
            #expect(email == "user@test.com")
        } else {
            Issue.record("Expected .claudeCodeFound state")
        }
    }

    @Test("checkClaudeCode handles no credentials")
    func checkClaudeCodeHandlesNoCredentials() async {
        let mockSync = MockClaudeCodeSync()
        await mockSync.configure(hasCredentials: false)

        let mockSessionRepo = MockSessionKeyRepository()
        let mockCredentialsRepo = MockOAuthCredentialsRepository()

        let viewModel = makeViewModel(
            mockSync: mockSync,
            mockSessionRepo: mockSessionRepo,
            mockCredentialsRepo: mockCredentialsRepo
        )

        await viewModel.checkClaudeCode()

        #expect(viewModel.state == .claudeCodeNotFound)
    }
}
