import SwiftUI

/// Settings screen view model
@Observable
@MainActor
final class SettingsViewModel {
    // MARK: - State

    private(set) var state: SettingsState = .checking
    var inputKey: String = ""

    // MARK: - Dependencies

    private let claudeCodeSync: ClaudeCodeSyncService
    private let validateUseCase: ValidateSessionKeyUseCase
    private let getSessionKeyUseCase: GetSessionKeyUseCase

    // MARK: - Callbacks

    var onSaveSuccess: (() -> Void)?

    // MARK: - Init

    init(
        claudeCodeSync: ClaudeCodeSyncService,
        validateUseCase: ValidateSessionKeyUseCase,
        getSessionKeyUseCase: GetSessionKeyUseCase
    ) {
        self.claudeCodeSync = claudeCodeSync
        self.validateUseCase = validateUseCase
        self.getSessionKeyUseCase = getSessionKeyUseCase
    }

    // MARK: - Lifecycle

    /// Called when view appears
    func onAppear() async {
        // First check if we already have a valid key
        if let existingKey = await getSessionKeyUseCase.execute() {
            state = .hasKey(masked: existingKey.masked)
            return
        }

        // Check for Claude Code credentials
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
        state = .syncing

        do {
            // Extract session key from Claude Code
            let accessToken = try await claudeCodeSync.extractSessionKey()

            // Validate and save
            _ = try await validateUseCase.execute(rawKey: accessToken)

            state = .success(message: "Successfully connected!")

            // Notify parent to refresh after delay
            try? await Task.sleep(for: .seconds(1.5))
            onSaveSuccess?()

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

    /// Switches to manual entry mode
    func showManualEntry() {
        state = .manualEntry
        inputKey = ""
    }

    /// Saves manually entered key
    func saveManualKey() async {
        let trimmedKey = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKey.isEmpty else {
            state = .error(message: "Please enter a session key")
            return
        }

        state = .validating

        do {
            _ = try await validateUseCase.execute(rawKey: trimmedKey)
            state = .success(message: "Successfully connected!")
            inputKey = ""

            try? await Task.sleep(for: .seconds(1.5))
            onSaveSuccess?()
        } catch let error as DomainError {
            state = .error(message: error.localizedDescription)
        } catch let error as InfrastructureError {
            state = .error(message: error.localizedDescription)
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }

    /// Deletes stored key
    func deleteKey() async {
        await getSessionKeyUseCase.delete()
        await checkClaudeCode()
    }

    /// Cancels manual entry
    func cancelManualEntry() async {
        inputKey = ""
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

    var canSubmitManual: Bool {
        state.showManualEntry && !inputKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
