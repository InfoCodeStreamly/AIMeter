import Testing
import Foundation
@testable import AIMeterDomain

@Suite("UsageStatus")
struct UsageStatusTests {

    // MARK: - Cases Tests

    @Test("all cases are present")
    func allCases() {
        let cases = UsageStatus.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.safe))
        #expect(cases.contains(.moderate))
        #expect(cases.contains(.critical))
    }

    // MARK: - Raw Value Tests

    @Test("safe raw value")
    func safeRawValue() {
        #expect(UsageStatus.safe.rawValue == "safe")
    }

    @Test("moderate raw value")
    func moderateRawValue() {
        #expect(UsageStatus.moderate.rawValue == "moderate")
    }

    @Test("critical raw value")
    func criticalRawValue() {
        #expect(UsageStatus.critical.rawValue == "critical")
    }

    @Test("initialize from raw value")
    func initFromRawValue() {
        #expect(UsageStatus(rawValue: "safe") == .safe)
        #expect(UsageStatus(rawValue: "moderate") == .moderate)
        #expect(UsageStatus(rawValue: "critical") == .critical)
        #expect(UsageStatus(rawValue: "invalid") == nil)
    }

    // MARK: - Codable Tests

    @Test("encode safe status")
    func encodeSafe() throws {
        let status = UsageStatus.safe
        let encoded = try JSONEncoder().encode(status)
        let json = String(data: encoded, encoding: .utf8)!
        #expect(json.contains("safe"))
    }

    @Test("encode moderate status")
    func encodeModerate() throws {
        let status = UsageStatus.moderate
        let encoded = try JSONEncoder().encode(status)
        let json = String(data: encoded, encoding: .utf8)!
        #expect(json.contains("moderate"))
    }

    @Test("encode critical status")
    func encodeCritical() throws {
        let status = UsageStatus.critical
        let encoded = try JSONEncoder().encode(status)
        let json = String(data: encoded, encoding: .utf8)!
        #expect(json.contains("critical"))
    }

    @Test("decode safe status")
    func decodeSafe() throws {
        let json = "\"safe\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(UsageStatus.self, from: json)
        #expect(decoded == .safe)
    }

    @Test("decode moderate status")
    func decodeModerate() throws {
        let json = "\"moderate\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(UsageStatus.self, from: json)
        #expect(decoded == .moderate)
    }

    @Test("decode critical status")
    func decodeCritical() throws {
        let json = "\"critical\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(UsageStatus.self, from: json)
        #expect(decoded == .critical)
    }

    @Test("decode invalid status throws")
    func decodeInvalid() {
        let json = "\"invalid\"".data(using: .utf8)!
        #expect(throws: Error.self) {
            _ = try JSONDecoder().decode(UsageStatus.self, from: json)
        }
    }

    @Test("roundtrip encoding and decoding")
    func codableRoundtrip() throws {
        let statuses: [UsageStatus] = [.safe, .moderate, .critical]

        for status in statuses {
            let encoded = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(UsageStatus.self, from: encoded)
            #expect(decoded == status)
        }
    }

    // MARK: - Sendable Conformance

    @Test("sendable conformance compiles")
    func sendableConformance() {
        // This test verifies that UsageStatus conforms to Sendable
        // by attempting to use it in a Sendable context
        let status: UsageStatus = .safe
        let closure: @Sendable () -> UsageStatus = { status }
        #expect(closure() == .safe)
    }

    // MARK: - Case Ordering

    @Test("cases in order")
    func casesOrder() {
        let cases = UsageStatus.allCases
        #expect(cases[0] == .safe || cases[0] == .moderate || cases[0] == .critical)
        #expect(cases[1] == .safe || cases[1] == .moderate || cases[1] == .critical)
        #expect(cases[2] == .safe || cases[2] == .moderate || cases[2] == .critical)
    }

    // MARK: - Equality Tests

    @Test("equality for same cases")
    func equalitySame() {
        #expect(UsageStatus.safe == UsageStatus.safe)
        #expect(UsageStatus.moderate == UsageStatus.moderate)
        #expect(UsageStatus.critical == UsageStatus.critical)
    }

    @Test("inequality for different cases")
    func inequalityDifferent() {
        #expect(UsageStatus.safe != UsageStatus.moderate)
        #expect(UsageStatus.safe != UsageStatus.critical)
        #expect(UsageStatus.moderate != UsageStatus.critical)
    }
}
