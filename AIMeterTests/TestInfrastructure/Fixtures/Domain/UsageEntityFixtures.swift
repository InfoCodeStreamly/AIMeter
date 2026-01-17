import Foundation
@testable import AIMeter

enum UsageEntityFixtures {

    // MARK: - Base Values (SSOT)
    static let testId = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!

    // MARK: - Session Usage
    static var sessionSafe: UsageEntity {
        UsageEntity(
            id: testId,
            type: .session,
            percentage: PercentageFixtures.safePercentage,
            resetTime: ResetTime(ResetTimeFixtures.inFiveHours)
        )
    }

    static var sessionHigh: UsageEntity {
        UsageEntity(
            id: testId,
            type: .session,
            percentage: PercentageFixtures.highPercentage,
            resetTime: ResetTime(ResetTimeFixtures.inFiveHours)
        )
    }

    static var sessionCritical: UsageEntity {
        UsageEntity(
            id: testId,
            type: .session,
            percentage: PercentageFixtures.criticalPercentage,
            resetTime: ResetTime(ResetTimeFixtures.inOneHour)
        )
    }

    // MARK: - Weekly Usage
    static var weeklySafe: UsageEntity {
        UsageEntity(
            id: UUID(),
            type: .weekly,
            percentage: try! Percentage.create(30.0),
            resetTime: ResetTime(ResetTimeFixtures.inSevenDays)
        )
    }

    static var weeklyHigh: UsageEntity {
        UsageEntity(
            id: UUID(),
            type: .weekly,
            percentage: try! Percentage.create(85.0),
            resetTime: ResetTime(ResetTimeFixtures.inSevenDays)
        )
    }

    // MARK: - Opus Usage
    static var opusSafe: UsageEntity {
        UsageEntity(
            id: UUID(),
            type: .opus,
            percentage: try! Percentage.create(10.0),
            resetTime: ResetTime(ResetTimeFixtures.inSevenDays)
        )
    }

    // MARK: - Sonnet Usage
    static var sonnetSafe: UsageEntity {
        UsageEntity(
            id: UUID(),
            type: .sonnet,
            percentage: try! Percentage.create(25.0),
            resetTime: ResetTime(ResetTimeFixtures.inSevenDays)
        )
    }

    // MARK: - Arrays
    static var allSafe: [UsageEntity] {
        [sessionSafe, weeklySafe, opusSafe, sonnetSafe]
    }

    static var allCritical: [UsageEntity] {
        [sessionCritical, weeklyHigh, opusSafe, sonnetSafe]
    }

    static var empty: [UsageEntity] {
        []
    }

    // MARK: - Parameterized Test Data
    static var statusTestCases: [(name: String, entity: UsageEntity, expectedStatus: UsageStatus)] {
        [
            ("safe", sessionSafe, .safe),
            ("high", sessionHigh, .moderate),
            ("critical", sessionCritical, .critical)
        ]
    }
}
