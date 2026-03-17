import Testing
import SwiftUI
@testable import AIMeterPresentation
@testable import AIMeterApplication
@testable import AIMeterDomain

/// Tests for UsageViewModel setup and state-transition logic.
///
/// Covers the priority order in checkSetupAndLoad() (OAuth checked first),
/// reloadAfterSync(), recheckSetup() with hasData guard, and refresh()
/// short-circuit in apiKeyOnly mode.
@Suite("UsageViewModel Setup Tests")
@MainActor
struct UsageViewModelSetupTests {

    // MARK: - Mocks

    actor MockUsageRepository: UsageRepository {
        var usageEntities: [UsageEntity] = []
        var extraUsageEntity: ExtraUsageEntity?

        func configure(usages: [UsageEntity]) { self.usageEntities = usages }

        func fetchUsage() async throws -> [UsageEntity] { usageEntities }
        func getCachedUsage() async -> [UsageEntity] { usageEntities }
        func cacheUsage(_ entities: [UsageEntity]) async { usageEntities = entities }
        func getExtraUsage() async -> ExtraUsageEntity? { extraUsageEntity }
    }

    actor MockSessionKeyRepository: SessionKeyRepository {
        var storedKey: SessionKey?

        func configure(storedKey: SessionKey? = nil) { self.storedKey = storedKey }

        func save(_ key: SessionKey) async throws { storedKey = key }
        func get() async -> SessionKey? { storedKey }
        func delete() async { storedKey = nil }
        func exists() async -> Bool { storedKey != nil }
        func validateToken(_ token: String) async throws {}
    }

    actor MockAPIKeyRepository: APIKeyRepository {
        var storedKey: AnthropicAPIKey?

        func configure(storedKey: AnthropicAPIKey? = nil) { self.storedKey = storedKey }

        func save(_ key: AnthropicAPIKey) async throws { storedKey = key }
        func get() async -> AnthropicAPIKey? { storedKey }
        func delete() async { storedKey = nil }
        func exists() async -> Bool { storedKey != nil }
    }

    actor MockAdminKeyRepository: AdminKeyRepository {
        var storedKey: AdminAPIKey?

        func configure(storedKey: AdminAPIKey? = nil) { self.storedKey = storedKey }

        func save(_ key: AdminAPIKey) async throws { storedKey = key }
        func get() async -> AdminAPIKey? { storedKey }
        func delete() async { storedKey = nil }
        func exists() async -> Bool { storedKey != nil }
    }

    actor MockNotificationService: NotificationServiceProtocol {
        func requestPermission() async -> Bool { true }
        func isPermissionGranted() async -> Bool { true }
        func send(title: String, body: String, identifier: String) async {}
        func removePending(identifiers: [String]) async {}
        func removeDelivered(identifiers: [String]) async {}
    }

    @MainActor
    final class MockNotificationPreferences: NotificationPreferencesProtocol {
        var isEnabled = true
        var warningThreshold = 80
        var criticalThreshold = 95
        private var sentKeys: Set<String> = []
        func wasSent(key: String) -> Bool { sentKeys.contains(key) }
        func markSent(key: String) { sentKeys.insert(key) }
        func clearExpired() {}
        func resetAll() { sentKeys.removeAll() }
    }

    // MARK: - Builder

    func makeViewModel(
        sessionRepo: MockSessionKeyRepository,
        usageRepo: MockUsageRepository,
        apiKeyRepo: MockAPIKeyRepository? = nil,
        adminKeyRepo: MockAdminKeyRepository? = nil
    ) -> UsageViewModel {
        let fetchUseCase = FetchUsageUseCase(
            usageRepository: usageRepo,
            sessionKeyRepository: sessionRepo
        )
        let getSessionKeyUseCase = GetSessionKeyUseCase(sessionKeyRepository: sessionRepo)
        let checkNotificationUseCase = CheckNotificationUseCase(
            notificationService: MockNotificationService(),
            preferencesService: MockNotificationPreferences()
        )
        let getApiKeyUseCase: GetAnthropicAPIKeyUseCase? = apiKeyRepo.map {
            GetAnthropicAPIKeyUseCase(apiKeyRepository: $0)
        }
        let getAdminKeyUseCase: GetAdminKeyUseCase? = adminKeyRepo.map {
            GetAdminKeyUseCase(adminKeyRepository: $0)
        }
        return UsageViewModel(
            fetchUsageUseCase: fetchUseCase,
            getSessionKeyUseCase: getSessionKeyUseCase,
            checkNotificationUseCase: checkNotificationUseCase,
            getAnthropicAPIKeyUseCase: getApiKeyUseCase,
            getAdminKeyUseCase: getAdminKeyUseCase
        )
    }

