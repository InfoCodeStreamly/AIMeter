import AIMeterApplication
import AIMeterDomain
import AppKit
import OSLog
import SwiftUI

/// ViewModel for usage display
@MainActor
@Observable
public final class UsageViewModel {
    private let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "usage-vm")
    public private(set) var state: UsageViewState = .loading
    public private(set) var lastUpdated: Date?
    public private(set) var extraUsage: ExtraUsageDisplayData?
    public private(set) var usageHistory: [UsageHistoryEntry] = []
    public private(set) var detailHistory: [UsageHistoryEntry] = []
    public var selectedGranularity: TimeGranularity = .oneHour
    public private(set) var deepgramUsage: DeepgramUsageStats?

    private let fetchUsageUseCase: FetchUsageUseCase
    private let getSessionKeyUseCase: GetSessionKeyUseCase
    private let checkNotificationUseCase: CheckNotificationUseCase
    private let refreshTokenUseCase: RefreshTokenUseCase?
    private let getExtraUsageUseCase: GetExtraUsageUseCase?
    private let saveUsageHistoryUseCase: SaveUsageHistoryUseCase?
    private let fetchUsageHistoryUseCase: FetchUsageHistoryUseCase?
    private let widgetDataService: (any WidgetDataServiceProtocol)?
    private let fetchDeepgramUsageUseCase: FetchDeepgramUsageUseCase?
    private let voiceInputPreferences: (any VoiceInputPreferencesProtocol)?
    private let keychainService: (any KeychainServiceProtocol)?
    private let networkMonitor: (any NetworkMonitorProtocol)?

    private var refreshTask: Task<Void, Never>?
    private let baseRefreshInterval: TimeInterval = 300  // 5 minutes
    private var consecutiveFailures: Int = 0
    private var isLoadingUsage = false
    private var lastRateLimitedAt: Date?

    public init(
        fetchUsageUseCase: FetchUsageUseCase,
        getSessionKeyUseCase: GetSessionKeyUseCase,
        checkNotificationUseCase: CheckNotificationUseCase,
        refreshTokenUseCase: RefreshTokenUseCase? = nil,
        getExtraUsageUseCase: GetExtraUsageUseCase? = nil,
        saveUsageHistoryUseCase: SaveUsageHistoryUseCase? = nil,
        fetchUsageHistoryUseCase: FetchUsageHistoryUseCase? = nil,
        widgetDataService: (any WidgetDataServiceProtocol)? = nil,
        fetchDeepgramUsageUseCase: FetchDeepgramUsageUseCase? = nil,
        voiceInputPreferences: (any VoiceInputPreferencesProtocol)? = nil,
        keychainService: (any KeychainServiceProtocol)? = nil,
        networkMonitor: (any NetworkMonitorProtocol)? = nil
    ) {
        self.fetchUsageUseCase = fetchUsageUseCase
        self.getSessionKeyUseCase = getSessionKeyUseCase
        self.checkNotificationUseCase = checkNotificationUseCase
        self.refreshTokenUseCase = refreshTokenUseCase
        self.getExtraUsageUseCase = getExtraUsageUseCase
        self.saveUsageHistoryUseCase = saveUsageHistoryUseCase
        self.fetchUsageHistoryUseCase = fetchUsageHistoryUseCase
        self.widgetDataService = widgetDataService
        self.fetchDeepgramUsageUseCase = fetchDeepgramUsageUseCase
        self.voiceInputPreferences = voiceInputPreferences
        self.keychainService = keychainService
        self.networkMonitor = networkMonitor
    }

    /// Start background refresh (called once at app launch)
    public func startBackgroundRefresh() async {
        // Only start once
        guard refreshTask == nil else {
            logger.debug("startBackgroundRefresh: already running, skipping")
            return
        }

        logger.info("startBackgroundRefresh: starting initial load")
        await checkSetupAndLoad()
        startAutoRefresh()

        // Subscribe to network changes — refresh immediately when network restores
        Task { [weak self] in
            await self?.networkMonitor?.startMonitoring { [weak self] isConnected in
                guard isConnected else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.logger.info("networkMonitor: network restored, refreshing immediately")
                    self.consecutiveFailures = 0
                    self.lastRateLimitedAt = nil
                    await self.loadUsage()
                }
            }
        }
    }

    /// Initial load (when popup appears)
    public func onAppear() {
        // Background refresh already handles loading — only load if not yet started
        guard refreshTask == nil else { return }
        Task {
            await checkSetupAndLoad()
        }
        startAutoRefresh()
    }

    /// Manual refresh
    public func refresh() {
        Task {
            await loadUsage()
        }
    }

    /// Load detailed history for the trend detail window with selected granularity
    public func loadDetailHistory(days: Int) {
        Task {
            if let history = await fetchUsageHistoryUseCase?
                .executeWithGranularity(days: days, granularity: selectedGranularity)
            {
                detailHistory = history
            }
        }
    }

    /// Cleanup on disappear
    public func onDisappear() {
        // Don't stop auto refresh - keep updating in background
    }

    // MARK: - Private

    private func checkSetupAndLoad() async {
        let isConfigured = await getSessionKeyUseCase.isConfigured()

        if !isConfigured {
            state = .needsSetup
            return
        }

        // Always try to pick up fresh tokens from Claude Code on startup
        if let refreshTokenUseCase {
            let result = await refreshTokenUseCase.forceResync()
            if result != nil {
                logger.info("checkSetupAndLoad: picked up fresh token from Claude Code")
            } else {
                logger.debug("checkSetupAndLoad: no new token from Claude Code (same or unavailable)")
            }
        }

        await loadUsage()
    }

    private func loadUsage() async {
        // Prevent concurrent loads (debounce)
        guard !isLoadingUsage else {
            logger.debug("loadUsage: skipped (already loading)")
            return
        }
        isLoadingUsage = true
        defer { isLoadingUsage = false }

        // Cooldown after 429 — don't hit API for at least 30s
        if let lastRL = lastRateLimitedAt, Date().timeIntervalSince(lastRL) < 30 {
            logger.debug("loadUsage: skipped (rate limit cooldown, \(Int(30 - Date().timeIntervalSince(lastRL)))s remaining)")
            return
        }

        logger.info("loadUsage: started (failures=\(self.consecutiveFailures), interval=\(self.currentRefreshInterval)s)")

        // Only show loading spinner on first load (not when refreshing)
        let isFirstLoad = !state.hasData

        if isFirstLoad {
            state = .loading
        }

        do {
            // Refresh OAuth token if needed before API call
            if let refreshTokenUseCase {
                do {
                    _ = try await refreshTokenUseCase.execute()
                } catch let error as TokenRefreshError where error.requiresReauth {
                    logger.warning("loadUsage: token requires re-auth, switching to needsSetup")
                    state = .needsSetup
                    consecutiveFailures = 0
                    return
                } catch let error as TokenRefreshError {
                    if case .refreshFailed(let code) = error, code == 429 {
                        logger.warning("loadUsage: token refresh got 429, trying resync from Claude Code...")
                        if let resynced = await refreshTokenUseCase.forceResync() {
                            logger.info("loadUsage: token refresh 429 → resync got fresh token (prefix=\(String(resynced.accessToken.prefix(15)), privacy: .public))")
                            // Continue to usage API call with fresh token
                        } else {
                            consecutiveFailures += 1
                            lastRateLimitedAt = Date()
                            logger.warning("loadUsage: token refresh 429, no fresh token available, backing off (failures=\(self.consecutiveFailures))")
                            if isFirstLoad {
                                state = .error("Rate limited. Will retry shortly.")
                            }
                            return
                        }
                    }
                    logger.warning("loadUsage: token refresh error (non-fatal): \(error.localizedDescription, privacy: .public)")
                } catch {
                    logger.warning("loadUsage: unknown refresh error (non-fatal): \(error.localizedDescription, privacy: .public)")
                }
            }

            let entities = try await fetchUsageUseCase.execute()
            let displayData = entities.map { UsageDisplayData(from: $0) }
            state = .loaded(displayData)
            lastUpdated = Date()
            consecutiveFailures = 0
            logger.info("loadUsage: success (\(entities.count) usage items)")

            // Fetch extra usage (pay-as-you-go) data
            let extraUsageEntity = await getExtraUsageUseCase?.execute()
            if let extraUsageEntity {
                extraUsage = ExtraUsageDisplayData(from: extraUsageEntity)
            } else {
                extraUsage = nil
            }

            // Save and fetch usage history
            await saveUsageHistoryUseCase?.execute(usages: entities)
            if let history = await fetchUsageHistoryUseCase?.execute(days: 7) {
                usageHistory = history
            }

            // Update widget data (including extra usage)
            widgetDataService?.update(from: entities, extraUsage: extraUsageEntity)

            // Check for threshold notifications
            await checkNotificationUseCase.execute(usages: entities)

            // Fetch Deepgram usage if Voice Input is enabled
            if let prefs = voiceInputPreferences, prefs.isEnabled,
               let keychain = keychainService,
               let apiKey = await keychain.read(forKey: "deepgramApiKey"),
               let useCase = fetchDeepgramUsageUseCase {
                deepgramUsage = try? await useCase.execute(apiKey: apiKey)
            } else {
                deepgramUsage = nil
            }
        } catch let error as DomainError {
            if error == .rateLimited {
                logger.warning("loadUsage: API rate limited (429), trying token refresh...")

                // 1) Try to get a FRESH access_token via refresh_token endpoint
                if let refreshTokenUseCase,
                   let refreshed = await refreshTokenUseCase.forceRefresh() {
                    logger.info("loadUsage: got fresh token via refresh (prefix=\(String(refreshed.accessToken.prefix(15)), privacy: .public)), retrying API call...")
                    do {
                        let entities = try await fetchUsageUseCase.execute()
                        let displayData = entities.map { UsageDisplayData(from: $0) }
                        state = .loaded(displayData)
                        lastUpdated = Date()
                        consecutiveFailures = 0
                        lastRateLimitedAt = nil
                        logger.info("loadUsage: retry after resync SUCCESS (\(entities.count) items)")

                        let extraUsageEntity = await getExtraUsageUseCase?.execute()
                        extraUsage = extraUsageEntity.map { ExtraUsageDisplayData(from: $0) }
                        await saveUsageHistoryUseCase?.execute(usages: entities)
                        if let history = await fetchUsageHistoryUseCase?.execute(days: 7) {
                            usageHistory = history
                        }
                        widgetDataService?.update(from: entities, extraUsage: extraUsageEntity)
                        await checkNotificationUseCase.execute(usages: entities)
                        return
                    } catch {
                        logger.warning("loadUsage: retry after refresh also failed: \(error.localizedDescription, privacy: .public)")
                    }
                }

                // 2) Fallback: check if user did /login (different token in Claude Code keychain)
                if let refreshTokenUseCase,
                   let resynced = await refreshTokenUseCase.forceResync() {
                    logger.info("loadUsage: got different token from Claude Code keychain (prefix=\(String(resynced.accessToken.prefix(15)), privacy: .public)), retrying...")
                    if let entities = try? await fetchUsageUseCase.execute() {
                        let displayData = entities.map { UsageDisplayData(from: $0) }
                        state = .loaded(displayData)
                        lastUpdated = Date()
                        consecutiveFailures = 0
                        lastRateLimitedAt = nil
                        logger.info("loadUsage: retry after keychain resync SUCCESS (\(entities.count) items)")
                        return
                    }
                }

                consecutiveFailures += 1
                lastRateLimitedAt = Date()
                logger.warning("loadUsage: backing off (failures=\(self.consecutiveFailures), next in \(self.currentRefreshInterval)s)")
                if isFirstLoad {
                    state = .error("Rate limited. Will retry shortly.")
                }
                return
            }
            consecutiveFailures += 1
            logger.error("loadUsage: domain error: \(error.localizedDescription, privacy: .public) (failures=\(self.consecutiveFailures))")
            if error == .sessionKeyNotFound {
                state = .needsSetup
            } else if isFirstLoad {
                state = .error(error.localizedDescription)
            }
        } catch {
            consecutiveFailures += 1
            logger.error("loadUsage: error: \(error.localizedDescription, privacy: .public) (failures=\(self.consecutiveFailures))")
            if isFirstLoad {
                state = .error(error.localizedDescription)
            }
        }
    }

    /// Current refresh interval with exponential backoff
    /// On failure: 30s → 60s → 120s → 240s → 300s (cap at normal interval)
    private var currentRefreshInterval: TimeInterval {
        guard consecutiveFailures > 0 else { return baseRefreshInterval }
        let backoffBase: TimeInterval = 30
        let backoff = backoffBase * pow(2.0, Double(min(consecutiveFailures - 1, 4)))
        return min(backoff, baseRefreshInterval)
    }

    private func startAutoRefresh() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                let interval: TimeInterval
                if let self, self.consecutiveFailures > 0 {
                    // In backoff: check for new token every 60s max
                    interval = min(self.currentRefreshInterval, 60)
                } else {
                    interval = self?.baseRefreshInterval ?? 300
                }
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }

                // In backoff: check if Claude Code token changed (e.g. user did /login)
                if let self, self.consecutiveFailures > 0,
                   let refreshTokenUseCase = self.refreshTokenUseCase,
                   let _ = await refreshTokenUseCase.forceResync() {
                    self.logger.info("autoRefresh: new token from Claude Code, resetting backoff")
                    self.consecutiveFailures = 0
                    self.lastRateLimitedAt = nil
                }

                await self?.loadUsage()
            }
        }
    }

    private func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}

