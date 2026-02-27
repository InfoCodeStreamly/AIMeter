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
        // Migrate old keychain items from file-based keychain (ACL tied to
        // code signature → password prompt on rebuild/update) to Data
        // Protection keychain (no per-app ACL).
        Task {
            let keychain = self.keychainService
            await keychain.migrateFromACLKeychain(forKey: "sessionKey")
            await keychain.migrateFromACLKeychain(forKey: "oauthCredentials")
            await keychain.migrateFromACLKeychain(forKey: "deepgramApiKey")
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

    private lazy var deepgramTranscriptionService: DeepgramTranscriptionService = {
        DeepgramTranscriptionService()
    }()

    private lazy var deepgramAPIService: DeepgramAPIService = {
        DeepgramAPIService()
    }()

    lazy var textInsertionService: TextInsertionService = {
        TextInsertionService()
    }()

    lazy var voiceInputPreferencesService: VoiceInputPreferencesService = {
        VoiceInputPreferencesService()
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

    private var transcriptionRepository: any TranscriptionRepository {
        deepgramTranscriptionService
    }

    private var deepgramAPIRepository: any DeepgramAPIRepository {
        deepgramAPIService
    }

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

    func makeStartTranscriptionUseCase() -> StartTranscriptionUseCase {
        StartTranscriptionUseCase(transcriptionRepository: transcriptionRepository)
    }

    func makeStopTranscriptionUseCase() -> StopTranscriptionUseCase {
        StopTranscriptionUseCase(transcriptionRepository: transcriptionRepository)
    }

    func makeCancelTranscriptionUseCase() -> CancelTranscriptionUseCase {
        CancelTranscriptionUseCase(transcriptionRepository: transcriptionRepository)
    }

    func makeInsertTextUseCase() -> InsertTextUseCase {
        InsertTextUseCase(textInsertionService: textInsertionService)
    }

    func makeFetchDeepgramBalanceUseCase() -> FetchDeepgramBalanceUseCase {
        FetchDeepgramBalanceUseCase(deepgramAPIRepository: deepgramAPIRepository)
    }

    func makeFetchDeepgramUsageUseCase() -> FetchDeepgramUsageUseCase {
        FetchDeepgramUsageUseCase(deepgramAPIRepository: deepgramAPIRepository)
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
            widgetDataService: widgetDataService,
            fetchDeepgramUsageUseCase: makeFetchDeepgramUsageUseCase(),
            voiceInputPreferences: voiceInputPreferencesService,
            keychainService: keychainService
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

    func makeVoiceInputViewModel() -> VoiceInputViewModel {
        VoiceInputViewModel(
            startTranscriptionUseCase: makeStartTranscriptionUseCase(),
            stopTranscriptionUseCase: makeStopTranscriptionUseCase(),
            cancelTranscriptionUseCase: makeCancelTranscriptionUseCase(),
            insertTextUseCase: makeInsertTextUseCase(),
            fetchBalanceUseCase: makeFetchDeepgramBalanceUseCase(),
            preferencesService: voiceInputPreferencesService,
            keychainService: keychainService
        )
    }
}
