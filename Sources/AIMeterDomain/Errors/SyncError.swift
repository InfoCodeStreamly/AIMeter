import Foundation

/// Errors related to Claude Code credential synchronization
public enum SyncError: LocalizedError, Sendable {
    case noCredentialsFound
    case invalidCredentialsFormat
    case emptyAccessToken
    case keychainAccessFailed(status: OSStatus)
    case keychainWriteFailed(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .noCredentialsFound:
            return "Claude Code not logged in. Please run 'claude' in terminal and login first."
        case .invalidCredentialsFormat:
            return "Claude Code credentials are corrupted."
        case .emptyAccessToken:
            return "Claude Code session expired. Please re-login in terminal."
        case .keychainAccessFailed(let status):
            return "Cannot access Keychain (error \(status)). Check System Preferences → Security."
        case .keychainWriteFailed(let status):
            return "Cannot write to Keychain (error \(status)). Check app permissions."
        }
    }
}
