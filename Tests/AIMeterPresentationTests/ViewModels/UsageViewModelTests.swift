import Testing
import SwiftUI
@testable import AIMeterPresentation
@testable import AIMeterApplication
@testable import AIMeterDomain

/// Tests for UsageViewModel
@Suite("UsageViewModel Tests")
@MainActor
struct UsageViewModelTests {

    // MARK: - Mock Repositories

    actor MockUsageRepository: UsageRepository {
        var usageEntities: [UsageEntity] = []
        var extraUsageEntity: ExtraUsageEntity?
        var shouldThrowOnFetch = false

        func configure(usages: [UsageEntity], extraUsage: ExtraUsageEntity? = nil) {
            self.usageEntities = usages
            self.extraUsageEntity = extraUsage
        }

        func configure(shouldThrow: Bool) {
            self.shouldThrowOnFetch = shouldThrow
        }

        func fetchUsage() async throws -> [UsageEntity] {
            if shouldThrowOnFetch {
                throw DomainError.sessionKeyNotFound
            }
            return usageEntities
        }

        func getCachedUsage() async -> [UsageEntity] {
            return usageEntities
        }

        func cacheUsage(_ entities: [UsageEntity]) async {
            self.usageEntities = entities
        }

        func getExtraUsage() async -> ExtraUsageEntity? {
            return extraUsageEntity
        }
    }

    actor MockSessionKeyRepository: SessionKeyRepository {
        var storedKey: SessionKey?

        func configure(storedKey: SessionKey? = nil) {
            self.storedKey = storedKey
        }

        func save(_ key: SessionKey) async throws {
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

        func validateToken(_ token: String) async throws {}
    }

    actor MockNotificationService: NotificationServiceProtocol {
        var permissionGranted = true

        func requestPermission() async -> Bool { permissionGranted }

        func isPermissionGranted() async -> Bool { permissionGranted }

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

        func wasSent(key: String) -> Bool {
            return sentKeys.contains(key)
        }

        func markSent(key: String) {
            sentKeys.insert(key)
        }

        func clearExpired() {}

        func resetAll() {
            sentKeys.removeAll()
        }
    }

    // MARK: - Helper Methods

    func makeViewModel(
        mockUsageRepo: MockUsageRepository,
        mockSessionRepo: MockSessionKeyRepository,
        mockNotificationService: MockNotificationService,
        mockNotificationPrefs: MockNotificationPreferences
    ) -> UsageViewModel {
        let fetchUsageUseCase = FetchUsageUseCase(
            usageRepository: mockUsageRepo,
            sessionKeyRepository: mockSessionRepo
        )
        let getSessionKeyUseCase = GetSessionKeyUseCase(sessionKeyRepository: mockSessionRepo)
        let checkNotificationUseCase = CheckNotificationUseCase(
            notificationService: mockNotificationService,
            preferencesService: mockNotificationPrefs
        )

        return UsageViewModel(
            fetchUsageUseCase: fetchUsageUseCase,
            getSessionKeyUseCase: getSessionKeyUseCase,
            checkNotificationUseCase: checkNotificationUseCase
        )
    }

    func makeUsageEntity(
        type: UsageType,
        percentage: Double,
        resetDate: Date = Date().addingTimeInterval(3600)
    ) -> UsageEntity {
        return UsageEntity(
            type: type,
            percentage: .clamped(percentage),
            resetTime: ResetTime(resetDate)
        )
    }

    // MARK: - Computed Properties Tests

    @Test("primaryUsage returns session usage")
    func primaryUsageReturnsSessionUsage() async throws {
        let mockUsageRepo = MockUsageRepository()
        let sessionEntity = makeUsageEntity(type: .session, percentage: 70)
        let weeklyEntity = makeUsageEntity(type: .weekly, percentage: 30)
        await mockUsageRepo.configure(usages: [sessionEntity, weeklyEntity])

        let mockSessionRepo = MockSessionKeyRepository()
        let key = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await mockSessionRepo.configure(storedKey: key)

        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        if let primary = viewModel.primaryUsage {
            #expect(primary.type == .session)
            #expect(primary.type.isPrimary)
            #expect(primary.percentage == 70)
        } else {
            Issue.record("Expected primary usage to be non-nil")
        }
    }

    @Test("secondaryUsages returns non-primary usage types")
    func secondaryUsagesReturnsNonPrimaryTypes() async throws {
        let mockUsageRepo = MockUsageRepository()
        let sessionEntity = makeUsageEntity(type: .session, percentage: 70)
        let weeklyEntity = makeUsageEntity(type: .weekly, percentage: 30)
        let opusEntity = makeUsageEntity(type: .opus, percentage: 40)
        await mockUsageRepo.configure(usages: [sessionEntity, weeklyEntity, opusEntity])

        let mockSessionRepo = MockSessionKeyRepository()
        let key = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await mockSessionRepo.configure(storedKey: key)

        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        let secondaryUsages = viewModel.secondaryUsages
        #expect(secondaryUsages.count == 2)
        #expect(secondaryUsages.allSatisfy { !$0.type.isPrimary })
        #expect(secondaryUsages.contains { $0.type == .weekly })
        #expect(secondaryUsages.contains { $0.type == .opus })
    }

    @Test("hasCriticalUsage returns true when any usage is critical")
    func hasCriticalUsageReturnsTrueWhenCritical() async throws {
        let mockUsageRepo = MockUsageRepository()
        let sessionEntity = makeUsageEntity(type: .session, percentage: 85)
        let weeklyEntity = makeUsageEntity(type: .weekly, percentage: 30)
        await mockUsageRepo.configure(usages: [sessionEntity, weeklyEntity])

        let mockSessionRepo = MockSessionKeyRepository()
        let key = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await mockSessionRepo.configure(storedKey: key)

        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.hasCriticalUsage)
    }

