import SwiftUI
import AIMeterDomain

/// Presentation model for usage display
public struct UsageDisplayData: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let type: UsageType
    public let percentage: Int
    public let resetDate: Date
    public let status: UsageStatus

    public init(from entity: UsageEntity) {
        self.id = entity.id
        self.type = entity.type
        self.percentage = Int(entity.percentage.value)
        self.resetDate = entity.resetTime.date
        self.status = entity.status
    }

    public var color: Color { status.color }
    public var percentageText: String { "\(percentage)%" }
    public var icon: String { status.icon }
    public var isCritical: Bool { status == .critical }
}

/// State of the usage view
public enum UsageViewState: Equatable, Sendable {
    case loading
    case loaded([UsageDisplayData])
    case error(String)
    case needsSetup

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var data: [UsageDisplayData] {
        if case .loaded(let data) = self { return data }
        return []
    }

    public var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }

    public var hasData: Bool {
        if case .loaded(let data) = self { return !data.isEmpty }
        return false
    }
}