    func makeUsageEntity(type: UsageType, percentage: Double) -> UsageEntity {
        UsageEntity(
            type: type,
            percentage: .clamped(percentage),
            resetTime: ResetTime(Date().addingTimeInterval(3600))
        )
    }

    // MARK: - checkSetupAndLoad priority tests

    @Test("OAuth configured — state becomes loaded, not apiKeyOnly")
    func oauthConfigured_stateBecomesLoaded() async throws {
        // Arrange
        let sessionRepo = MockSessionKeyRepository()
        let key = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await sessionRepo.configure(storedKey: key)

        let usageRepo = MockUsageRepository()
        await usageRepo.configure(usages: [makeUsageEntity(type: .session, percentage: 40)])

        let apiKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await apiKeyRepo.configure(storedKey: apiKey)

        let viewModel = makeViewModel(
            sessionRepo: sessionRepo,
            usageRepo: usageRepo,
            apiKeyRepo: apiKeyRepo
        )

        // Act
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        // Assert — OAuth takes priority: state must be .loaded, not .apiKeyOnly
        if case .loaded = viewModel.state {
            // pass
        } else {
            Issue.record("Expected .loaded state but got \(viewModel.state)")
        }
        #expect(!viewModel.state.isApiKeyOnly)
    }

    @Test("OAuth not configured, API key configured — state becomes apiKeyOnly")
    func noOauth_apiKeyConfigured_stateBecomesApiKeyOnly() async throws {
        // Arrange
        let sessionRepo = MockSessionKeyRepository()
        // No OAuth key stored

        let usageRepo = MockUsageRepository()

        let apiKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await apiKeyRepo.configure(storedKey: apiKey)

        let viewModel = makeViewModel(
            sessionRepo: sessionRepo,
            usageRepo: usageRepo,
            apiKeyRepo: apiKeyRepo
        )

        // Act
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        // Assert
        #expect(viewModel.state == .apiKeyOnly)
    }

    @Test("OAuth not configured, Admin key configured — state becomes apiKeyOnly")
    func noOauth_adminKeyConfigured_stateBecomesApiKeyOnly() async throws {
        // Arrange
        let sessionRepo = MockSessionKeyRepository()
        // No OAuth key stored

        let usageRepo = MockUsageRepository()

        let adminKeyRepo = MockAdminKeyRepository()
        let adminKey = try AdminAPIKey.create("sk-ant-admin-testkey12345678")
        await adminKeyRepo.configure(storedKey: adminKey)

        let viewModel = makeViewModel(
            sessionRepo: sessionRepo,
            usageRepo: usageRepo,
            adminKeyRepo: adminKeyRepo
        )

        // Act
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        // Assert
        #expect(viewModel.state == .apiKeyOnly)
    }

    @Test("Nothing configured — state becomes needsSetup")
    func nothingConfigured_stateBecomesNeedsSetup() async throws {
        // Arrange
        let sessionRepo = MockSessionKeyRepository()
        // No OAuth
        let usageRepo = MockUsageRepository()
        let apiKeyRepo = MockAPIKeyRepository()
        // No API key either
        let adminKeyRepo = MockAdminKeyRepository()
        // No Admin key either

        let viewModel = makeViewModel(
            sessionRepo: sessionRepo,
            usageRepo: usageRepo,
            apiKeyRepo: apiKeyRepo,
            adminKeyRepo: adminKeyRepo
        )

        // Act
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        // Assert
        #expect(viewModel.state == .needsSetup)
    }

