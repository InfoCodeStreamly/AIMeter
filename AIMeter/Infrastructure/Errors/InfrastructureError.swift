import Foundation

/// Infrastructure layer errors
enum InfrastructureError: LocalizedError, Sendable {
    // Network errors
    case networkUnavailable
    case invalidURL(String)
    case requestFailed(statusCode: Int)
    case decodingFailed(Error)
    case unauthorized

    // Keychain errors
    case keychainSaveFailed(OSStatus)
    case keychainReadFailed(OSStatus)
    case keychainDeleteFailed(OSStatus)
    case keychainItemNotFound

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network is unavailable"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .requestFailed(let code):
            return "Request failed with status: \(code)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "OAuth token is invalid or expired"
        case .keychainSaveFailed(let status):
            return "Failed to save to Keychain: \(status)"
        case .keychainReadFailed(let status):
            return "Failed to read from Keychain: \(status)"
        case .keychainDeleteFailed(let status):
            return "Failed to delete from Keychain: \(status)"
        case .keychainItemNotFound:
            return "Item not found in Keychain"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection"
        case .unauthorized:
            return "Please re-sync from Claude Code in Settings"
        case .requestFailed(let code) where code == 429:
            return "Rate limited. Please wait before retrying"
        default:
            return nil
        }
    }
}
