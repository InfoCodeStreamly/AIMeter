import Testing
import Foundation
@testable import AIMeter

@Suite("ResetTime")
struct ResetTimeTests {

    // MARK: - localTimeString

    @Test("localTimeString today shows time only")
    func localTimeString_today_showsTimeOnly() {
        let resetTime = ResetTime(ResetTimeFixtures.todayLater)

        let result = resetTime.localTimeString

        // Should be format like "3:59pm" (no date)
        #expect(!result.contains(","))
        #expect(result.contains("am") || result.contains("pm"))
    }

    @Test("localTimeString another day shows date and time")
    func localTimeString_anotherDay_showsDateAndTime() {
        let resetTime = ResetTime(ResetTimeFixtures.tomorrowMorning)

        let result = resetTime.localTimeString

        // Should be format like "jan 22, 9:00am" (with date)
        #expect(result.contains(","))
        #expect(result.contains("am") || result.contains("pm"))
    }

    @Test("localTimeString expired returns Now")
    func localTimeString_expired_returnsNow() {
        let resetTime = ResetTime(ResetTimeFixtures.expired)

        let result = resetTime.localTimeString

        #expect(result == "Now")
    }

    // MARK: - countdown (existing functionality)

    @Test("countdown shows hours and minutes")
    func countdown_showsHoursAndMinutes() {
        let resetTime = ResetTime(ResetTimeFixtures.inOneHour)

        let result = resetTime.countdown

        #expect(result.contains("h") || result.contains("m"))
    }

    @Test("countdown expired returns Now")
    func countdown_expired_returnsNow() {
        let resetTime = ResetTime(ResetTimeFixtures.expired)

        let result = resetTime.countdown

        #expect(result == "Now")
    }

    // MARK: - isExpired

    @Test("isExpired returns true for past date")
    func isExpired_pastDate_returnsTrue() {
        let resetTime = ResetTime(ResetTimeFixtures.expired)

        #expect(resetTime.isExpired)
    }

    @Test("isExpired returns false for future date")
    func isExpired_futureDate_returnsFalse() {
        let resetTime = ResetTime(ResetTimeFixtures.inOneHour)

        #expect(!resetTime.isExpired)
    }

    // MARK: - fromISO8601

    @Test("fromISO8601 parses valid date string")
    func fromISO8601_validString_parsesCorrectly() {
        let isoString = "2026-01-20T15:30:00Z"

        let result = ResetTime.fromISO8601(isoString)

        #expect(result != nil)
    }

    @Test("fromISO8601 returns nil for invalid string")
    func fromISO8601_invalidString_returnsNil() {
        let invalidString = "not-a-date"

        let result = ResetTime.fromISO8601(invalidString)

        #expect(result == nil)
    }

    // MARK: - Rounding (fixes jumping minutes bug)

    @Test("fromISO8601 rounds up seconds to next minute")
    func fromISO8601_roundsUpSeconds() {
        // 13:59:59 should become 14:00:00
        let isoString = "2026-01-17T13:59:59Z"

        let result = ResetTime.fromISO8601(isoString)

        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: result!.date)
        let second = calendar.component(.second, from: result!.date)

        #expect(minute == 0) // Rounded to :00
        #expect(second == 0)
    }

    @Test("fromISO8601 keeps exact minute unchanged")
    func fromISO8601_keepsExactMinute() {
        // 14:00:00 should stay 14:00:00
        let isoString = "2026-01-17T14:00:00Z"

        let result = ResetTime.fromISO8601(isoString)

        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: result!.date)
        let second = calendar.component(.second, from: result!.date)

        #expect(minute == 0)
        #expect(second == 0)
    }

    @Test("fromISO8601 rounds up fractional seconds")
    func fromISO8601_roundsUpFractionalSeconds() {
        // 13:59:59.689 should become 14:00:00
        let isoString = "2026-01-17T13:59:59.689253+00:00"

        let result = ResetTime.fromISO8601(isoString)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: result!.date)
        let minute = calendar.component(.minute, from: result!.date)
        let second = calendar.component(.second, from: result!.date)

        // Note: hour depends on timezone, but minute and second should be 0
        #expect(minute == 0)
        #expect(second == 0)
    }

    @Test("fromISO8601 rounds up any non-zero seconds")
    func fromISO8601_roundsUpAnySeconds() {
        // 14:30:01 should become 14:31:00
        let isoString = "2026-01-17T14:30:01Z"

        let result = ResetTime.fromISO8601(isoString)

        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: result!.date)
        let second = calendar.component(.second, from: result!.date)

        #expect(minute == 31) // Rounded up from :30:01 to :31:00
        #expect(second == 0)
    }
}