    @Test("OAuth AND API key both configured — OAuth takes priority, state becomes loaded")
    func oauthAndApiKey_oauthTakesPriority() async throws {
        // Arrange
        let sessionRepo = MockSessionKeyRepository()
        let key = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await sessionRepo.configure(storedKey: key)

        let usageRepo = MockUsageRepository()
        await usageRepo.configure(usages: [makeUsageEntity(type: .session, percentage: 55)])

        let apiKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await apiKeyRepo.configure(storedKey: apiKey)

        let viewModel = makeViewModel(
            sessionRepo: sessionRepo,
            usageRepo: usageRepo,
            apiKeyRepo: apiKeyRepo
        )

        // Act
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        // Assert — must never be apiKeyOnly when OAuth is present
        #expect(!viewModel.state.isApiKeyOnly)
        #expect(viewModel.state.hasData)
    }

    // MARK: - reloadAfterSync tests

    @Test("reloadAfterSync with OAuth configured transitions from apiKeyOnly to loaded")
    func reloadAfterSync_oauthConfigured_transitionsToLoaded() async throws {
        // Arrange — start in apiKeyOnly mode (no OAuth initially)
        let sessionRepo = MockSessionKeyRepository()
        let usageRepo = MockUsageRepository()
        let apiKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await apiKeyRepo.configure(storedKey: apiKey)

        let viewModel = makeViewModel(
            sessionRepo: sessionRepo,
            usageRepo: usageRepo,
            apiKeyRepo: apiKeyRepo
        )
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        // Precondition: must be in apiKeyOnly
        #expect(viewModel.state == .apiKeyOnly)

        // Now OAuth key becomes available (simulate sync)
        let oauthKey = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await sessionRepo.configure(storedKey: oauthKey)
        await usageRepo.configure(usages: [makeUsageEntity(type: .session, percentage: 30)])

        // Act
        viewModel.reloadAfterSync()
        try await Task.sleep(for: .milliseconds(300))

        // Assert — must transition to loaded (OAuth path)
        if case .loaded = viewModel.state {
            // pass
        } else {
            Issue.record("Expected .loaded after reloadAfterSync with OAuth, got \(viewModel.state)")
        }
    }

