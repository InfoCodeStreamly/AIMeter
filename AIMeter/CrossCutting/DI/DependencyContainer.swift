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


    private lazy var tokenRefreshService: TokenRefreshService = {
        TokenRefreshService()
    }()

    // MARK: - Repositories

    private lazy var keychainSessionRepository: KeychainSessionRepository = {
        KeychainSessionRepository(
            keychainService: keychainService,
            apiClient: apiClient,
            claudeCodeSyncService: claudeCodeSyncService
        )
    }()

    private var sessionKeyRepository: any SessionKeyRepository {
        keychainSessionRepository
    }

    private var credentialsRepository: any OAuthCredentialsRepository {
        keychainSessionRepository
    }

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


    func makeRefreshTokenUseCase() -> RefreshTokenUseCase {
        RefreshTokenUseCase(
            credentialsRepository: credentialsRepository,
            tokenRefreshService: tokenRefreshService
        )
    }

    // MARK: - ViewModels

    func makeUsageViewModel() -> UsageViewModel {
        UsageViewModel(
            fetchUsageUseCase: makeFetchUsageUseCase(),
            getSessionKeyUseCase: makeGetSessionKeyUseCase(),
            checkNotificationUseCase: makeCheckNotificationUseCase(),
            refreshTokenUseCase: makeRefreshTokenUseCase()
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            claudeCodeSync: claudeCodeSyncService,
            validateUseCase: makeValidateSessionKeyUseCase(),
            getSessionKeyUseCase: makeGetSessionKeyUseCase(),
            credentialsRepository: credentialsRepository
        )
    }
}
