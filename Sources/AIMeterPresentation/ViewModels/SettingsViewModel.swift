import AIMeterApplication
import AIMeterDomain
import OSLog
import SwiftUI

/// Settings screen view model
@Observable
@MainActor
public final class SettingsViewModel {
    private let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "settings-vm")

    // MARK: - State

    public private(set) var state: SettingsState = .checking

    // MARK: - Dependencies

    private let claudeCodeSync: any ClaudeCodeSyncServiceProtocol
    private let validateUseCase: ValidateSessionKeyUseCase
    private let getSessionKeyUseCase: GetSessionKeyUseCase
    private let credentialsRepository: OAuthCredentialsRepository

    // MARK: - Callbacks

    public var onSaveSuccess: (() -> Void)?

    // MARK: - Init

    public init(
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
    public func onAppear() async {

        // First check if we already have a valid key
        if let existingKey = await getSessionKeyUseCase.execute() {
            state = .hasKey(masked: existingKey.masked)
            return
        }

        await checkClaudeCode()
    }

    // MARK: - Actions

    /// Checks for Claude Code credentials in system Keychain
    public func checkClaudeCode() async {
        state = .checking
        logger.info("checkClaudeCode: checking keychain...")

        let hasCredentials = await claudeCodeSync.hasCredentials()

        if hasCredentials {
            let info = await claudeCodeSync.getSubscriptionInfo()
            logger.info("checkClaudeCode: found credentials (email=\(info?.email ?? "nil", privacy: .private))")
            state = .claudeCodeFound(email: info?.email)
        } else {
            logger.info("checkClaudeCode: no credentials found")
            state = .claudeCodeNotFound
        }
    }

    /// Syncs credentials from Claude Code
    public func syncFromClaudeCode() async {
        logger.info("syncFromClaudeCode: started")
        state = .syncing

        do {
            let oauthCredentials = try await claudeCodeSync.extractOAuthCredentials()
            logger.info("syncFromClaudeCode: extracted credentials, saving...")

            try await credentialsRepository.saveOAuthCredentials(oauthCredentials)
            logger.info("syncFromClaudeCode: credentials saved successfully")

            state = .success(message: "Successfully connected!")

            try? await Task.sleep(for: .seconds(1.5))
            onSaveSuccess?()
            logger.info("syncFromClaudeCode: onSaveSuccess callback fired")

            if let key = await getSessionKeyUseCase.execute() {
                state = .hasKey(masked: key.masked)
            }

        } catch let error as SyncError {
            logger.error("syncFromClaudeCode: SyncError: \(error.localizedDescription)")
            state = .error(message: error.localizedDescription)
        } catch let error as DomainError {
            logger.error("syncFromClaudeCode: DomainError: \(error.localizedDescription)")
            state = .error(message: error.localizedDescription)
        } catch {
            logger.error("syncFromClaudeCode: error: \(error.localizedDescription)")
            state = .error(message: error.localizedDescription)
        }
    }

    /// Deletes stored key and credentials
    public func deleteKey() async {
        logger.info("deleteKey: disconnecting...")
        await getSessionKeyUseCase.delete()
        logger.info("deleteKey: credentials deleted, checking Claude Code state")
        await checkClaudeCode()
    }

    /// Clears error and retries
    public func retry() async {
        await checkClaudeCode()
    }
}

// MARK: - Computed Properties

extension SettingsViewModel {
    public var statusMessage: String? {
        switch state {
        case .success(let msg), .error(let msg):
            return msg
        default:
            return nil
        }
    }

    public var statusColor: Color {
        switch state {
        case .success:
            return AccessibleColors.success
        case .error:
            return .red
        default:
            return .secondary
        }
    }
}
