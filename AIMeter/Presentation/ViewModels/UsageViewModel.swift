import SwiftUI

/// ViewModel for usage display
@MainActor
@Observable
final class UsageViewModel {
    private(set) var state: UsageViewState = .loading
    private(set) var lastUpdated: Date?

    private let fetchUsageUseCase: FetchUsageUseCase
    private let getSessionKeyUseCase: GetSessionKeyUseCase
    private let checkNotificationUseCase: CheckNotificationUseCase
    private let refreshTokenUseCase: RefreshTokenUseCase?

    private var refreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 60 // 1 minute

    init(
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

    /// Initial load
    func onAppear() {
        Task {
            await checkSetupAndLoad()
        }
        startAutoRefresh()
    }

    /// Manual refresh
    func refresh() {
        Task {
            await loadUsage()
        }
    }

    /// Cleanup on disappear
    func onDisappear() {
        stopAutoRefresh()
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
    var primaryUsage: UsageDisplayData? {
        state.data.first { $0.type.isPrimary }
    }

    /// Secondary usages (weekly limits)
    var secondaryUsages: [UsageDisplayData] {
        state.data.filter { !$0.type.isPrimary }
    }

    /// Whether any usage is critical
    var hasCriticalUsage: Bool {
        state.data.contains { $0.isCritical }
    }

    /// Formatted last updated time
    var lastUpdatedText: String {
        guard let date = lastUpdated else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Menu Bar Display (VS-13)

    /// Weekly usage (all models)
    var weeklyUsage: UsageDisplayData? {
        state.data.first { $0.type == .weekly }
    }

    /// Menu bar text "70/30" format (session/weekly)
    var menuBarText: String {
        guard let session = primaryUsage,
              let weekly = weeklyUsage else { return "--/--" }
        return "\(session.percentage)/\(weekly.percentage)"
    }

    /// Menu bar status based on max(session, weekly)
    var menuBarStatus: UsageStatus {
        guard let session = primaryUsage,
              let weekly = weeklyUsage else { return .safe }
        let maxPercentage = max(session.percentage, weekly.percentage)
        return Percentage.clamped(Double(maxPercentage)).toStatus()
    }
}
