import Foundation
import AIMeterDomain
import AIMeterInfrastructure

/// Application-wide error type
enum AppError: LocalizedError, Sendable {
    case domain(DomainError)
    case infrastructure(InfrastructureError)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .domain(let error):
            return error.errorDescription
        case .infrastructure(let error):
            return error.errorDescription
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .domain(let error):
            return error.recoverySuggestion
        case .infrastructure(let error):
            return error.recoverySuggestion
        case .unknown:
            return "Please try again"
        }
    }

    /// Creates AppError from any error
    static func from(_ error: Error) -> AppError {
        switch error {
        case let domainError as DomainError:
            return .domain(domainError)
        case let infraError as InfrastructureError:
            return .infrastructure(infraError)
        case let appError as AppError:
            return appError
        default:
            return .unknown(error)
        }
    }

    /// Whether this error requires re-authentication
    var requiresReauth: Bool {
        switch self {
        case .domain(let error):
            switch error {
            case .sessionKeyNotFound, .sessionKeyExpired, .invalidSessionKeyFormat:
                return true
            default:
                return false
            }
        case .infrastructure(let error):
            if case .unauthorized = error {
                return true
            }
            return false
        case .unknown:
            return false
        }
    }
}
