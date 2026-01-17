import SwiftUI
import AIMeterDomain
import AIMeterApplication
import AIMeterInfrastructure

/// ViewModel for usage display
@MainActor
@Observable
public final class UsageViewModel {
    public private(set) var state: UsageViewState = .loading
    public private(set) var lastUpdated: Date?

    private let fetchUsageUseCase: FetchUsageUseCase
    private let getSessionKeyUseCase: GetSessionKeyUseCase
    private let checkNotificationUseCase: CheckNotificationUseCase
    private let refreshTokenUseCase: RefreshTokenUseCase?

    private var refreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 60 // 1 minute

    public init(
        fetchUsageUseCase: FetchUsageUseCase,
        getSessionKeyUseCase: GetSessionKeyUseCase,
        checkNotificationUseCase: CheckNotificationUseCase,
        refreshTokenUseCase: RefreshTokenUseCase? = nil
    ) {
        self.fetchUsageUseCase = fetchUsageUseCase
        self.getSessionKeyUseCase = getSessionKeyUseCase
        self.checkNotificationUseCase = checkNotificationUseCase
        self.refreshTokenUseCase = refreshTokenUseCase
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
        Task {
            await checkSetupAndLoad()
        }
        // Auto refresh is already running from startBackgroundRefresh
        if refreshTask == nil {
            startAutoRefresh()
        }
    }

    /// Manual refresh
    public func refresh() {
        Task {
            await loadUsage()
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
                    return
                } catch {
                    // Non-fatal refresh error - try the API call anyway
                    // The token might still be valid
                }
            }

            let entities = try await fetchUsageUseCase.execute()
            let displayData = entities.map { UsageDisplayData(from: $0) }
            state = .loaded(displayData)
            lastUpdated = Date()

            // Check for threshold notifications
            await checkNotificationUseCase.execute(usages: entities)
        } catch let error as DomainError {
            if error == .sessionKeyNotFound {
                state = .needsSetup
            } else if isFirstLoad {
                // Only show error on first load
                state = .error(error.localizedDescription)
            }
        } catch {
            if isFirstLoad {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func startAutoRefresh() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.refreshInterval ?? 60))
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

    /// Menu bar text "70/30" format (session/weekly)
    public var menuBarText: String {
        guard let session = primaryUsage,
              let weekly = weeklyUsage else { return "--/--" }
        return "\(session.percentage)/\(weekly.percentage)"
    }

    /// Menu bar status based on max(session, weekly)
    public var menuBarStatus: UsageStatus {
        guard let session = primaryUsage,
              let weekly = weeklyUsage else { return .safe }
        let maxPercentage = max(session.percentage, weekly.percentage)
        return Percentage.clamped(Double(maxPercentage)).toStatus()
    }
}
