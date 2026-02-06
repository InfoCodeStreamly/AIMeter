import Testing
import Foundation
@testable import AIMeterDomain

@Suite("UsageType")
struct UsageTypeTests {

    // MARK: - Cases Tests

    @Test("all cases are present")
    func allCases() {
        let cases = UsageType.allCases
        #expect(cases.count == 4)
        #expect(cases.contains(.session))
        #expect(cases.contains(.weekly))
        #expect(cases.contains(.opus))
        #expect(cases.contains(.sonnet))
    }

    // MARK: - Raw Value Tests

    @Test("session raw value")
    func sessionRawValue() {
        #expect(UsageType.session.rawValue == "session")
    }

    @Test("weekly raw value")
    func weeklyRawValue() {
        #expect(UsageType.weekly.rawValue == "weekly")
    }

    @Test("opus raw value")
    func opusRawValue() {
        #expect(UsageType.opus.rawValue == "opus")
    }

    @Test("sonnet raw value")
    func sonnetRawValue() {
        #expect(UsageType.sonnet.rawValue == "sonnet")
    }

    @Test("initialize from raw value")
    func initFromRawValue() {
        #expect(UsageType(rawValue: "session") == .session)
        #expect(UsageType(rawValue: "weekly") == .weekly)
        #expect(UsageType(rawValue: "opus") == .opus)
        #expect(UsageType(rawValue: "sonnet") == .sonnet)
        #expect(UsageType(rawValue: "invalid") == nil)
    }

    // MARK: - isPrimary Tests

    @Test("session is primary")
    func sessionIsPrimary() {
        #expect(UsageType.session.isPrimary == true)
    }

    @Test("weekly is not primary")
    func weeklyNotPrimary() {
        #expect(UsageType.weekly.isPrimary == false)
    }

    @Test("opus is not primary")
    func opusNotPrimary() {
        #expect(UsageType.opus.isPrimary == false)
    }

    @Test("sonnet is not primary")
    func sonnetNotPrimary() {
        #expect(UsageType.sonnet.isPrimary == false)
    }

    @Test("only session is primary")
    func onlySessionPrimary() {
        let primaryCount = UsageType.allCases.filter { $0.isPrimary }.count
        #expect(primaryCount == 1)
    }

    // MARK: - Codable Tests

    @Test("encode session")
    func encodeSession() throws {
        let type = UsageType.session
        let encoded = try JSONEncoder().encode(type)
        let json = String(data: encoded, encoding: .utf8)!
        #expect(json.contains("session"))
    }

    @Test("encode weekly")
    func encodeWeekly() throws {
        let type = UsageType.weekly
        let encoded = try JSONEncoder().encode(type)
        let json = String(data: encoded, encoding: .utf8)!
        #expect(json.contains("weekly"))
    }

    @Test("encode opus")
    func encodeOpus() throws {
        let type = UsageType.opus
        let encoded = try JSONEncoder().encode(type)
        let json = String(data: encoded, encoding: .utf8)!
        #expect(json.contains("opus"))
    }

    @Test("encode sonnet")
    func encodeSonnet() throws {
        let type = UsageType.sonnet
        let encoded = try JSONEncoder().encode(type)
        let json = String(data: encoded, encoding: .utf8)!
        #expect(json.contains("sonnet"))
    }

    @Test("decode session")
    func decodeSession() throws {
        let json = "\"session\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(UsageType.self, from: json)
        #expect(decoded == .session)
    }

    @Test("decode weekly")
    func decodeWeekly() throws {
        let json = "\"weekly\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(UsageType.self, from: json)
        #expect(decoded == .weekly)
    }

    @Test("decode opus")
    func decodeOpus() throws {
        let json = "\"opus\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(UsageType.self, from: json)
        #expect(decoded == .opus)
    }

    @Test("decode sonnet")
    func decodeSonnet() throws {
        let json = "\"sonnet\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(UsageType.self, from: json)
        #expect(decoded == .sonnet)
    }

    @Test("decode invalid type throws")
    func decodeInvalid() {
        let json = "\"invalid\"".data(using: .utf8)!
        #expect(throws: Error.self) {
            _ = try JSONDecoder().decode(UsageType.self, from: json)
        }
    }

    @Test("roundtrip encoding and decoding")
    func codableRoundtrip() throws {
        let types: [UsageType] = [.session, .weekly, .opus, .sonnet]

        for type in types {
            let encoded = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(UsageType.self, from: encoded)
            #expect(decoded == type)
        }
    }

    // MARK: - Sendable Conformance

    @Test("sendable conformance compiles")
    func sendableConformance() {
        let type: UsageType = .session
        let closure: @Sendable () -> UsageType = { type }
        #expect(closure() == .session)
    }

    // MARK: - Equality Tests

    @Test("equality for same cases")
    func equalitySame() {
        #expect(UsageType.session == UsageType.session)
        #expect(UsageType.weekly == UsageType.weekly)
        #expect(UsageType.opus == UsageType.opus)
        #expect(UsageType.sonnet == UsageType.sonnet)
    }

    @Test("inequality for different cases")
    func inequalityDifferent() {
        #expect(UsageType.session != UsageType.weekly)
        #expect(UsageType.session != UsageType.opus)
        #expect(UsageType.session != UsageType.sonnet)
        #expect(UsageType.weekly != UsageType.opus)
        #expect(UsageType.weekly != UsageType.sonnet)
        #expect(UsageType.opus != UsageType.sonnet)
    }

    // MARK: - Collection Tests

    @Test("filter primary types")
    func filterPrimary() {
        let primaryTypes = UsageType.allCases.filter { $0.isPrimary }
        #expect(primaryTypes.count == 1)
        #expect(primaryTypes.first == .session)
    }

    @Test("filter non-primary types")
    func filterNonPrimary() {
        let nonPrimaryTypes = UsageType.allCases.filter { !$0.isPrimary }
        #expect(nonPrimaryTypes.count == 3)
        #expect(nonPrimaryTypes.contains(.weekly))
        #expect(nonPrimaryTypes.contains(.opus))
        #expect(nonPrimaryTypes.contains(.sonnet))
    }
}
