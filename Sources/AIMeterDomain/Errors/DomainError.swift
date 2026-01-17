import Foundation

/// Domain-specific errors
public enum DomainError: LocalizedError, Sendable, Equatable {
    // Value Object validation errors
    case invalidPercentage(Double)
    case emptySessionKey
    case invalidSessionKeyFormat

    // Business rule errors
    case sessionKeyNotFound
    case sessionKeyExpired

    public var errorDescription: String? {
        switch self {
        case .invalidPercentage(let value):
            return "Invalid percentage: \(value). Must be 0-100."
        case .emptySessionKey:
            return "Session key cannot be empty"
        case .invalidSessionKeyFormat:
            return "Invalid session key format"
        case .sessionKeyNotFound:
            return "Session key not found"
        case .sessionKeyExpired:
            return "Session key has expired"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .sessionKeyNotFound, .sessionKeyExpired, .invalidSessionKeyFormat, .emptySessionKey:
            return "Please sync from Claude Code in Settings"
        default:
            return nil
        }
    }
}
