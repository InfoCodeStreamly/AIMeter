import SwiftUI

/// Presentation model for usage display
struct UsageDisplayData: Identifiable, Equatable {
    let id: UUID
    let type: UsageType
    let percentage: Int
    let countdown: String
    let status: UsageStatus
    let title: String
    let subtitle: String

    /// Creates display data from domain entity
    init(from entity: UsageEntity) {
        self.id = entity.id
        self.type = entity.type
        self.percentage = Int(entity.percentage.value)
        self.countdown = entity.resetTime.countdown
        self.status = entity.status
        self.title = entity.type.displayName
        self.subtitle = entity.type.subtitle
    }

    /// Color for progress indicator
    var color: Color {
        status.color
    }

    /// Formatted percentage string
    var percentageText: String {
        "\(percentage)%"
    }

    /// Icon name for status
    var icon: String {
        status.icon
    }

    /// Whether this is critical usage
    var isCritical: Bool {
        status == .critical
    }
}

/// State of the usage view
enum UsageViewState: Equatable {
    case loading
    case loaded([UsageDisplayData])
    case error(String)
    case needsSetup

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var data: [UsageDisplayData] {
        if case .loaded(let data) = self { return data }
        return []
    }

    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }

    var hasData: Bool {
        if case .loaded(let data) = self { return !data.isEmpty }
        return false
    }
}
