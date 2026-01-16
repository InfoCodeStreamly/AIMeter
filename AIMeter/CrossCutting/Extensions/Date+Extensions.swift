import Foundation

extension Date {
    /// Relative time string (e.g., "2m ago", "1h ago")
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Countdown string to future date (e.g., "2h 30m")
    var countdown: String {
        let interval = timeIntervalSinceNow
        guard interval > 0 else { return "Now" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h"
        }

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }

    /// Whether date is in the past
    var isPast: Bool {
        self < Date()
    }

    /// Whether date is in the future
    var isFuture: Bool {
        self > Date()
    }

    /// Next Monday at noon
    static var nextMonday: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = 2 // Monday
        components.hour = 12
        components.minute = 0
        return calendar.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        ) ?? Date()
    }

    /// 5 hours from now
    static var fiveHoursFromNow: Date {
        Date().addingTimeInterval(5 * 3600)
    }
}
