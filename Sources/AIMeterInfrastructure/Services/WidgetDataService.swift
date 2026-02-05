import Foundation
import AIMeterDomain
import WidgetKit

/// Shared data structure for widget
public struct WidgetData: Codable, Sendable {
    public let sessionPercentage: Int
    public let weeklyPercentage: Int
    public let lastUpdated: Date
    public let sessionStatus: String
    public let weeklyStatus: String
    public let sessionResetDate: Date?
    public let weeklyResetDate: Date?

    public init(
        sessionPercentage: Int,
        weeklyPercentage: Int,
        lastUpdated: Date,
        sessionStatus: UsageStatus,
        weeklyStatus: UsageStatus,
        sessionResetDate: Date? = nil,
        weeklyResetDate: Date? = nil
    ) {
        self.sessionPercentage = sessionPercentage
        self.weeklyPercentage = weeklyPercentage
        self.lastUpdated = lastUpdated
        self.sessionStatus = sessionStatus.rawValue
        self.weeklyStatus = weeklyStatus.rawValue
        self.sessionResetDate = sessionResetDate
        self.weeklyResetDate = weeklyResetDate
    }

    /// Creates widget data from usage entities
    public static func from(usages: [UsageEntity]) -> WidgetData? {
        guard let session = usages.first(where: { $0.type == .session }),
              let weekly = usages.first(where: { $0.type == .weekly }) else {
            return nil
        }

        return WidgetData(
            sessionPercentage: Int(session.percentage.value),
            weeklyPercentage: Int(weekly.percentage.value),
            lastUpdated: Date(),
            sessionStatus: session.status,
            weeklyStatus: weekly.status,
            sessionResetDate: session.resetTime.date,
            weeklyResetDate: weekly.resetTime.date
        )
    }
}

/// Service for sharing data between main app and widget via App Group
@MainActor
public final class WidgetDataService {
    /// App Group identifier - must match entitlements
    public static let appGroupIdentifier = "group.com.codestreamly.AIMeter"
    private static let dataKey = "widgetData"

    private let defaults: UserDefaults?

    public init() {
        defaults = UserDefaults(suiteName: Self.appGroupIdentifier)
    }

    /// Saves widget data to shared container and triggers widget refresh
    public func save(_ data: WidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults?.set(encoded, forKey: Self.dataKey)

        // Trigger widget to refresh immediately
        WidgetCenter.shared.reloadTimelines(ofKind: "AIMeterWidget")
    }

    /// Loads widget data from shared container
    public func load() -> WidgetData? {
        guard let data = defaults?.data(forKey: Self.dataKey) else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }

    /// Updates widget data from usage entities
    public func update(from usages: [UsageEntity]) {
        guard let data = WidgetData.from(usages: usages) else { return }
        save(data)
    }
}
