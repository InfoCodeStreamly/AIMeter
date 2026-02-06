import AIMeterApplication
import AIMeterDomain
import AIMeterInfrastructure
import SwiftUI

/// Settings screen view model
@Observable
@MainActor
public final class SettingsViewModel {

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

        let hasCredentials = await claudeCodeSync.hasCredentials()

        if hasCredentials {
            let info = await claudeCodeSync.getSubscriptionInfo()
            state = .claudeCodeFound(email: info?.email)
        } else {
            state = .claudeCodeNotFound
        }
    }

    /// Syncs credentials from Claude Code
    public func syncFromClaudeCode() async {
        state = .syncing

        do {
            // Extract full OAuth credentials from Claude Code
            let oauthCredentials = try await claudeCodeSync.extractOAuthCredentials()

            // Validate the token
            _ = try await validateUseCase.execute(rawKey: oauthCredentials.accessToken)

            // Save full OAuth credentials for token refresh
            try await credentialsRepository.saveOAuthCredentials(oauthCredentials)

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
    public func deleteKey() async {
        await getSessionKeyUseCase.delete()
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
