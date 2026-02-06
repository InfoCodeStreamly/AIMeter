import Testing
import Foundation
@testable import AIMeterDomain

@Suite("UsageHistoryEntry")
struct UsageHistoryEntryTests {

    // MARK: - Initialization Tests

    @Test("initialization with valid values")
    func initialization() {
        let id = UUID()
        let timestamp = Date()
        let entry = UsageHistoryEntry(
            id: id,
            timestamp: timestamp,
            sessionPercentage: 75.5,
            weeklyPercentage: 60.2
        )

        #expect(entry.id == id)
        #expect(entry.timestamp == timestamp)
        #expect(entry.sessionPercentage == 75.5)
        #expect(entry.weeklyPercentage == 60.2)
    }

    // MARK: - from(usages:) Tests

    @Test("from creates entry from valid usages")
    func fromValidUsages() throws {
        let sessionPercentage = try Percentage.create(75.0)
        let weeklyPercentage = try Percentage.create(60.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))

        let usages = [
            UsageEntity(type: .session, percentage: sessionPercentage, resetTime: resetTime),
            UsageEntity(type: .weekly, percentage: weeklyPercentage, resetTime: resetTime)
        ]

        let entry = UsageHistoryEntry.from(usages: usages)

        #expect(entry != nil)
        #expect(entry?.sessionPercentage == 75.0)
        #expect(entry?.weeklyPercentage == 60.0)
    }

    @Test("from returns nil when session is missing")
    func fromMissingSession() throws {
        let weeklyPercentage = try Percentage.create(60.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))

        let usages = [
            UsageEntity(type: .weekly, percentage: weeklyPercentage, resetTime: resetTime)
        ]

        let entry = UsageHistoryEntry.from(usages: usages)

        #expect(entry == nil)
    }

    @Test("from returns nil when weekly is missing")
    func fromMissingWeekly() throws {
        let sessionPercentage = try Percentage.create(75.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))

        let usages = [
            UsageEntity(type: .session, percentage: sessionPercentage, resetTime: resetTime)
        ]

        let entry = UsageHistoryEntry.from(usages: usages)

        #expect(entry == nil)
    }

    @Test("from returns nil for empty array")
    func fromEmptyArray() {
        let entry = UsageHistoryEntry.from(usages: [])
        #expect(entry == nil)
    }

    @Test("from ignores non-primary types")
    func fromIgnoresNonPrimary() throws {
        let sessionPercentage = try Percentage.create(75.0)
        let weeklyPercentage = try Percentage.create(60.0)
        let opusPercentage = try Percentage.create(50.0)
        let sonnetPercentage = try Percentage.create(40.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))

        let usages = [
            UsageEntity(type: .session, percentage: sessionPercentage, resetTime: resetTime),
            UsageEntity(type: .weekly, percentage: weeklyPercentage, resetTime: resetTime),
            UsageEntity(type: .opus, percentage: opusPercentage, resetTime: resetTime),
            UsageEntity(type: .sonnet, percentage: sonnetPercentage, resetTime: resetTime)
        ]

        let entry = UsageHistoryEntry.from(usages: usages)

        #expect(entry != nil)
        #expect(entry?.sessionPercentage == 75.0)
        #expect(entry?.weeklyPercentage == 60.0)
    }

    @Test("from creates entry with current timestamp")
    func fromCurrentTimestamp() throws {
        let sessionPercentage = try Percentage.create(75.0)
        let weeklyPercentage = try Percentage.create(60.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))

        let usages = [
            UsageEntity(type: .session, percentage: sessionPercentage, resetTime: resetTime),
            UsageEntity(type: .weekly, percentage: weeklyPercentage, resetTime: resetTime)
        ]

        let before = Date()
        let entry = UsageHistoryEntry.from(usages: usages)
        let after = Date()

        #expect(entry != nil)
        #expect(entry!.timestamp >= before)
        #expect(entry!.timestamp <= after)
    }

    @Test("from creates unique IDs")
    func fromUniqueIDs() throws {
        let sessionPercentage = try Percentage.create(75.0)
        let weeklyPercentage = try Percentage.create(60.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))

        let usages = [
            UsageEntity(type: .session, percentage: sessionPercentage, resetTime: resetTime),
            UsageEntity(type: .weekly, percentage: weeklyPercentage, resetTime: resetTime)
        ]

        let entry1 = UsageHistoryEntry.from(usages: usages)
        let entry2 = UsageHistoryEntry.from(usages: usages)

        #expect(entry1?.id != entry2?.id)
    }

    // MARK: - Identifiable Tests

    @Test("id is unique")
    func identifiableUnique() {
        let timestamp = Date()
        let entry1 = UsageHistoryEntry(
            id: UUID(),
            timestamp: timestamp,
            sessionPercentage: 75.0,
            weeklyPercentage: 60.0
        )
        let entry2 = UsageHistoryEntry(
            id: UUID(),
            timestamp: timestamp,
            sessionPercentage: 75.0,
            weeklyPercentage: 60.0
        )

        #expect(entry1.id != entry2.id)
    }

    // MARK: - Equatable Tests

    @Test("equatable compares all fields")
    func equatable() {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 1704067200)

        let entry1 = UsageHistoryEntry(
            id: id,
            timestamp: timestamp,
            sessionPercentage: 75.0,
            weeklyPercentage: 60.0
        )
        let entry2 = UsageHistoryEntry(
            id: id,
            timestamp: timestamp,
            sessionPercentage: 75.0,
            weeklyPercentage: 60.0
        )
        let entry3 = UsageHistoryEntry(
            id: UUID(),
            timestamp: timestamp,
            sessionPercentage: 75.0,
            weeklyPercentage: 60.0
        )

        #expect(entry1 == entry2)
        #expect(entry1 != entry3)
    }

    @Test("equatable with different percentages")
    func equatableDifferentPercentages() {
        let id = UUID()
        let timestamp = Date()

        let entry1 = UsageHistoryEntry(
            id: id,
            timestamp: timestamp,
            sessionPercentage: 75.0,
            weeklyPercentage: 60.0
        )
        let entry2 = UsageHistoryEntry(
            id: id,
            timestamp: timestamp,
            sessionPercentage: 80.0,
            weeklyPercentage: 60.0
        )

        #expect(entry1 != entry2)
    }

    // MARK: - Codable Tests

    @Test("codable encodes correctly")
    func codableEncode() throws {
        let entry = UsageHistoryEntry(
            id: UUID(),
            timestamp: Date(),
            sessionPercentage: 75.0,
            weeklyPercentage: 60.0
        )

        let encoded = try JSONEncoder().encode(entry)
        #expect(!encoded.isEmpty)
    }

    @Test("codable decodes correctly")
    func codableDecode() throws {
        let id = UUID()
        let timestamp = Date()
        let entry = UsageHistoryEntry(
            id: id,
            timestamp: timestamp,
            sessionPercentage: 75.0,
            weeklyPercentage: 60.0
        )

        let encoded = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(UsageHistoryEntry.self, from: encoded)

        #expect(decoded.id == id)
        #expect(decoded.sessionPercentage == 75.0)
        #expect(decoded.weeklyPercentage == 60.0)
    }

    @Test("codable roundtrip preserves values")
    func codableRoundtrip() throws {
        let original = UsageHistoryEntry(
            id: UUID(),
            timestamp: Date(),
            sessionPercentage: 75.5,
            weeklyPercentage: 60.2
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UsageHistoryEntry.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.sessionPercentage == original.sessionPercentage)
        #expect(decoded.weeklyPercentage == original.weeklyPercentage)
    }

    @Test("codable handles zero percentages")
    func codableZeroPercentages() throws {
        let entry = UsageHistoryEntry(
            id: UUID(),
            timestamp: Date(),
            sessionPercentage: 0.0,
            weeklyPercentage: 0.0
        )

        let encoded = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(UsageHistoryEntry.self, from: encoded)

        #expect(decoded.sessionPercentage == 0.0)
        #expect(decoded.weeklyPercentage == 0.0)
    }

    @Test("codable handles maximum percentages")
    func codableMaxPercentages() throws {
        let entry = UsageHistoryEntry(
            id: UUID(),
            timestamp: Date(),
            sessionPercentage: 100.0,
            weeklyPercentage: 100.0
        )

        let encoded = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(UsageHistoryEntry.self, from: encoded)

        #expect(decoded.sessionPercentage == 100.0)
        #expect(decoded.weeklyPercentage == 100.0)
    }

    // MARK: - Sendable Conformance

    @Test("sendable conformance compiles")
    func sendableConformance() {
        let entry = UsageHistoryEntry(
            id: UUID(),
            timestamp: Date(),
            sessionPercentage: 75.0,
            weeklyPercentage: 60.0
        )

        let closure: @Sendable () -> UsageHistoryEntry = { entry }
        #expect(closure().sessionPercentage == 75.0)
    }

    // MARK: - Edge Cases

    @Test("from handles duplicate usage types")
    func fromDuplicateTypes() throws {
        let sessionPercentage1 = try Percentage.create(75.0)
        let sessionPercentage2 = try Percentage.create(80.0)
        let weeklyPercentage = try Percentage.create(60.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))

        let usages = [
            UsageEntity(type: .session, percentage: sessionPercentage1, resetTime: resetTime),
            UsageEntity(type: .session, percentage: sessionPercentage2, resetTime: resetTime),
            UsageEntity(type: .weekly, percentage: weeklyPercentage, resetTime: resetTime)
        ]

        let entry = UsageHistoryEntry.from(usages: usages)

        #expect(entry != nil)
        // Should use the first session it finds
        #expect(entry?.sessionPercentage == 75.0 || entry?.sessionPercentage == 80.0)
    }

    @Test("from handles decimal percentages")
    func fromDecimalPercentages() throws {
        let sessionPercentage = try Percentage.create(75.123)
        let weeklyPercentage = try Percentage.create(60.456)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))

        let usages = [
            UsageEntity(type: .session, percentage: sessionPercentage, resetTime: resetTime),
            UsageEntity(type: .weekly, percentage: weeklyPercentage, resetTime: resetTime)
        ]

        let entry = UsageHistoryEntry.from(usages: usages)

        #expect(entry != nil)
        #expect(abs(entry!.sessionPercentage - 75.123) < 0.001)
        #expect(abs(entry!.weeklyPercentage - 60.456) < 0.001)
    }
}
