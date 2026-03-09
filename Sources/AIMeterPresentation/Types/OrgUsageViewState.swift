import Foundation

/// State of the organization usage view
public enum OrgUsageViewState: Equatable, Sendable {
    case noKey
    case loading
    case loaded
    case error(String)

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var hasData: Bool {
        if case .loaded = self { return true }
        return false
    }

    public var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }

    public var isNoKey: Bool {
        if case .noKey = self { return true }
        return false
    }
}
