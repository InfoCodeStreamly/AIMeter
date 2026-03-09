import Testing
@testable import AIMeterDomain

/// Tests for BucketWidth enum — raw values and CaseIterable conformance.
@Suite("BucketWidth")
struct BucketWidthTests {

    // MARK: - Raw Value Tests

    @Test("minute case has raw value 1m")
    func minuteRawValue() {
        #expect(BucketWidth.minute.rawValue == "1m")
    }

    @Test("hour case has raw value 1h")
    func hourRawValue() {
        #expect(BucketWidth.hour.rawValue == "1h")
    }

    @Test("day case has raw value 1d")
    func dayRawValue() {
        #expect(BucketWidth.day.rawValue == "1d")
    }

    // MARK: - CaseIterable Tests

    @Test("allCases contains exactly 3 cases")
    func allCasesCountIsThree() {
        #expect(BucketWidth.allCases.count == 3)
    }

    @Test("allCases contains minute")
    func allCasesContainsMinute() {
        #expect(BucketWidth.allCases.contains(.minute))
    }

    @Test("allCases contains hour")
    func allCasesContainsHour() {
        #expect(BucketWidth.allCases.contains(.hour))
    }

    @Test("allCases contains day")
    func allCasesContainsDay() {
        #expect(BucketWidth.allCases.contains(.day))
    }

    // MARK: - Raw Value Initialization Tests

    @Test("init from raw value 1m returns minute")
    func initFromRawValue1m() {
        let width = BucketWidth(rawValue: "1m")
        #expect(width == .minute)
    }

    @Test("init from raw value 1h returns hour")
    func initFromRawValue1h() {
        let width = BucketWidth(rawValue: "1h")
        #expect(width == .hour)
    }

    @Test("init from raw value 1d returns day")
    func initFromRawValue1d() {
        let width = BucketWidth(rawValue: "1d")
        #expect(width == .day)
    }

    @Test("init from unknown raw value returns nil")
    func initFromUnknownRawValueReturnsNil() {
        let width = BucketWidth(rawValue: "5m")
        #expect(width == nil)
    }

    @Test("init from empty raw value returns nil")
    func initFromEmptyRawValueReturnsNil() {
        let width = BucketWidth(rawValue: "")
        #expect(width == nil)
    }

    // MARK: - Equatable Tests

    @Test("same cases are equal")
    func sameCasesAreEqual() {
        #expect(BucketWidth.minute == BucketWidth.minute)
        #expect(BucketWidth.hour == BucketWidth.hour)
        #expect(BucketWidth.day == BucketWidth.day)
    }

    @Test("different cases are not equal")
    func differentCasesAreNotEqual() {
        #expect(BucketWidth.minute != BucketWidth.hour)
        #expect(BucketWidth.hour != BucketWidth.day)
        #expect(BucketWidth.minute != BucketWidth.day)
    }
}
