import AIMeterApplication
import AIMeterDomain
import AIMeterInfrastructure
import AIMeterPresentation
import Foundation

/// Dependency injection container
@MainActor
final class DependencyContainer {
    static let shared = DependencyContainer()

    private init() {
        // Migrate old keychain items from file-based to Data Protection keychain.
        // File-based keychain has ACL tied to code signature, causing password
        // prompts on every rebuild/update. Data Protection keychain does not.
        Task {
            let keychain = self.keychainService
            await keychain.migrateFromFileBasedKeychain(forKey: "sessionKey")
            await keychain.migrateFromFileBasedKeychain(forKey: "oauthCredentials")
        }
    }

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

    lazy var languageService: LanguageService = {
        LanguageService()
    }()

    lazy var keyboardShortcutService: KeyboardShortcutService = {
        KeyboardShortcutService()
    }()

    lazy var themeService: ThemeService = {
        ThemeService()
    }()

    lazy var widgetDataService: WidgetDataService = {
        WidgetDataService()
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

    private lazy var usageHistoryRepository: any UsageHistoryRepository = {
        UsageHistoryStore()
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

    func makeGetExtraUsageUseCase() -> GetExtraUsageUseCase {
        GetExtraUsageUseCase(usageRepository: usageRepository)
    }

    func makeSaveUsageHistoryUseCase() -> SaveUsageHistoryUseCase {
        SaveUsageHistoryUseCase(historyRepository: usageHistoryRepository)
    }

    func makeFetchUsageHistoryUseCase() -> FetchUsageHistoryUseCase {
        FetchUsageHistoryUseCase(historyRepository: usageHistoryRepository)
    }

    // MARK: - ViewModels

    func makeUsageViewModel() -> UsageViewModel {
        UsageViewModel(
            fetchUsageUseCase: makeFetchUsageUseCase(),
            getSessionKeyUseCase: makeGetSessionKeyUseCase(),
            checkNotificationUseCase: makeCheckNotificationUseCase(),
            refreshTokenUseCase: makeRefreshTokenUseCase(),
            getExtraUsageUseCase: makeGetExtraUsageUseCase(),
            saveUsageHistoryUseCase: makeSaveUsageHistoryUseCase(),
            fetchUsageHistoryUseCase: makeFetchUsageHistoryUseCase(),
            widgetDataService: widgetDataService
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
