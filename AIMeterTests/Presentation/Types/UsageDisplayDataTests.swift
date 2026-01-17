import Testing
@testable import AIMeter

@Suite("UsageDisplayData")
struct UsageDisplayDataTests {

    // MARK: - Initialization

    @Test("init maps resetTimeText from entity")
    func init_mapsResetTimeText() {
        let entity = UsageEntityFixtures.sessionSafe

        let displayData = UsageDisplayData(from: entity)

        #expect(!displayData.resetTimeText.isEmpty)
    }

    @Test("init maps all properties from entity")
    func init_mapsAllProperties() {
        let entity = UsageEntityFixtures.sessionSafe

        let displayData = UsageDisplayData(from: entity)

        #expect(displayData.id == entity.id)
        #expect(displayData.type == entity.type)
        #expect(displayData.percentage == Int(entity.percentage.value))
        #expect(displayData.status == entity.status)
        #expect(displayData.title == entity.type.displayName)
        #expect(displayData.subtitle == entity.type.subtitle)
    }

    // MARK: - Computed Properties

    @Test("percentageText formats correctly")
    func percentageText_formatsCorrectly() {
        let entity = UsageEntityFixtures.sessionSafe

        let displayData = UsageDisplayData(from: entity)

        #expect(displayData.percentageText.contains("%"))
    }

    @Test("isCritical returns true for critical status")
    func isCritical_criticalStatus_returnsTrue() {
        let entity = UsageEntityFixtures.sessionCritical

        let displayData = UsageDisplayData(from: entity)

        #expect(displayData.isCritical)
    }

    @Test("isCritical returns false for safe status")
    func isCritical_safeStatus_returnsFalse() {
        let entity = UsageEntityFixtures.sessionSafe

        let displayData = UsageDisplayData(from: entity)

        #expect(!displayData.isCritical)
    }

    // MARK: - Color and Icon

    @Test("color matches status color")
    func color_matchesStatusColor() {
        let entity = UsageEntityFixtures.sessionSafe

        let displayData = UsageDisplayData(from: entity)

        #expect(displayData.color == entity.status.color)
    }

    @Test("icon matches status icon")
    func icon_matchesStatusIcon() {
        let entity = UsageEntityFixtures.sessionSafe

        let displayData = UsageDisplayData(from: entity)

        #expect(displayData.icon == entity.status.icon)
    }
}
