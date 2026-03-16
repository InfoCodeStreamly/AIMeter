import Foundation

/// Admin API key state
public enum AdminKeyState: Equatable, Sendable {
    /// No admin key configured
    case noKey

    /// Key exists, showing masked value
    case hasKey(masked: String)

    /// Testing the key
    case testing

    /// Key validated successfully
    case valid

    /// Error occurred
    case error(String)

    // MARK: - Computed Properties

    public var isLoading: Bool {
        if case .testing = self { return true }
        return false
    }

    public var canSave: Bool {
        switch self {
        case .noKey, .error:
            return true
        default:
            return false
        }
    }
}

/// API key state (personal Anthropic API key)
public enum APIKeyState: Equatable, Sendable {
    /// No API key configured
    case noKey

    /// Key exists, showing masked value
    case hasKey(masked: String)

    /// Testing the key
    case testing

    /// Error occurred
    case error(String)

    // MARK: - Computed Properties

    public var isLoading: Bool {
        if case .testing = self { return true }
        return false
    }

    public var canSave: Bool {
        switch self {
        case .noKey, .error:
            return true
        default:
            return false
        }
    }
}

/// Settings screen state
public enum SettingsState: Equatable {
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

    public var isLoading: Bool {
        switch self {
        case .checking, .syncing:
            return true
        default:
            return false
        }
    }

    public var canSync: Bool {
        if case .claudeCodeFound = self { return true }
        return false
    }

    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    public var isError: Bool {
        if case .error = self { return true }
        return false
    }

    public var canRetry: Bool {
        switch self {
        case .claudeCodeNotFound, .error:
            return true
        default:
            return false
        }
    }
}
