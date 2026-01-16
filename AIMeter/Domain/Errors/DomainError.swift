import Foundation

/// Domain-specific errors
enum DomainError: LocalizedError, Sendable, Equatable {
    // Value Object validation errors
    case invalidPercentage(Double)
    case emptySessionKey
    case invalidSessionKeyFormat
    case invalidOrganizationId(String)

    // Business rule errors
    case sessionKeyNotFound
    case sessionKeyExpired
    case organizationNotFound

    var errorDescription: String? {
        switch self {
        case .invalidPercentage(let value):
            return "Invalid percentage: \(value). Must be 0-100."
        case .emptySessionKey:
            return "Session key cannot be empty"
        case .invalidSessionKeyFormat:
            return "Invalid session key format"
        case .invalidOrganizationId(let id):
            return "Invalid organization ID: \(id)"
        case .sessionKeyNotFound:
            return "Session key not found"
        case .sessionKeyExpired:
            return "Session key has expired"
        case .organizationNotFound:
            return "No organization found for this account"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .sessionKeyNotFound, .sessionKeyExpired, .invalidSessionKeyFormat, .emptySessionKey:
            return "Enter a valid session key in Settings"
        case .organizationNotFound:
            return "Make sure you have a Claude Pro subscription"
        default:
            return nil
        }
    }
}
