import Testing
@testable import AIMeter

@Suite("Percentage")
struct PercentageTests {

    // MARK: - toStatus() Safe Range (0-49)

    @Test("toStatus returns safe for 0%")
    func toStatus_zero_returnsSafe() {
        let percentage = Percentage.clamped(0)
        #expect(percentage.toStatus() == .safe)
    }

    @Test("toStatus returns safe for 25%")
    func toStatus_25_returnsSafe() {
        let percentage = Percentage.clamped(25)
        #expect(percentage.toStatus() == .safe)
    }

    @Test("toStatus returns safe for 49%")
    func toStatus_49_returnsSafe() {
        let percentage = Percentage.clamped(49)
        #expect(percentage.toStatus() == .safe)
    }

    // MARK: - toStatus() Moderate Range (50-79)

    @Test("toStatus returns moderate for 50%")
    func toStatus_50_returnsModerate() {
        let percentage = Percentage.clamped(50)
        #expect(percentage.toStatus() == .moderate)
    }

    @Test("toStatus returns moderate for 65%")
    func toStatus_65_returnsModerate() {
        let percentage = Percentage.clamped(65)
        #expect(percentage.toStatus() == .moderate)
    }

    @Test("toStatus returns moderate for 79%")
    func toStatus_79_returnsModerate() {
        let percentage = Percentage.clamped(79)
        #expect(percentage.toStatus() == .moderate)
    }

    // MARK: - toStatus() Critical Range (80-100)

    @Test("toStatus returns critical for 80%")
    func toStatus_80_returnsCritical() {
        let percentage = Percentage.clamped(80)
        #expect(percentage.toStatus() == .critical)
    }

    @Test("toStatus returns critical for 90%")
    func toStatus_90_returnsCritical() {
        let percentage = Percentage.clamped(90)
        #expect(percentage.toStatus() == .critical)
    }

    @Test("toStatus returns critical for 100%")
    func toStatus_100_returnsCritical() {
        let percentage = Percentage.clamped(100)
        #expect(percentage.toStatus() == .critical)
    }

    // MARK: - Clamped Tests

    @Test("clamped clamps negative values to 0")
    func clamped_negative_clampsToZero() {
        let percentage = Percentage.clamped(-10)
        #expect(percentage.value == 0)
    }

    @Test("clamped clamps values over 100 to 100")
    func clamped_over100_clampsTo100() {
        let percentage = Percentage.clamped(150)
        #expect(percentage.value == 100)
    }

    // MARK: - Formatted Tests

    @Test("formatted returns string with percent sign")
    func formatted_returnsPercentString() {
        let percentage = Percentage.clamped(75)
        #expect(percentage.formatted == "75%")
    }
}
