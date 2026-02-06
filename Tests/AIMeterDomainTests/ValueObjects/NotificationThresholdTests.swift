import Testing
@testable import AIMeterDomain

@Suite("NotificationThreshold")
struct NotificationThresholdTests {

    // MARK: - Cases Tests

    @Test("warning case has correct raw value")
    func warningRawValue() {
        #expect(NotificationThreshold.warning.rawValue == 80)
    }

    @Test("critical case has correct raw value")
    func criticalRawValue() {
        #expect(NotificationThreshold.critical.rawValue == 95)
    }

    @Test("all cases are present")
    func allCases() {
        #expect(NotificationThreshold.allCases.count == 2)
        #expect(NotificationThreshold.allCases.contains(.warning))
        #expect(NotificationThreshold.allCases.contains(.critical))
    }

    // MARK: - Title Tests

    @Test("warning title")
    func warningTitle() {
        let title = NotificationThreshold.warning.title
        #expect(!title.isEmpty)
        #expect(title.contains("Warning") || title.contains("80"))
    }

    @Test("critical title")
    func criticalTitle() {
        let title = NotificationThreshold.critical.title
        #expect(!title.isEmpty)
        #expect(title.contains("Critical") || title.contains("95"))
    }

    // MARK: - Body Tests

    @Test("body for session usage")
    func bodySession() {
        let body = NotificationThreshold.warning.body(for: .session, percentage: 85)
        #expect(!body.isEmpty)
        #expect(body.contains("session") || body.contains("Session"))
        #expect(body.contains("85"))
    }

    @Test("body for weekly usage")
    func bodyWeekly() {
        let body = NotificationThreshold.warning.body(for: .weekly, percentage: 85)
        #expect(!body.isEmpty)
        #expect(body.contains("weekly") || body.contains("Weekly"))
        #expect(body.contains("85"))
    }

    @Test("body for opus usage")
    func bodyOpus() {
        let body = NotificationThreshold.warning.body(for: .opus, percentage: 85)
        #expect(!body.isEmpty)
        #expect(body.contains("opus") || body.contains("Opus"))
        #expect(body.contains("85"))
    }

    @Test("body for sonnet usage")
    func bodySonnet() {
        let body = NotificationThreshold.warning.body(for: .sonnet, percentage: 85)
        #expect(!body.isEmpty)
        #expect(body.contains("sonnet") || body.contains("Sonnet"))
        #expect(body.contains("85"))
    }

    @Test("body for critical threshold")
    func bodyCritical() {
        let body = NotificationThreshold.critical.body(for: .session, percentage: 98)
        #expect(!body.isEmpty)
        #expect(body.contains("98"))
    }

    @Test("body contains percentage value")
    func bodyContainsPercentage() {
        let body = NotificationThreshold.warning.body(for: .session, percentage: 82)
        #expect(body.contains("82"))
    }

    // MARK: - isCrossed Tests

    @Test("warning isCrossed at 79.9")
    func warningNotCrossedBelow() {
        #expect(NotificationThreshold.warning.isCrossed(by: 79.9) == false)
    }

    @Test("warning isCrossed at exactly 80")
    func warningCrossedAtBoundary() {
        #expect(NotificationThreshold.warning.isCrossed(by: 80.0) == true)
    }

    @Test("warning isCrossed at 80.1")
    func warningCrossedAbove() {
        #expect(NotificationThreshold.warning.isCrossed(by: 80.1) == true)
    }

    @Test("warning isCrossed at 100")
    func warningCrossedAtMax() {
        #expect(NotificationThreshold.warning.isCrossed(by: 100.0) == true)
    }

    @Test("critical isCrossed at 94.9")
    func criticalNotCrossedBelow() {
        #expect(NotificationThreshold.critical.isCrossed(by: 94.9) == false)
    }

    @Test("critical isCrossed at exactly 95")
    func criticalCrossedAtBoundary() {
        #expect(NotificationThreshold.critical.isCrossed(by: 95.0) == true)
    }

    @Test("critical isCrossed at 95.1")
    func criticalCrossedAbove() {
        #expect(NotificationThreshold.critical.isCrossed(by: 95.1) == true)
    }

    @Test("critical isCrossed at 100")
    func criticalCrossedAtMax() {
        #expect(NotificationThreshold.critical.isCrossed(by: 100.0) == true)
    }

    @Test("isCrossed at 0")
    func notCrossedAtZero() {
        #expect(NotificationThreshold.warning.isCrossed(by: 0.0) == false)
        #expect(NotificationThreshold.critical.isCrossed(by: 0.0) == false)
    }

    @Test("isCrossed at 50")
    func notCrossedAtFifty() {
        #expect(NotificationThreshold.warning.isCrossed(by: 50.0) == false)
        #expect(NotificationThreshold.critical.isCrossed(by: 50.0) == false)
    }

    // MARK: - Ordering Tests

    @Test("thresholds are in ascending order")
    func ordering() {
        #expect(NotificationThreshold.warning.rawValue < NotificationThreshold.critical.rawValue)
    }

    @Test("warning is crossed before critical")
    func crossingOrder() {
        let percentage = 90.0
        #expect(NotificationThreshold.warning.isCrossed(by: percentage) == true)
        #expect(NotificationThreshold.critical.isCrossed(by: percentage) == false)
    }

    // MARK: - Edge Cases

    @Test("body with different usage types uses correct names")
    func bodyUsageTypeNames() {
        let usageTypes: [UsageType] = [.session, .weekly, .opus, .sonnet]

        for usageType in usageTypes {
            let body = NotificationThreshold.warning.body(for: usageType, percentage: 85)
            #expect(!body.isEmpty)
        }
    }

    @Test("isCrossed with negative percentage")
    func isCrossedNegative() {
        #expect(NotificationThreshold.warning.isCrossed(by: -10.0) == false)
        #expect(NotificationThreshold.critical.isCrossed(by: -10.0) == false)
    }

    @Test("isCrossed with very large percentage")
    func isCrossedLarge() {
        #expect(NotificationThreshold.warning.isCrossed(by: 200.0) == true)
        #expect(NotificationThreshold.critical.isCrossed(by: 200.0) == true)
    }
}