    @Test("reloadAfterSync without OAuth returns to apiKeyOnly when API key still configured")
    func reloadAfterSync_noOauth_returnsToApiKeyOnly() async throws {
        // Arrange — apiKeyOnly mode (no OAuth, but API key present)
        let sessionRepo = MockSessionKeyRepository()
        let usageRepo = MockUsageRepository()
        let apiKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await apiKeyRepo.configure(storedKey: apiKey)

        let viewModel = makeViewModel(
            sessionRepo: sessionRepo,
            usageRepo: usageRepo,
            apiKeyRepo: apiKeyRepo
        )
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))
        #expect(viewModel.state == .apiKeyOnly)

        // Act — reloadAfterSync passes through .loading then re-checks setup:
        // no OAuth → API key present → back to .apiKeyOnly
        viewModel.reloadAfterSync()
        try await Task.sleep(for: .milliseconds(300))

        // Assert — after the full cycle, apiKeyOnly is the correct final state
        #expect(viewModel.state == .apiKeyOnly)
    }

    // MARK: - recheckSetup tests

    @Test("recheckSetup — state is loaded, API key exists — state stays loaded")
    func recheckSetup_stateLoaded_apiKeyExists_stateUnchanged() async throws {
        // Arrange — start with OAuth so state becomes .loaded
        let sessionRepo = MockSessionKeyRepository()
        let key = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await sessionRepo.configure(storedKey: key)

        let usageRepo = MockUsageRepository()
        await usageRepo.configure(usages: [makeUsageEntity(type: .session, percentage: 50)])

        let apiKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await apiKeyRepo.configure(storedKey: apiKey)

        let viewModel = makeViewModel(
            sessionRepo: sessionRepo,
            usageRepo: usageRepo,
            apiKeyRepo: apiKeyRepo
        )
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        // Precondition: loaded with data
        #expect(viewModel.state.hasData)

        // Act
        viewModel.recheckSetup()
        try await Task.sleep(for: .milliseconds(200))

        // Assert — loaded state must NOT be overwritten to apiKeyOnly
        #expect(viewModel.state.hasData)
        #expect(!viewModel.state.isApiKeyOnly)
    }

    @Test("recheckSetup — state is needsSetup, API key added — state becomes apiKeyOnly")
    func recheckSetup_stateNeedsSetup_apiKeyAdded_stateBecomesApiKeyOnly() async throws {
        // Arrange — no keys at all → needsSetup
        let sessionRepo = MockSessionKeyRepository()
        let usageRepo = MockUsageRepository()
        let apiKeyRepo = MockAPIKeyRepository()

        let viewModel = makeViewModel(
            sessionRepo: sessionRepo,
            usageRepo: usageRepo,
            apiKeyRepo: apiKeyRepo
        )
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))
        #expect(viewModel.state == .needsSetup)

        // Simulate user adding an API key in Settings
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await apiKeyRepo.configure(storedKey: apiKey)

        // Act
        viewModel.recheckSetup()
        try await Task.sleep(for: .milliseconds(200))

        // Assert
        #expect(viewModel.state == .apiKeyOnly)
    }

    @Test("recheckSetup — state is apiKeyOnly, keys removed — state becomes needsSetup")
    func recheckSetup_stateApiKeyOnly_keysRemoved_stateBecomesNeedsSetup() async throws {
        // Arrange — start in apiKeyOnly mode
        let sessionRepo = MockSessionKeyRepository()
        let usageRepo = MockUsageRepository()
        let apiKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await apiKeyRepo.configure(storedKey: apiKey)

        let viewModel = makeViewModel(
            sessionRepo: sessionRepo,
            usageRepo: usageRepo,
            apiKeyRepo: apiKeyRepo
        )
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))
        #expect(viewModel.state == .apiKeyOnly)

        // Simulate user deleting the API key in Settings
        await apiKeyRepo.configure(storedKey: nil)

        // Act
        viewModel.recheckSetup()
        try await Task.sleep(for: .milliseconds(200))

        // Assert
        #expect(viewModel.state == .needsSetup)
    }

    // MARK: - refresh() tests

    @Test("refresh in apiKeyOnly state does not call loadUsage (no fetch occurs)")
    func refresh_inApiKeyOnlyState_doesNotLoadUsage() async throws {
        // Arrange — set up a counting usage repo
        let sessionRepo = MockSessionKeyRepository()
        let usageRepo = MockCountingUsageRepository()
        let apiKeyRepo = MockAPIKeyRepository()
        let apiKey = try AnthropicAPIKey.create("sk-ant-api03-testkey1234567890abcdef")
        await apiKeyRepo.configure(storedKey: apiKey)

        let fetchUseCase = FetchUsageUseCase(
            usageRepository: usageRepo,
            sessionKeyRepository: sessionRepo
        )
        let getSessionKeyUseCase = GetSessionKeyUseCase(sessionKeyRepository: sessionRepo)
        let checkNotificationUseCase = CheckNotificationUseCase(
            notificationService: MockNotificationService(),
            preferencesService: MockNotificationPreferences()
        )
        let getApiKeyUseCase = GetAnthropicAPIKeyUseCase(apiKeyRepository: apiKeyRepo)

        let viewModel = UsageViewModel(
            fetchUsageUseCase: fetchUseCase,
            getSessionKeyUseCase: getSessionKeyUseCase,
            checkNotificationUseCase: checkNotificationUseCase,
            getAnthropicAPIKeyUseCase: getApiKeyUseCase
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))
        #expect(viewModel.state == .apiKeyOnly)

        let fetchCountBefore = await usageRepo.fetchCount

        // Act
        viewModel.refresh()
        try await Task.sleep(for: .milliseconds(200))

        // Assert — fetchUsage must NOT have been called
        let fetchCountAfter = await usageRepo.fetchCount
        #expect(fetchCountAfter == fetchCountBefore)
    }
}

// MARK: - Counting repo helper (defined outside the Suite to avoid actor-in-struct restriction)

private actor MockCountingUsageRepository: UsageRepository {
    var fetchCount = 0
    var usageEntities: [UsageEntity] = []

    func fetchUsage() async throws -> [UsageEntity] {
        fetchCount += 1
        return usageEntities
    }
    func getCachedUsage() async -> [UsageEntity] { usageEntities }
    func cacheUsage(_ entities: [UsageEntity]) async { usageEntities = entities }
    func getExtraUsage() async -> ExtraUsageEntity? { nil }
}