// MARK: - Computed Properties

extension UsageViewModel {
    /// Primary usage (session limit)
    public var primaryUsage: UsageDisplayData? {
        state.data.first { $0.type.isPrimary }
    }

    /// Secondary usages (weekly limits)
    public var secondaryUsages: [UsageDisplayData] {
        state.data.filter { !$0.type.isPrimary }
    }

    /// Whether any usage is critical
    public var hasCriticalUsage: Bool {
        state.data.contains { $0.isCritical }
    }

    /// Formatted last updated time
    public var lastUpdatedText: String {
        guard let date = lastUpdated else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Menu Bar Display (VS-13)

    /// Weekly usage (all models)
    public var weeklyUsage: UsageDisplayData? {
        state.data.first { $0.type == .weekly }
    }

    /// Menu bar text: "session/weekly" when both exist, or single value with suffix
    public var menuBarText: String {
        let session = primaryUsage
        let weekly = weeklyUsage

        switch (session, weekly) {
        case let (s?, w?):
            return "\(s.percentage)/\(w.percentage)"
        case let (s?, nil):
            return "\(s.percentage)%"
        case let (nil, w?):
            return "\(w.percentage)%"
        case (nil, nil):
            return "--"
        }
    }

    /// Menu bar status based on max of available usages
    public var menuBarStatus: UsageStatus {
        let session = primaryUsage
        let weekly = weeklyUsage

        let maxPercentage: Int
        switch (session, weekly) {
        case let (s?, w?):
            maxPercentage = max(s.percentage, w.percentage)
        case let (s?, nil):
            maxPercentage = s.percentage
        case let (nil, w?):
            maxPercentage = w.percentage
        case (nil, nil):
            return .safe
        }
        return Percentage.clamped(Double(maxPercentage)).toStatus()
    }

    // MARK: - Clipboard

    /// Copies current usage summary to clipboard
    public func copyToClipboard() {
        var lines: [String] = []
        lines.append("Claude Usage Summary")
        lines.append("---")

        if let session = primaryUsage {
            lines.append("Session (5h): \(session.percentage)%")
        }

        for usage in secondaryUsages {
            let name: String
            switch usage.type {
            case .weekly: name = "Weekly Total"
            case .opus: name = "Opus (7d)"
            case .sonnet: name = "Sonnet (7d)"
            default: name = usage.type.rawValue
            }
            lines.append("\(name): \(usage.percentage)%")
        }

        if let extra = extraUsage {
            lines.append("---")
            lines.append("Pay-as-you-go: \(extra.usageSummary)")
        }

        let text = lines.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
