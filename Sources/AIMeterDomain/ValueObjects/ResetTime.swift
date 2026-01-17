import Foundation

/// Reset time with countdown formatting
public struct ResetTime: Sendable, Equatable, Codable {
    public let date: Date

    public nonisolated init(_ date: Date) {
        self.date = date
    }

    /// Parses ISO8601 date string, rounding UP to nearest minute
    public nonisolated static func fromISO8601(_ string: String) -> ResetTime? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return ResetTime(roundUpToMinute(date))
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        guard let date = formatter.date(from: string) else { return nil }
        return ResetTime(roundUpToMinute(date))
    }

    /// Rounds date UP to the nearest minute (ceiling)
    /// This prevents UI from jumping between "3:59pm" and "4:00pm" when API returns
    /// times like 13:59:59.689 vs 14:00:00.220
    private nonisolated static func roundUpToMinute(_ date: Date) -> Date {
        let calendar = Calendar.current
        let seconds = calendar.component(.second, from: date)

        // If seconds > 0, round up to next minute
        if seconds > 0 {
            let secondsToAdd = 60 - seconds
            return date.addingTimeInterval(Double(secondsToAdd))
        }
        return date
    }

    /// Countdown string (e.g., "2h 30m" or "45m")
    public var countdown: String {
        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return "Now" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Local time string (e.g., "3:59pm" or "Jan 22, 9:59am")
    public var localTimeString: String {
        guard date > Date() else { return "Now" }

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        if calendar.isDateInToday(date) {
            // Today: show time only "3:59pm"
            formatter.dateFormat = "h:mma"
        } else {
            // Another day: show date and time "Jan 22, 9:59am"
            formatter.dateFormat = "MMM d, h:mma"
        }

        return formatter.string(from: date).lowercased()
    }

    /// Whether reset time has passed
    public var isExpired: Bool { date <= Date() }

    /// Default 5-hour session reset
    public nonisolated static var defaultSession: ResetTime {
        ResetTime(Date().addingTimeInterval(5 * 3600))
    }

    /// Default weekly reset (next Monday)
    public nonisolated static var defaultWeekly: ResetTime {
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
