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
    case rateLimited

    // Admin API errors
    case adminKeyNotFound
    case invalidAdminKeyFormat

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
        case .rateLimited:
            return "Rate limited by API"
        case .adminKeyNotFound:
            return "Admin API key not configured"
        case .invalidAdminKeyFormat:
            return "Invalid Admin API key format. Must start with sk-ant-admin"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .sessionKeyNotFound, .sessionKeyExpired, .invalidSessionKeyFormat, .emptySessionKey:
            return "Please sync from Claude Code in Settings"
        case .rateLimited:
            return "Too many requests. Will retry with backoff"
        case .adminKeyNotFound:
            return "Enter Admin API key in Settings → Organization"
        case .invalidAdminKeyFormat:
            return "Get your Admin API key from console.anthropic.com → Settings → Admin Keys"
        default:
            return nil
        }
    }
}
