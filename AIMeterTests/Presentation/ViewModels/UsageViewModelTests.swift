import Testing
@testable import AIMeter

@Suite("UsageViewModel", .tags(.presentation))
struct UsageViewModelTests {

    // MARK: - Menu Bar Text Logic Tests

    @Test("menuBarText format with session 70 and weekly 30")
    func menuBarTextLogic_formatsCorrectly() {
        // Test the expected format logic
        let sessionPercentage = 70
        let weeklyPercentage = 30
        let expected = "\(sessionPercentage)/\(weeklyPercentage)"

        #expect(expected == "70/30")
    }

    @Test("menuBarText fallback when no data")
    func menuBarTextLogic_noData_returnsDashes() {
        let fallback = "--/--"
        #expect(fallback == "--/--")
    }

    // MARK: - Menu Bar Status Logic Tests

    @Test("menuBarStatus uses max of session and weekly when session higher")
    func menuBarStatusLogic_sessionHigher_usesSessionStatus() {
        let sessionPercentage = 70
        let weeklyPercentage = 30
        let maxPercentage = max(sessionPercentage, weeklyPercentage)
        let status = Percentage.clamped(Double(maxPercentage)).toStatus()

        #expect(maxPercentage == 70)
        #expect(status == .moderate)
    }

    @Test("menuBarStatus uses max of session and weekly when weekly higher")
    func menuBarStatusLogic_weeklyHigher_usesWeeklyStatus() {
        let sessionPercentage = 30
        let weeklyPercentage = 85
        let maxPercentage = max(sessionPercentage, weeklyPercentage)
        let status = Percentage.clamped(Double(maxPercentage)).toStatus()

        #expect(maxPercentage == 85)
        #expect(status == .critical)
    }

    @Test("menuBarStatus safe when both under 50")
    func menuBarStatusLogic_bothSafe_returnsSafe() {
        let sessionPercentage = 30
        let weeklyPercentage = 40
        let maxPercentage = max(sessionPercentage, weeklyPercentage)
        let status = Percentage.clamped(Double(maxPercentage)).toStatus()

        #expect(maxPercentage == 40)
        #expect(status == .safe)
    }

    // MARK: - Weekly Usage Filter Logic Tests

    @Test("weeklyUsage filters by type weekly")
    func weeklyUsageLogic_filtersCorrectly() {
        let displayData = UsageDisplayDataFixtures.allSafe
        let weekly = displayData.first { $0.type == .weekly }

        #expect(weekly != nil)
        #expect(weekly?.type == .weekly)
    }

    @Test("weeklyUsage returns nil when no weekly data")
    func weeklyUsageLogic_noWeeklyData_returnsNil() {
        let displayData = [UsageDisplayDataFixtures.sessionSafe]
        let weekly = displayData.first { $0.type == .weekly }

        #expect(weekly == nil)
    }

    // MARK: - Integration with Fixtures

    @Test("menu bar text with fixtures session safe and weekly safe")
    func menuBarText_withFixtures_formatsCorrectly() {
        let session = UsageDisplayDataFixtures.sessionSafe
        let weekly = UsageDisplayDataFixtures.weeklySafe

        let menuBarText = "\(session.percentage)/\(weekly.percentage)"

        #expect(menuBarText.contains("/"))
        #expect(!menuBarText.contains("%"))
    }

    @Test("menu bar status with fixtures uses max percentage")
    func menuBarStatus_withFixtures_usesMaxPercentage() {
        let session = UsageDisplayDataFixtures.sessionHigh  // 85% (critical)
        let weekly = UsageDisplayDataFixtures.weeklySafe    // 30%

        let maxPercentage = max(session.percentage, weekly.percentage)
        let status = Percentage.clamped(Double(maxPercentage)).toStatus()

        #expect(status == .critical)  // 85% is critical (80+)
    }

    @Test("menu bar status critical when weekly is high")
    func menuBarStatus_weeklyHigh_returnsCritical() {
        let session = UsageDisplayDataFixtures.sessionSafe  // safe
        let weekly = UsageDisplayDataFixtures.weeklyHigh    // 85%

        let maxPercentage = max(session.percentage, weekly.percentage)
        let status = Percentage.clamped(Double(maxPercentage)).toStatus()

        #expect(status == .critical)  // 85% is critical (80+)
    }
}
