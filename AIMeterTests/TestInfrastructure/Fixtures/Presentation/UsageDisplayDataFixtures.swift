import Foundation
@testable import AIMeter

enum UsageDisplayDataFixtures {

    // MARK: - Session Usage

    static var sessionSafe: UsageDisplayData {
        UsageDisplayData(from: UsageEntityFixtures.sessionSafe)
    }

    static var sessionHigh: UsageDisplayData {
        UsageDisplayData(from: UsageEntityFixtures.sessionHigh)
    }

    static var sessionCritical: UsageDisplayData {
        UsageDisplayData(from: UsageEntityFixtures.sessionCritical)
    }

    // MARK: - Weekly Usage

    static var weeklySafe: UsageDisplayData {
        UsageDisplayData(from: UsageEntityFixtures.weeklySafe)
    }

    static var weeklyHigh: UsageDisplayData {
        UsageDisplayData(from: UsageEntityFixtures.weeklyHigh)
    }

    // MARK: - Opus Usage

    static var opusSafe: UsageDisplayData {
        UsageDisplayData(from: UsageEntityFixtures.opusSafe)
    }

    // MARK: - Sonnet Usage

    static var sonnetSafe: UsageDisplayData {
        UsageDisplayData(from: UsageEntityFixtures.sonnetSafe)
    }

    // MARK: - Arrays

    static var allSafe: [UsageDisplayData] {
        [sessionSafe, weeklySafe, opusSafe, sonnetSafe]
    }

    static var sessionHighWeeklySafe: [UsageDisplayData] {
        [sessionHigh, weeklySafe, opusSafe, sonnetSafe]
    }

    static var sessionSafeWeeklyHigh: [UsageDisplayData] {
        [sessionSafe, weeklyHigh, opusSafe, sonnetSafe]
    }

    static var empty: [UsageDisplayData] {
        []
    }
}
