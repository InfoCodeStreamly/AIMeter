import AIMeterApplication
import AIMeterDomain
import OSLog
import SwiftUI

/// ViewModel for organization API usage display
@MainActor
@Observable
public final class OrgUsageViewModel {
    private let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "org-usage-vm")

    // MARK: - State

    public private(set) var state: OrgUsageViewState = .noKey
    public private(set) var orgSummary: OrgUsageSummaryDisplayData?
    public private(set) var analytics: ClaudeCodeAnalyticsDisplayData?
    public private(set) var lastUpdated: Date?

    // MARK: - Dependencies

    private let fetchOrgUsageSummaryUseCase: FetchOrgUsageSummaryUseCase
    private let fetchClaudeCodeAnalyticsUseCase: FetchClaudeCodeAnalyticsUseCase
    private let getAdminKeyUseCase: GetAdminKeyUseCase
    private let networkMonitor: (any NetworkMonitorProtocol)?

    // MARK: - Private

    private var usageRefreshTask: Task<Void, Never>?
    private var analyticsRefreshTask: Task<Void, Never>?
    private let baseUsageInterval: TimeInterval = 60
    private let baseAnalyticsInterval: TimeInterval = 3600
    private var consecutiveFailures: Int = 0

    // MARK: - Init

    public init(
        fetchOrgUsageSummaryUseCase: FetchOrgUsageSummaryUseCase,
        fetchClaudeCodeAnalyticsUseCase: FetchClaudeCodeAnalyticsUseCase,
        getAdminKeyUseCase: GetAdminKeyUseCase,
        networkMonitor: (any NetworkMonitorProtocol)? = nil
    ) {
        self.fetchOrgUsageSummaryUseCase = fetchOrgUsageSummaryUseCase
        self.fetchClaudeCodeAnalyticsUseCase = fetchClaudeCodeAnalyticsUseCase
        self.getAdminKeyUseCase = getAdminKeyUseCase
        self.networkMonitor = networkMonitor
    }

    // MARK: - Lifecycle

    /// Start background refresh (called once at app launch)
    public func startBackgroundRefresh() async {
        guard usageRefreshTask == nil else { return }

        let isConfigured = await getAdminKeyUseCase.isConfigured()
        guard isConfigured else {
            state = .noKey
            logger.info("startBackgroundRefresh: no admin key configured")
            return
        }

        state = .loading
        await loadUsage()
        await loadAnalytics()
        startAutoRefresh()
    }

    /// Called when menu bar popover appears
    public func onAppear() {
        guard usageRefreshTask == nil else { return }
        Task {
            await startBackgroundRefresh()
        }
    }

    /// Re-check admin key and restart if newly configured
    public func recheckAndRestart() async {
        let isConfigured = await getAdminKeyUseCase.isConfigured()
        if isConfigured && state == .noKey {
            state = .loading
            await loadUsage()
            await loadAnalytics()
            startAutoRefresh()
        } else if !isConfigured {
            stopAutoRefresh()
            state = .noKey
            orgSummary = nil
            analytics = nil
        }
    }

    /// Manual refresh
    public func refresh() {
        Task {
            await loadUsage()
            await loadAnalytics()
        }
    }

    // MARK: - Private

    private func loadUsage() async {
        do {
            let entity = try await fetchOrgUsageSummaryUseCase.execute()
            orgSummary = OrgUsageSummaryDisplayData(from: entity)
            state = .loaded
            lastUpdated = Date()
            consecutiveFailures = 0
            logger.info("loadUsage: success (cost=\(entity.totalCostCents)¢)")
        } catch let error as DomainError where error == .adminKeyNotFound {
            state = .noKey
            logger.warning("loadUsage: admin key not found")
        } catch {
            consecutiveFailures += 1
            logger.error("loadUsage: error: \(error.localizedDescription)")
            if !state.hasData {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func loadAnalytics() async {
        do {
            let entities = try await fetchClaudeCodeAnalyticsUseCase.execute()
            analytics = ClaudeCodeAnalyticsDisplayData(from: entities)
            logger.info("loadAnalytics: success (\(entities.count) users)")
        } catch {
            logger.error("loadAnalytics: error: \(error.localizedDescription)")
        }
    }

    private func startAutoRefresh() {
        // Usage: every 60s
        usageRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.baseUsageInterval ?? 60))
                guard !Task.isCancelled else { break }
                await self?.loadUsage()
            }
        }

        // Analytics: every 1h
        analyticsRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.baseAnalyticsInterval ?? 3600))
                guard !Task.isCancelled else { break }
                await self?.loadAnalytics()
            }
        }
    }

    private func stopAutoRefresh() {
        usageRefreshTask?.cancel()
        usageRefreshTask = nil
        analyticsRefreshTask?.cancel()
        analyticsRefreshTask = nil
    }
}
