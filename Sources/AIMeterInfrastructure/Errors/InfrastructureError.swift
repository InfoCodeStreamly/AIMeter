import Foundation

/// Infrastructure layer errors
public enum InfrastructureError: LocalizedError, Sendable {
    case networkUnavailable
    case invalidURL(String)
    case requestFailed(statusCode: Int)
    case decodingFailed(Error)
    case unauthorized
    case keychainSaveFailed(OSStatus)
    case keychainReadFailed(OSStatus)
    case keychainDeleteFailed(OSStatus)
    case keychainItemNotFound

    public var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "Network is unavailable"
        case .invalidURL(let url): return "Invalid URL: \(url)"
        case .requestFailed(let code): return "Request failed with status: \(code)"
        case .decodingFailed(let error): return "Failed to decode: \(error.localizedDescription)"
        case .unauthorized: return "OAuth token is invalid or expired"
        case .keychainSaveFailed(let status): return "Failed to save to Keychain: \(status)"
        case .keychainReadFailed(let status): return "Failed to read from Keychain: \(status)"
        case .keychainDeleteFailed(let status): return "Failed to delete from Keychain: \(status)"
        case .keychainItemNotFound: return "Item not found in Keychain"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable: return "Check your internet connection"
        case .unauthorized: return "Please re-sync from Claude Code in Settings"
        case .requestFailed(let code) where code == 429: return "Rate limited. Please wait"
        default: return nil
        }
    }
}
