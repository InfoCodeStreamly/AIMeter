import AIMeterApplication
import AIMeterDomain
import AIMeterInfrastructure
import AIMeterPresentation
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

    private lazy var networkMonitorService: NetworkMonitorService = {
        NetworkMonitorService()
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

    private lazy var adminAPIClient: AdminAPIClient = {
        AdminAPIClient()
    }()

    private lazy var rateLimitClient: AnthropicRateLimitClient = {
        AnthropicRateLimitClient()
    }()

    lazy var accessibilityService: AccessibilityService = {
        AccessibilityService()
    }()

    lazy var textInsertionService: TextInsertionService = {
        TextInsertionService(accessibilityService: accessibilityService)
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

    private lazy var adminKeyRepository: any AdminKeyRepository = {
        AdminKeyKeychainRepository(keychainService: keychainService)
    }()

    private lazy var orgUsageRepository: any OrgUsageRepository = {
        AdminOrgUsageRepository(adminAPIClient: adminAPIClient, adminKeyRepository: adminKeyRepository)
    }()

    private lazy var apiKeyRepository: any APIKeyRepository = {
        AnthropicAPIKeyKeychainRepository(keychainService: keychainService)
    }()

    private lazy var rateLimitRepository: any RateLimitRepository = {
        AnthropicRateLimitRepository(rateLimitClient: rateLimitClient)
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

    func makeFetchOrgUsageSummaryUseCase() -> FetchOrgUsageSummaryUseCase {
        FetchOrgUsageSummaryUseCase(
            adminKeyRepository: adminKeyRepository,
            orgUsageRepository: orgUsageRepository
        )
    }

    func makeFetchClaudeCodeAnalyticsUseCase() -> FetchClaudeCodeAnalyticsUseCase {
        FetchClaudeCodeAnalyticsUseCase(
            adminKeyRepository: adminKeyRepository,
            orgUsageRepository: orgUsageRepository
        )
    }

    func makeSaveAdminKeyUseCase() -> SaveAdminKeyUseCase {
        SaveAdminKeyUseCase(adminKeyRepository: adminKeyRepository)
    }

    func makeGetAdminKeyUseCase() -> GetAdminKeyUseCase {
        GetAdminKeyUseCase(adminKeyRepository: adminKeyRepository)
    }

    func makeSaveAnthropicAPIKeyUseCase() -> SaveAnthropicAPIKeyUseCase {
        SaveAnthropicAPIKeyUseCase(apiKeyRepository: apiKeyRepository)
    }

    func makeGetAnthropicAPIKeyUseCase() -> GetAnthropicAPIKeyUseCase {
        GetAnthropicAPIKeyUseCase(apiKeyRepository: apiKeyRepository)
    }

    func makeFetchAPIKeyRateLimitsUseCase() -> FetchAPIKeyRateLimitsUseCase {
        FetchAPIKeyRateLimitsUseCase(
            apiKeyRepository: apiKeyRepository,
            rateLimitRepository: rateLimitRepository
        )
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
            keychainService: keychainService,
            networkMonitor: networkMonitorService,
            getAnthropicAPIKeyUseCase: makeGetAnthropicAPIKeyUseCase(),
            getAdminKeyUseCase: makeGetAdminKeyUseCase()
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            claudeCodeSync: claudeCodeSyncService,
            validateUseCase: makeValidateSessionKeyUseCase(),
            getSessionKeyUseCase: makeGetSessionKeyUseCase(),
            credentialsRepository: credentialsRepository,
            saveAdminKeyUseCase: makeSaveAdminKeyUseCase(),
            getAdminKeyUseCase: makeGetAdminKeyUseCase(),
            saveAnthropicAPIKeyUseCase: makeSaveAnthropicAPIKeyUseCase(),
            getAnthropicAPIKeyUseCase: makeGetAnthropicAPIKeyUseCase()
        )
    }

    func makeOrgUsageViewModel() -> OrgUsageViewModel {
        OrgUsageViewModel(
            fetchOrgUsageSummaryUseCase: makeFetchOrgUsageSummaryUseCase(),
            fetchClaudeCodeAnalyticsUseCase: makeFetchClaudeCodeAnalyticsUseCase(),
            getAdminKeyUseCase: makeGetAdminKeyUseCase(),
            fetchAPIKeyRateLimitsUseCase: makeFetchAPIKeyRateLimitsUseCase(),
            getAnthropicAPIKeyUseCase: makeGetAnthropicAPIKeyUseCase(),
            networkMonitor: networkMonitorService
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
            keychainService: keychainService,
            accessibilityService: accessibilityService
        )
    }
}
