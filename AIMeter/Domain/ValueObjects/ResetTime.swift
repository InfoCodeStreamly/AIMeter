import Foundation

/// Reset time with countdown formatting
struct ResetTime: Sendable, Equatable, Codable {
    let date: Date

    nonisolated init(_ date: Date) {
        self.date = date
    }

    /// Parses ISO8601 date string
    nonisolated static func fromISO8601(_ string: String) -> ResetTime? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return ResetTime(date)
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: string) else { return nil }
        return ResetTime(date)
    }

    /// Countdown string (e.g., "2h 30m" or "45m")
    var countdown: String {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return "Now" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Whether reset time has passed
    var isExpired: Bool { date <= Date() }

    /// Default 5-hour session reset
    nonisolated static var defaultSession: ResetTime {
        ResetTime(Date().addingTimeInterval(5 * 3600))
    }

    /// Default weekly reset (next Monday)
    nonisolated static var defaultWeekly: ResetTime {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = 2
        components.hour = 12
        components.minute = 59
        let date = calendar.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        ) ?? Date()
        return ResetTime(date)
    }
}
