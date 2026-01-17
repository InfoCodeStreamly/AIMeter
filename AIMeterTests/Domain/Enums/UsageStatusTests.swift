import Testing
import SwiftUI
@testable import AIMeter

@Suite("UsageStatus")
struct UsageStatusTests {

    // MARK: - Color Tests

    @Test("safe status has green color")
    func color_safe_isGreen() {
        #expect(UsageStatus.safe.color == .green)
    }

    @Test("moderate status has orange color")
    func color_moderate_isOrange() {
        #expect(UsageStatus.moderate.color == .orange)
    }

    @Test("critical status has red color")
    func color_critical_isRed() {
        #expect(UsageStatus.critical.color == .red)
    }

    // MARK: - Icon Tests

    @Test("safe status has checkmark icon")
    func icon_safe_isCheckmark() {
        #expect(UsageStatus.safe.icon == "checkmark.circle.fill")
    }

    @Test("moderate status has warning icon")
    func icon_moderate_isWarning() {
        #expect(UsageStatus.moderate.icon == "exclamationmark.triangle.fill")
    }

    @Test("critical status has error icon")
    func icon_critical_isError() {
        #expect(UsageStatus.critical.icon == "xmark.circle.fill")
    }

    // MARK: - Description Tests

    @Test("safe status description is Good")
    func description_safe_isGood() {
        #expect(UsageStatus.safe.description == "Good")
    }

    @Test("moderate status description is Moderate")
    func description_moderate_isModerate() {
        #expect(UsageStatus.moderate.description == "Moderate")
    }

    @Test("critical status description is Near Limit")
    func description_critical_isNearLimit() {
        #expect(UsageStatus.critical.description == "Near Limit")
    }
}
