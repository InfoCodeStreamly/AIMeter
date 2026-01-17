import Foundation
@testable import AIMeter

enum ResetTimeFixtures {

    // MARK: - Base Values (SSOT)
    static var inOneHour: Date {
        Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    }

    static var inFiveHours: Date {
        Calendar.current.date(byAdding: .hour, value: 5, to: Date())!
    }

    static var inSevenDays: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    }

    static var expired: Date {
        Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
    }

    // MARK: - Local Time String Testing

    /// Today, 3 hours later (for testing "h:mma" format)
    static var todayLater: Date {
        Calendar.current.date(byAdding: .hour, value: 3, to: Date())!
    }

    /// Tomorrow morning 9:00 (for testing "MMM d, h:mma" format)
    static var tomorrowMorning: Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)!
    }

    /// Next week (for testing date format with day)
    static var nextWeek: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    }
}