    @Test("hasCriticalUsage returns false when no critical usage")
    func hasCriticalUsageReturnsFalseWhenNotCritical() async throws {
        let mockUsageRepo = MockUsageRepository()
        let sessionEntity = makeUsageEntity(type: .session, percentage: 45)
        let weeklyEntity = makeUsageEntity(type: .weekly, percentage: 30)
        await mockUsageRepo.configure(usages: [sessionEntity, weeklyEntity])

        let mockSessionRepo = MockSessionKeyRepository()
        let key = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await mockSessionRepo.configure(storedKey: key)

        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        #expect(!viewModel.hasCriticalUsage)
    }

    @Test("menuBarText returns '70/30' format when session and weekly exist")
    func menuBarTextReturnsCorrectFormat() async throws {
        let mockUsageRepo = MockUsageRepository()
        let sessionEntity = makeUsageEntity(type: .session, percentage: 70)
        let weeklyEntity = makeUsageEntity(type: .weekly, percentage: 30)
        await mockUsageRepo.configure(usages: [sessionEntity, weeklyEntity])

        let mockSessionRepo = MockSessionKeyRepository()
        let key = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await mockSessionRepo.configure(storedKey: key)

        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.menuBarText == "70/30")
    }

    @Test("menuBarText returns '--/--' when no data")
    func menuBarTextReturnsPlaceholderWhenNoData() {
        let mockUsageRepo = MockUsageRepository()
        let mockSessionRepo = MockSessionKeyRepository()
        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        #expect(viewModel.menuBarText == "--/--")
    }

    @Test("menuBarStatus returns safe when no data")
    func menuBarStatusReturnsSafeWhenNoData() {
        let mockUsageRepo = MockUsageRepository()
        let mockSessionRepo = MockSessionKeyRepository()
        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        #expect(viewModel.menuBarStatus == .safe)
    }

    @Test("menuBarStatus returns critical when session is critical")
    func menuBarStatusReturnsCriticalWhenSessionCritical() async throws {
        let mockUsageRepo = MockUsageRepository()
        let sessionEntity = makeUsageEntity(type: .session, percentage: 85)
        let weeklyEntity = makeUsageEntity(type: .weekly, percentage: 30)
        await mockUsageRepo.configure(usages: [sessionEntity, weeklyEntity])

        let mockSessionRepo = MockSessionKeyRepository()
        let key = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await mockSessionRepo.configure(storedKey: key)

        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.menuBarStatus == .critical)
    }

    @Test("lastUpdatedText returns 'Never' when nil")
    func lastUpdatedTextReturnsNeverWhenNil() {
        let mockUsageRepo = MockUsageRepository()
        let mockSessionRepo = MockSessionKeyRepository()
        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        #expect(viewModel.lastUpdatedText == "Never")
    }

    @Test("lastUpdatedText returns relative time after loading")
    func lastUpdatedTextReturnsRelativeTimeAfterLoading() async throws {
        let mockUsageRepo = MockUsageRepository()
        let sessionEntity = makeUsageEntity(type: .session, percentage: 70)
        await mockUsageRepo.configure(usages: [sessionEntity])

        let mockSessionRepo = MockSessionKeyRepository()
        let key = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await mockSessionRepo.configure(storedKey: key)

        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.lastUpdatedText != "Never")
    }

    // MARK: - State Tests

    @Test("Initial state is loading")
    func initialStateIsLoading() {
        let mockUsageRepo = MockUsageRepository()
        let mockSessionRepo = MockSessionKeyRepository()
        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        #expect(viewModel.state == .loading)
    }

    @Test("State transitions to needsSetup when no session key")
    func stateTransitionsToNeedsSetupWhenNoKey() async throws {
        let mockUsageRepo = MockUsageRepository()
        let mockSessionRepo = MockSessionKeyRepository()

        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.state == .needsSetup)
    }

    @Test("State transitions to loaded when data is fetched")
    func stateTransitionsToLoadedWhenDataFetched() async throws {
        let mockUsageRepo = MockUsageRepository()
        let sessionEntity = makeUsageEntity(type: .session, percentage: 70)
        await mockUsageRepo.configure(usages: [sessionEntity])

        let mockSessionRepo = MockSessionKeyRepository()
        let key = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await mockSessionRepo.configure(storedKey: key)

        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        if case .loaded(let data) = viewModel.state {
            #expect(data.count == 1)
            #expect(data.first?.type == .session)
        } else {
            Issue.record("Expected .loaded state, got \(viewModel.state)")
        }
    }

    @Test("weeklyUsage returns weekly usage type")
    func weeklyUsageReturnsWeeklyType() async throws {
        let mockUsageRepo = MockUsageRepository()
        let sessionEntity = makeUsageEntity(type: .session, percentage: 70)
        let weeklyEntity = makeUsageEntity(type: .weekly, percentage: 45)
        await mockUsageRepo.configure(usages: [sessionEntity, weeklyEntity])

        let mockSessionRepo = MockSessionKeyRepository()
        let key = try SessionKey.create("sk-ant-oat01-testtoken123456789")
        await mockSessionRepo.configure(storedKey: key)

        let mockNotificationService = MockNotificationService()
        let mockNotificationPrefs = MockNotificationPreferences()

        let viewModel = makeViewModel(
            mockUsageRepo: mockUsageRepo,
            mockSessionRepo: mockSessionRepo,
            mockNotificationService: mockNotificationService,
            mockNotificationPrefs: mockNotificationPrefs
        )

        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        if let weekly = viewModel.weeklyUsage {
            #expect(weekly.type == .weekly)
            #expect(weekly.percentage == 45)
        } else {
            Issue.record("Expected weeklyUsage to be non-nil")
        }
    }
}
