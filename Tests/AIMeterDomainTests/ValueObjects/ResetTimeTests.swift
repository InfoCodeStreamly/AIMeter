import Testing
import Foundation
@testable import AIMeterDomain

@Suite("ResetTime")
struct ResetTimeTests {

    // MARK: - Initialization Tests

    @Test("init with date")
    func initWithDate() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let resetTime = ResetTime(date)
        #expect(resetTime.date == date)
    }

    // MARK: - fromISO8601 Tests

    @Test("fromISO8601 parses valid ISO8601 string")
    func fromISO8601Valid() {
        let resetTime = ResetTime.fromISO8601("2024-01-01T12:30:45Z")
        #expect(resetTime != nil)
        // 12:30:45 UTC rounds up to 12:31:00 UTC = 1704112260
        #expect(resetTime?.date.timeIntervalSince1970 == 1704112260)
    }

    @Test("fromISO8601 returns nil for string without seconds")
    func fromISO8601NoSeconds() {
        // ISO8601DateFormatter with .withInternetDateTime requires seconds
        let resetTime = ResetTime.fromISO8601("2024-01-01T12:30Z")
        #expect(resetTime == nil)
    }

    @Test("fromISO8601 rounds up seconds to next minute")
    func fromISO8601RoundUp() {
        // 12:30:01 UTC should round to 12:31:00 UTC
        let resetTime = ResetTime.fromISO8601("2024-01-01T12:30:01Z")
        #expect(resetTime != nil)

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.hour, .minute, .second], from: resetTime!.date)
        #expect(components.hour == 12)
        #expect(components.minute == 31)
        #expect(components.second == 0)
    }

    @Test("fromISO8601 does not round exact minute")
    func fromISO8601ExactMinute() {
        // 12:30:00 UTC should stay 12:30:00 UTC
        let resetTime = ResetTime.fromISO8601("2024-01-01T12:30:00Z")
        #expect(resetTime != nil)

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.hour, .minute, .second], from: resetTime!.date)
        #expect(components.hour == 12)
        #expect(components.minute == 30)
        #expect(components.second == 0)
    }

    @Test("fromISO8601 returns nil for invalid string")
    func fromISO8601Invalid() {
        let resetTime = ResetTime.fromISO8601("not a date")
        #expect(resetTime == nil)
    }

    @Test("fromISO8601 returns nil for empty string")
    func fromISO8601Empty() {
        let resetTime = ResetTime.fromISO8601("")
        #expect(resetTime == nil)
    }

    @Test("fromISO8601 parses with milliseconds")
    func fromISO8601Milliseconds() {
        let resetTime = ResetTime.fromISO8601("2024-01-01T12:30:45.123Z")
        #expect(resetTime != nil)
    }

    // MARK: - countdown Tests

    @Test("countdown shows hours and minutes")
    func countdownHoursMinutes() {
        // Add extra seconds to avoid rounding down
        let futureDate = Date().addingTimeInterval(2 * 3600 + 30 * 60 + 30) // 2h 30m 30s from now
        let resetTime = ResetTime(futureDate)
        #expect(resetTime.countdown == "2h 30m")
    }

    @Test("countdown shows only minutes")
    func countdownMinutesOnly() {
        let futureDate = Date().addingTimeInterval(45 * 60 + 30) // 45m 30s from now
        let resetTime = ResetTime(futureDate)
        #expect(resetTime.countdown == "45m")
    }

    @Test("countdown shows Now for expired")
    func countdownExpired() {
        let pastDate = Date().addingTimeInterval(-3600) // 1h ago
        let resetTime = ResetTime(pastDate)
        #expect(resetTime.countdown == "Now")
    }

    @Test("countdown shows Now for current time")
    func countdownNow() {
        let resetTime = ResetTime(Date())
        #expect(resetTime.countdown == "Now")
    }

    @Test("countdown rounds down partial minutes")
    func countdownRoundDown() {
        let futureDate = Date().addingTimeInterval(90) // 1.5 minutes from now
        let resetTime = ResetTime(futureDate)
        #expect(resetTime.countdown == "1m")
    }

    // MARK: - isExpired Tests

    @Test("isExpired returns true for past date")
    func isExpiredPast() {
        let pastDate = Date().addingTimeInterval(-3600)
        let resetTime = ResetTime(pastDate)
        #expect(resetTime.isExpired == true)
    }

    @Test("isExpired returns false for future date")
    func isExpiredFuture() {
        let futureDate = Date().addingTimeInterval(3600)
        let resetTime = ResetTime(futureDate)
        #expect(resetTime.isExpired == false)
    }

    @Test("isExpired returns true for current time")
    func isExpiredNow() {
        let resetTime = ResetTime(Date())
        #expect(resetTime.isExpired == true)
    }

    // MARK: - localTimeString Tests

    @Test("localTimeString shows time for today")
    func localTimeStringToday() {
        let calendar = Calendar.current
        let now = Date()
        let futureToday = calendar.date(byAdding: .hour, value: 2, to: now)!
        let resetTime = ResetTime(futureToday)

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.locale = Locale.current
        let expected = formatter.string(from: futureToday).lowercased()

        #expect(resetTime.localTimeString == expected)
    }

    @Test("localTimeString shows date and time for another day")
    func localTimeStringAnotherDay() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let resetTime = ResetTime(tomorrow)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mma"
        formatter.locale = Locale.current
        let expected = formatter.string(from: tomorrow).lowercased()

        #expect(resetTime.localTimeString == expected)
    }

    @Test("localTimeString shows Now for expired")
    func localTimeStringExpired() {
        let pastDate = Date().addingTimeInterval(-3600)
        let resetTime = ResetTime(pastDate)
        #expect(resetTime.localTimeString == "Now")
    }

    // MARK: - Equatable Tests

    @Test("equatable compares dates correctly")
    func equatable() {
        let date1 = Date(timeIntervalSince1970: 1704067200)
        let date2 = Date(timeIntervalSince1970: 1704067200)
        let date3 = Date(timeIntervalSince1970: 1704153600)

        let resetTime1 = ResetTime(date1)
        let resetTime2 = ResetTime(date2)
        let resetTime3 = ResetTime(date3)

        #expect(resetTime1 == resetTime2)
        #expect(resetTime1 != resetTime3)
    }

    // MARK: - Codable Tests

    @Test("codable encodes and decodes correctly")
    func codable() throws {
        let date = Date(timeIntervalSince1970: 1704067200)
        let original = ResetTime(date)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ResetTime.self, from: encoded)

        #expect(original == decoded)
    }
}
