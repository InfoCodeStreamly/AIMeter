import SwiftUI
import OSLog

/// Settings screen view model
@Observable
@MainActor
final class SettingsViewModel {
    private let logger = Logger.sync

    // MARK: - State

    private(set) var state: SettingsState = .checking

    // MARK: - Dependencies

    private let claudeCodeSync: any ClaudeCodeSyncServiceProtocol
    private let validateUseCase: ValidateSessionKeyUseCase
    private let getSessionKeyUseCase: GetSessionKeyUseCase
    private let credentialsRepository: OAuthCredentialsRepository

    // MARK: - Callbacks

    var onSaveSuccess: (() -> Void)?

    // MARK: - Init

    init(
        claudeCodeSync: any ClaudeCodeSyncServiceProtocol,
        validateUseCase: ValidateSessionKeyUseCase,
        getSessionKeyUseCase: GetSessionKeyUseCase,
        credentialsRepository: OAuthCredentialsRepository
    ) {
        self.claudeCodeSync = claudeCodeSync
        self.validateUseCase = validateUseCase
        self.getSessionKeyUseCase = getSessionKeyUseCase
        self.credentialsRepository = credentialsRepository
    }

    // MARK: - Lifecycle

    /// Called when view appears
    func onAppear() async {
        logger.info("📱 SettingsViewModel.onAppear()")

        // First check if we already have a valid key
        if let existingKey = await getSessionKeyUseCase.execute() {
            logger.info("🔑 Found existing key, state = .hasKey")
            state = .hasKey(masked: existingKey.masked)
            return
        }

        logger.info("🔍 No existing key, checking Claude Code...")
        await checkClaudeCode()
    }

    // MARK: - Actions

    /// Checks for Claude Code credentials in system Keychain
    func checkClaudeCode() async {
        state = .checking

        let hasCredentials = await claudeCodeSync.hasCredentials()

        if hasCredentials {
            let info = await claudeCodeSync.getSubscriptionInfo()
            state = .claudeCodeFound(email: info?.email)
        } else {
            state = .claudeCodeNotFound
        }
    }

    /// Syncs credentials from Claude Code
    func syncFromClaudeCode() async {
        logger.info("🔄 Starting sync from Claude Code...")
        state = .syncing

        do {
            // Extract full OAuth credentials from Claude Code
            logger.info("📥 Extracting OAuth credentials...")
            let oauthCredentials = try await claudeCodeSync.extractOAuthCredentials()
            logger.info("✅ Extracted credentials, token expires: \(oauthCredentials.expiresAt)")

            // Validate the token
            logger.info("🔐 Validating token...")
            _ = try await validateUseCase.execute(rawKey: oauthCredentials.accessToken)
            logger.info("✅ Token validated")

            // Save full OAuth credentials for token refresh
            logger.info("💾 Saving OAuth credentials to keychain...")
            try await credentialsRepository.saveOAuthCredentials(oauthCredentials)
            logger.info("✅ OAuth credentials saved!")

            state = .success(message: "Successfully connected!")

            // Notify parent to refresh after delay
            try? await Task.sleep(for: .seconds(1.5))
            onSaveSuccess?()

            // Transition to hasKey state so disconnect button appears
            if let key = await getSessionKeyUseCase.execute() {
                state = .hasKey(masked: key.masked)
            }

        } catch let error as ClaudeCodeSyncError {
            state = .error(message: error.localizedDescription)
        } catch let error as DomainError {
            state = .error(message: error.localizedDescription)
        } catch let error as InfrastructureError {
            state = .error(message: error.localizedDescription)
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }

    /// Deletes stored key and credentials
    func deleteKey() async {
        await getSessionKeyUseCase.delete()
        await checkClaudeCode()
    }

    /// Clears error and retries
    func retry() async {
        await checkClaudeCode()
    }
}

// MARK: - Computed Properties

extension SettingsViewModel {
    var statusMessage: String? {
        switch state {
        case .success(let msg), .error(let msg):
            return msg
        default:
            return nil
        }
    }

    var statusColor: Color {
        switch state {
        case .success:
            return .green
        case .error:
            return .red
        default:
            return .secondary
        }
    }
}
