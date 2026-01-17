import Foundation

/// Settings screen state
enum SettingsState: Equatable {
    /// Checking for Claude Code credentials
    case checking

    /// Claude Code found, ready to sync
    case claudeCodeFound(email: String?)

    /// Claude Code not found
    case claudeCodeNotFound

    /// Key exists, showing masked value
    case hasKey(masked: String)

    /// Syncing credentials from Claude Code
    case syncing

    /// Sync successful
    case success(message: String)

    /// Error occurred
    case error(message: String)

    // MARK: - Computed Properties

    var isLoading: Bool {
        switch self {
        case .checking, .syncing:
            return true
        default:
            return false
        }
    }

    var canSync: Bool {
        if case .claudeCodeFound = self { return true }
        return false
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var isError: Bool {
        if case .error = self { return true }
        return false
    }

    var canRetry: Bool {
        switch self {
        case .claudeCodeNotFound, .error:
            return true
        default:
            return false
        }
    }
}
