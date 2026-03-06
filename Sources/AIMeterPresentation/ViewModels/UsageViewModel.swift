import AIMeterApplication
import AIMeterDomain
import AppKit
import SwiftUI

/// ViewModel for usage display
@MainActor
@Observable
public final class UsageViewModel {
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

    private var refreshTask: Task<Void, Never>?
    private let baseRefreshInterval: TimeInterval = 300  // 5 minutes
    private var consecutiveFailures: Int = 0
    private let maxBackoffInterval: TimeInterval = 900  // 15 minutes
    private var isLoadingUsage = false

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
        keychainService: (any KeychainServiceProtocol)? = nil
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
    }

    /// Start background refresh (called once at app launch)
    public func startBackgroundRefresh() async {
        // Only start once
        guard refreshTask == nil else { return }

        await checkSetupAndLoad()
        startAutoRefresh()
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

        await loadUsage()
    }

    private func loadUsage() async {
        // Prevent concurrent loads (debounce)
        guard !isLoadingUsage else { return }
        isLoadingUsage = true
        defer { isLoadingUsage = false }

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
                    // Token refresh failed - user needs to re-authenticate
                    state = .needsSetup
                    consecutiveFailures = 0
                    return
                } catch let error as TokenRefreshError {
                    if case .refreshFailed(let code) = error, code == 429 {
                        // Rate limited — skip API call, back off
                        consecutiveFailures += 1
                        return
                    }
                    // Other non-fatal errors — try API call anyway
                } catch {
                    // Unknown refresh error — try API call anyway
                }
            }

            let entities = try await fetchUsageUseCase.execute()
            let displayData = entities.map { UsageDisplayData(from: $0) }
            state = .loaded(displayData)
            lastUpdated = Date()
            consecutiveFailures = 0  // Reset backoff on success

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
            consecutiveFailures += 1
            if error == .sessionKeyNotFound {
                state = .needsSetup
            } else if isFirstLoad {
                state = .error(error.localizedDescription)
            }
        } catch {
            consecutiveFailures += 1
            if isFirstLoad {
                state = .error(error.localizedDescription)
            }
        }
    }

    /// Current refresh interval with exponential backoff
    private var currentRefreshInterval: TimeInterval {
        guard consecutiveFailures > 0 else { return baseRefreshInterval }
        // 60s → 120s → 240s → 300s (max)
        let backoff = baseRefreshInterval * pow(2.0, Double(min(consecutiveFailures, 3)))
        return min(backoff, maxBackoffInterval)
    }

    private func startAutoRefresh() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                let interval = self?.currentRefreshInterval ?? 60
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
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
