import Foundation

/// Dependency injection container
@MainActor
final class DependencyContainer {
    static let shared = DependencyContainer()

    private init() {}

    // MARK: - Infrastructure

    private lazy var keychainService: KeychainService = {
        KeychainService()
    }()

    private lazy var apiClient: ClaudeAPIClient = {
        ClaudeAPIClient()
    }()

    private lazy var claudeCodeSyncService: ClaudeCodeSyncService = {
        ClaudeCodeSyncService()
    }()

    lazy var launchAtLoginService: LaunchAtLoginService = {
        LaunchAtLoginService()
    }()

    private lazy var notificationService: NotificationService = {
        NotificationService()
    }()

    lazy var notificationPreferencesService: NotificationPreferencesService = {
        NotificationPreferencesService()
    }()

    lazy var appInfoService: AppInfoService = {
        AppInfoService()
    }()

    private lazy var gitHubUpdateService: GitHubUpdateService = {
        GitHubUpdateService()
    }()

    // MARK: - Repositories

    private lazy var sessionKeyRepository: any SessionKeyRepository = {
        KeychainSessionRepository(
            keychainService: keychainService,
            apiClient: apiClient
        )
    }()

    private lazy var usageRepository: any UsageRepository = {
        ClaudeUsageRepository(
            apiClient: apiClient,
            keychainService: keychainService
        )
    }()

    // MARK: - Use Cases

    func makeFetchUsageUseCase() -> FetchUsageUseCase {
        FetchUsageUseCase(
            usageRepository: usageRepository,
            sessionKeyRepository: sessionKeyRepository
        )
    }

    func makeSaveSessionKeyUseCase() -> SaveSessionKeyUseCase {
        SaveSessionKeyUseCase(
            sessionKeyRepository: sessionKeyRepository
        )
    }

    func makeGetSessionKeyUseCase() -> GetSessionKeyUseCase {
        GetSessionKeyUseCase(
            sessionKeyRepository: sessionKeyRepository
        )
    }

    func makeValidateSessionKeyUseCase() -> ValidateSessionKeyUseCase {
        ValidateSessionKeyUseCase(
            sessionKeyRepository: sessionKeyRepository
        )
    }

    func makeCheckNotificationUseCase() -> CheckNotificationUseCase {
        CheckNotificationUseCase(
            notificationService: notificationService,
            preferencesService: notificationPreferencesService
        )
    }

    func makeCheckForUpdatesUseCase() -> CheckForUpdatesUseCase {
        CheckForUpdatesUseCase(
            appInfoService: appInfoService,
            gitHubUpdateService: gitHubUpdateService
        )
    }

    // MARK: - ViewModels

    func makeUsageViewModel() -> UsageViewModel {
        UsageViewModel(
            fetchUsageUseCase: makeFetchUsageUseCase(),
            getSessionKeyUseCase: makeGetSessionKeyUseCase(),
            checkNotificationUseCase: makeCheckNotificationUseCase()
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            claudeCodeSync: claudeCodeSyncService,
            validateUseCase: makeValidateSessionKeyUseCase(),
            getSessionKeyUseCase: makeGetSessionKeyUseCase()
        )
    }
}
