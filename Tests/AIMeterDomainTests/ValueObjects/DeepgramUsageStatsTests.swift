import Foundation
import Testing
@testable import AIMeterDomain

@Suite("DeepgramUsageStats")
struct DeepgramUsageStatsTests {

    // MARK: - Helpers

    private static let referenceBalance = DeepgramBalance(amount: 50.00, units: "usd")

    private static func makeDate(year: Int, month: Int, day: Int = 1) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }

    // MARK: - Init Tests

    @Test("init stores totalSeconds correctly")
    func initStoresTotalSeconds() {
        let stats = DeepgramUsageStats(
            totalSeconds: 120.5,
            requestCount: 10,
            balance: Self.referenceBalance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        #expect(stats.totalSeconds == 120.5)
    }

    @Test("init stores requestCount correctly")
    func initStoresRequestCount() {
        let stats = DeepgramUsageStats(
            totalSeconds: 60.0,
            requestCount: 42,
            balance: Self.referenceBalance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        #expect(stats.requestCount == 42)
    }

    @Test("init stores balance correctly")
    func initStoresBalance() {
        let balance = DeepgramBalance(amount: 187.50, units: "usd")
        let stats = DeepgramUsageStats(
            totalSeconds: 60.0,
            requestCount: 5,
            balance: balance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        #expect(stats.balance == balance)
        #expect(stats.balance.amount == 187.50)
        #expect(stats.balance.units == "usd")
    }

    @Test("init stores periodStart correctly")
    func initStoresPeriodStart() {
        let periodStart = Self.makeDate(year: 2026, month: 2)
        let stats = DeepgramUsageStats(
            totalSeconds: 60.0,
            requestCount: 5,
            balance: Self.referenceBalance,
            periodStart: periodStart
        )
        #expect(stats.periodStart == periodStart)
    }

    // MARK: - formattedDuration: seconds range

    @Test("formattedDuration shows seconds for values under 60")
    func formattedDurationSeconds() {
        let stats = DeepgramUsageStats(
            totalSeconds: 36.5,
            requestCount: 1,
            balance: Self.referenceBalance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        #expect(stats.formattedDuration == "36.5 sec")
    }

    @Test("formattedDuration shows seconds for value of 0")
    func formattedDurationZeroSeconds() {
        let stats = DeepgramUsageStats(
            totalSeconds: 0.0,
            requestCount: 0,
            balance: Self.referenceBalance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        #expect(stats.formattedDuration == "0.0 sec")
    }

    @Test("formattedDuration shows seconds for 59.9 seconds")
    func formattedDurationJustBelowMinute() {
        let stats = DeepgramUsageStats(
            totalSeconds: 59.9,
            requestCount: 1,
            balance: Self.referenceBalance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        #expect(stats.formattedDuration == "59.9 sec")
    }

    @Test("formattedDuration shows seconds for exactly 1 second")
    func formattedDurationOneSecond() {
        let stats = DeepgramUsageStats(
            totalSeconds: 1.0,
            requestCount: 1,
            balance: Self.referenceBalance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        #expect(stats.formattedDuration == "1.0 sec")
    }

    // MARK: - formattedDuration: boundary at 60 seconds

    @Test("formattedDuration shows minutes for exactly 60 seconds")
    func formattedDurationExactly60Seconds() {
        let stats = DeepgramUsageStats(
            totalSeconds: 60.0,
            requestCount: 1,
            balance: Self.referenceBalance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        #expect(stats.formattedDuration == "1.0 min")
    }

    @Test("formattedDuration shows minutes for values in 60-3600 range")
    func formattedDurationMinutes() {
        let stats = DeepgramUsageStats(
            totalSeconds: 125.0,
            requestCount: 1,
            balance: Self.referenceBalance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        // 125 / 60 = 2.0833... → "2.1 min"
        #expect(stats.formattedDuration == "2.1 min")
    }

    @Test("formattedDuration shows minutes for 3599 seconds")
    func formattedDurationJustBelowHour() {
        let stats = DeepgramUsageStats(
            totalSeconds: 3599.0,
            requestCount: 1,
            balance: Self.referenceBalance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        // 3599 / 60 = 59.983... → "60.0 min"
        #expect(stats.formattedDuration == "60.0 min")
    }

    // MARK: - formattedDuration: boundary at 3600 seconds

    @Test("formattedDuration shows hours for exactly 3600 seconds")
    func formattedDurationExactly3600Seconds() {
        let stats = DeepgramUsageStats(
            totalSeconds: 3600.0,
            requestCount: 1,
            balance: Self.referenceBalance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        #expect(stats.formattedDuration == "1.0 hrs")
    }

    @Test("formattedDuration shows hours for values above 3600")
    func formattedDurationHours() {
        let stats = DeepgramUsageStats(
            totalSeconds: 5400.0,
            requestCount: 1,
            balance: Self.referenceBalance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        // 5400 / 3600 = 1.5 → "1.5 hrs"
        #expect(stats.formattedDuration == "1.5 hrs")
    }

    @Test("formattedDuration rounds to one decimal place for hours")
    func formattedDurationHoursRounding() {
        let stats = DeepgramUsageStats(
            totalSeconds: 7266.0,
            requestCount: 1,
            balance: Self.referenceBalance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        // 7266 / 3600 = 2.0183... → "2.0 hrs"
        #expect(stats.formattedDuration == "2.0 hrs")
    }

    // MARK: - Equatable Tests

    @Test("same values are equal")
    func equatableSameValues() {
        let periodStart = Self.makeDate(year: 2026, month: 2)
        let balance = DeepgramBalance(amount: 100.0, units: "usd")
        let stats1 = DeepgramUsageStats(
            totalSeconds: 120.0,
            requestCount: 5,
            balance: balance,
            periodStart: periodStart
        )
        let stats2 = DeepgramUsageStats(
            totalSeconds: 120.0,
            requestCount: 5,
            balance: balance,
            periodStart: periodStart
        )
        #expect(stats1 == stats2)
    }

    @Test("different totalSeconds are not equal")
    func equatableDifferentSeconds() {
        let periodStart = Self.makeDate(year: 2026, month: 2)
        let balance = DeepgramBalance(amount: 100.0, units: "usd")
        let stats1 = DeepgramUsageStats(
            totalSeconds: 100.0,
            requestCount: 5,
            balance: balance,
            periodStart: periodStart
        )
        let stats2 = DeepgramUsageStats(
            totalSeconds: 200.0,
            requestCount: 5,
            balance: balance,
            periodStart: periodStart
        )
        #expect(stats1 != stats2)
    }

    @Test("different requestCount are not equal")
    func equatableDifferentRequestCount() {
        let periodStart = Self.makeDate(year: 2026, month: 2)
        let balance = DeepgramBalance(amount: 100.0, units: "usd")
        let stats1 = DeepgramUsageStats(
            totalSeconds: 120.0,
            requestCount: 5,
            balance: balance,
            periodStart: periodStart
        )
        let stats2 = DeepgramUsageStats(
            totalSeconds: 120.0,
            requestCount: 10,
            balance: balance,
            periodStart: periodStart
        )
        #expect(stats1 != stats2)
    }

    @Test("different balance are not equal")
    func equatableDifferentBalance() {
        let periodStart = Self.makeDate(year: 2026, month: 2)
        let stats1 = DeepgramUsageStats(
            totalSeconds: 120.0,
            requestCount: 5,
            balance: DeepgramBalance(amount: 50.0, units: "usd"),
            periodStart: periodStart
        )
        let stats2 = DeepgramUsageStats(
            totalSeconds: 120.0,
            requestCount: 5,
            balance: DeepgramBalance(amount: 99.0, units: "usd"),
            periodStart: periodStart
        )
        #expect(stats1 != stats2)
    }

    @Test("different periodStart are not equal")
    func equatableDifferentPeriodStart() {
        let balance = DeepgramBalance(amount: 100.0, units: "usd")
        let stats1 = DeepgramUsageStats(
            totalSeconds: 120.0,
            requestCount: 5,
            balance: balance,
            periodStart: Self.makeDate(year: 2026, month: 1)
        )
        let stats2 = DeepgramUsageStats(
            totalSeconds: 120.0,
            requestCount: 5,
            balance: balance,
            periodStart: Self.makeDate(year: 2026, month: 2)
        )
        #expect(stats1 != stats2)
    }
}
