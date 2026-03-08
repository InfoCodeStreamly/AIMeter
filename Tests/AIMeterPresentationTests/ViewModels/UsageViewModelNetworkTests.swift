import Testing
import SwiftUI
@testable import AIMeterPresentation
@testable import AIMeterApplication
@testable import AIMeterDomain

@Suite("UsageViewModel Network Tests")
@MainActor
struct UsageViewModelNetworkTests {

    actor MockUsageRepository: UsageRepository {
        var usageEntities: [UsageEntity] = []
        var extraUsageEntity: ExtraUsageEntity?
        var fetchCount = 0

        func configure(usages: [UsageEntity]) { self.usageEntities = usages }
        func fetchUsage() async throws -> [UsageEntity] { fetchCount += 1; return usageEntities }
        func getCachedUsage() async -> [UsageEntity] { usageEntities }
        func cacheUsage(_ entities: [UsageEntity]) async { usageEntities = entities }
        func getExtraUsage() async -> ExtraUsageEntity? { extraUsageEntity }
    }

    actor MockSessionKeyRepository: SessionKeyRepository {
        var storedKey: SessionKey?
        func configure(storedKey: SessionKey?) { self.storedKey = storedKey }
        func save(_ key: SessionKey) async throws { storedKey = key }
        func get() async -> SessionKey? { storedKey }
        func delete() async { storedKey = nil }
        func exists() async -> Bool { storedKey != nil }
        func validateToken(_ token: String) async throws {}
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

    actor MockNetworkMonitor: NetworkMonitorProtocol {
        private var _isConnected = true
        private var onChange: (@Sendable (Bool) -> Void)?

        func configure(isConnected: Bool) { _isConnected = isConnected }
        func isConnected() async -> Bool { _isConnected }
        func startMonitoring(onChange: @Sendable @escaping (Bool) -> Void) async { self.onChange = onChange }
        func stopMonitoring() async { onChange = nil }
        func simulateNetworkChange(connected: Bool) { _isConnected = connected; onChange?(connected) }
    }

    func makeViewModel(
        mockUsageRepo: MockUsageRepository,
        mockSessionRepo: MockSessionKeyRepository,
        mockNetworkMonitor: MockNetworkMonitor? = nil
    ) -> UsageViewModel {
        let fetchUsageUseCase = FetchUsageUseCase(usageRepository: mockUsageRepo, sessionKeyRepository: mockSessionRepo)
        let getSessionKeyUseCase = GetSessionKeyUseCase(sessionKeyRepository: mockSessionRepo)
        let checkNotificationUseCase = CheckNotificationUseCase(
            notificationService: MockNotificationService(),
            preferencesService: MockNotificationPreferences()
        )
        return UsageViewModel(
            fetchUsageUseCase: fetchUsageUseCase,
            getSessionKeyUseCase: getSessionKeyUseCase,
            checkNotificationUseCase: checkNotificationUseCase,
            networkMonitor: mockNetworkMonitor
        )
    }

    func makeUsageEntity(type: UsageType, percentage: Double) -> UsageEntity {
        UsageEntity(type: type, percentage: .clamped(percentage), resetTime: ResetTime(Date().addingTimeInterval(3600)))
    }

    @Test("network restored triggers loadUsage")
    func networkRestoredTriggersLoad() async throws {
        let mockUsageRepo = MockUsageRepository()
        await mockUsageRepo.configure(usages: [makeUsageEntity(type: .session, percentage: 50)])
        let mockSessionRepo = MockSessionKeyRepository()
        await mockSessionRepo.configure(storedKey: try SessionKey.create("sk-ant-oat01-testtoken123456789"))
        let mockNetworkMonitor = MockNetworkMonitor()

        let viewModel = makeViewModel(mockUsageRepo: mockUsageRepo, mockSessionRepo: mockSessionRepo, mockNetworkMonitor: mockNetworkMonitor)
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        let fetchCountBefore = await mockUsageRepo.fetchCount
        await mockNetworkMonitor.simulateNetworkChange(connected: true)
        try await Task.sleep(for: .milliseconds(300))

        let fetchCountAfter = await mockUsageRepo.fetchCount
        #expect(fetchCountAfter > fetchCountBefore)
    }

    @Test("network lost does not trigger refresh")
    func networkLostDoesNotTrigger() async throws {
        let mockUsageRepo = MockUsageRepository()
        await mockUsageRepo.configure(usages: [makeUsageEntity(type: .session, percentage: 50)])
        let mockSessionRepo = MockSessionKeyRepository()
        await mockSessionRepo.configure(storedKey: try SessionKey.create("sk-ant-oat01-testtoken123456789"))
        let mockNetworkMonitor = MockNetworkMonitor()

        let viewModel = makeViewModel(mockUsageRepo: mockUsageRepo, mockSessionRepo: mockSessionRepo, mockNetworkMonitor: mockNetworkMonitor)
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        let fetchCountBefore = await mockUsageRepo.fetchCount
        await mockNetworkMonitor.simulateNetworkChange(connected: false)
        try await Task.sleep(for: .milliseconds(200))

        let fetchCountAfter = await mockUsageRepo.fetchCount
        #expect(fetchCountAfter == fetchCountBefore)
    }

    @Test("no network monitor does not crash")
    func noNetworkMonitorDoesNotCrash() async throws {
        let mockUsageRepo = MockUsageRepository()
        await mockUsageRepo.configure(usages: [makeUsageEntity(type: .session, percentage: 50)])
        let mockSessionRepo = MockSessionKeyRepository()
        await mockSessionRepo.configure(storedKey: try SessionKey.create("sk-ant-oat01-testtoken123456789"))

        let viewModel = makeViewModel(mockUsageRepo: mockUsageRepo, mockSessionRepo: mockSessionRepo, mockNetworkMonitor: nil)
        await viewModel.startBackgroundRefresh()
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.primaryUsage != nil)
    }
}
