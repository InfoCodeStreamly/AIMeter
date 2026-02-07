import Foundation

/// Time granularity for usage history chart display
public enum TimeGranularity: Int, CaseIterable, Sendable, Codable {
    case fifteenMinutes = 15
    case oneHour = 60
    case threeHours = 180
    case sixHours = 360
}
