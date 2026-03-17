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
    public private(set) var rateLimits: APIKeyRateLimitDisplayData?
    public private(set) var monthlyUsage: MonthlyUsageDisplayData?
    public private(set) var lastUpdated: Date?

    // MARK: - Dependencies

    private let fetchOrgUsageSummaryUseCase: FetchOrgUsageSummaryUseCase
    private let fetchClaudeCodeAnalyticsUseCase: FetchClaudeCodeAnalyticsUseCase
    private let fetchMonthlyUsageUseCase: FetchMonthlyUsageUseCase?
    private let getAdminKeyUseCase: GetAdminKeyUseCase
    private let fetchAPIKeyRateLimitsUseCase: FetchAPIKeyRateLimitsUseCase?
    private let getAnthropicAPIKeyUseCase: GetAnthropicAPIKeyUseCase?
    private let networkMonitor: (any NetworkMonitorProtocol)?

    // MARK: - Private

    private var usageRefreshTask: Task<Void, Never>?
    private var analyticsRefreshTask: Task<Void, Never>?
    private var monthlyRefreshTask: Task<Void, Never>?
    private var rateLimitRefreshTask: Task<Void, Never>?
    private let baseUsageInterval: TimeInterval = 60
    private let baseAnalyticsInterval: TimeInterval = 3600
    private let baseMonthlyInterval: TimeInterval = 300
    private var consecutiveFailures: Int = 0

    // MARK: - Init

    public init(
        fetchOrgUsageSummaryUseCase: FetchOrgUsageSummaryUseCase,
        fetchClaudeCodeAnalyticsUseCase: FetchClaudeCodeAnalyticsUseCase,
        fetchMonthlyUsageUseCase: FetchMonthlyUsageUseCase? = nil,
        getAdminKeyUseCase: GetAdminKeyUseCase,
        fetchAPIKeyRateLimitsUseCase: FetchAPIKeyRateLimitsUseCase? = nil,
        getAnthropicAPIKeyUseCase: GetAnthropicAPIKeyUseCase? = nil,
        networkMonitor: (any NetworkMonitorProtocol)? = nil
    ) {
        self.fetchOrgUsageSummaryUseCase = fetchOrgUsageSummaryUseCase
        self.fetchClaudeCodeAnalyticsUseCase = fetchClaudeCodeAnalyticsUseCase
        self.fetchMonthlyUsageUseCase = fetchMonthlyUsageUseCase
        self.getAdminKeyUseCase = getAdminKeyUseCase
        self.fetchAPIKeyRateLimitsUseCase = fetchAPIKeyRateLimitsUseCase
        self.getAnthropicAPIKeyUseCase = getAnthropicAPIKeyUseCase
        self.networkMonitor = networkMonitor
    }

    // MARK: - Lifecycle

    /// Start background refresh (called once at app launch)
    public func startBackgroundRefresh() async {
        guard usageRefreshTask == nil else { return }

        // Rate limit polling starts independently of Admin key
        await startRateLimitRefreshIfNeeded()

        let isConfigured = await getAdminKeyUseCase.isConfigured()
        guard isConfigured else {
            state = .noKey
            logger.info("startBackgroundRefresh: no admin key configured")
            return
        }

        state = .loading
        await loadUsage()
        await loadAnalytics()
        await loadMonthlyUsage()
        startAutoRefresh()
    }

    /// Called when menu bar popover appears
    public func onAppear() {
        guard usageRefreshTask == nil else { return }
        Task {
            await startBackgroundRefresh()
        }
    }

    /// Re-check admin key and API key, restart if newly configured
    public func recheckAndRestart() async {
        // Admin key
        let adminConfigured = await getAdminKeyUseCase.isConfigured()
        if adminConfigured && state == .noKey {
            state = .loading
            await loadUsage()
            await loadAnalytics()
            await loadMonthlyUsage()
            startAutoRefresh()
        } else if !adminConfigured {
            stopAdminAutoRefresh()
            state = .noKey
            orgSummary = nil
            analytics = nil
            monthlyUsage = nil
        }

        // API key rate limits
        await recheckRateLimits()
    }

    /// Manual refresh
    public func refresh() {
        Task {
            await loadUsage()
            await loadAnalytics()
            await loadMonthlyUsage()
            await loadRateLimits()
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

    private func loadMonthlyUsage() async {
        guard let fetchMonthlyUsageUseCase else { return }
        do {
            let entity = try await fetchMonthlyUsageUseCase.execute()
            monthlyUsage = MonthlyUsageDisplayData(from: entity)
            logger.info("loadMonthlyUsage: success (cost=\(entity.totalCostCents)¢, keys=\(entity.byApiKey.count))")
        } catch {
            logger.error("loadMonthlyUsage: error: \(error.localizedDescription)")
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

        // Monthly: every 5 min
        monthlyRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.baseMonthlyInterval ?? 300))
                guard !Task.isCancelled else { break }
                await self?.loadMonthlyUsage()
            }
        }
    }

    private func stopAdminAutoRefresh() {
        usageRefreshTask?.cancel()
        usageRefreshTask = nil
        analyticsRefreshTask?.cancel()
        analyticsRefreshTask = nil
        monthlyRefreshTask?.cancel()
        monthlyRefreshTask = nil
    }

    // MARK: - Rate Limits

    private func loadRateLimits() async {
        guard let fetchAPIKeyRateLimitsUseCase else { return }
        do {
            let entity = try await fetchAPIKeyRateLimitsUseCase.execute()
            rateLimits = APIKeyRateLimitDisplayData(from: entity)
            logger.info("loadRateLimits: \(entity.requestsRemaining)/\(entity.requestsLimit) RPM")
        } catch let error as DomainError where error == .apiKeyNotFound {
            rateLimits = nil
        } catch {
            logger.error("loadRateLimits: error: \(error.localizedDescription)")
        }
    }

    private func startRateLimitRefreshIfNeeded() async {
        guard let getAnthropicAPIKeyUseCase else { return }
        let isConfigured = await getAnthropicAPIKeyUseCase.isConfigured()
        guard isConfigured else { return }

        await loadRateLimits()
        startRateLimitAutoRefresh()
    }

    private func startRateLimitAutoRefresh() {
        rateLimitRefreshTask?.cancel()
        rateLimitRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { break }
                await self?.loadRateLimits()
            }
        }
    }

    private func stopRateLimitAutoRefresh() {
        rateLimitRefreshTask?.cancel()
        rateLimitRefreshTask = nil
    }

    private func recheckRateLimits() async {
        guard let getAnthropicAPIKeyUseCase else { return }
        let isConfigured = await getAnthropicAPIKeyUseCase.isConfigured()
        if isConfigured && rateLimitRefreshTask == nil {
            await loadRateLimits()
            startRateLimitAutoRefresh()
        } else if !isConfigured {
            stopRateLimitAutoRefresh()
            rateLimits = nil
        }
    }
}
