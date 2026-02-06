import Testing
import Foundation
@testable import AIMeterDomain

@Suite("Percentage")
struct PercentageTests {

    // MARK: - Creation Tests

    @Test("create with valid percentage")
    func createValid() throws {
        let percentage = try Percentage.create(75.5)
        #expect(percentage.value == 75.5)
    }

    @Test("create with zero")
    func createZero() throws {
        let percentage = try Percentage.create(0.0)
        #expect(percentage.value == 0.0)
    }

    @Test("create with 100")
    func createHundred() throws {
        let percentage = try Percentage.create(100.0)
        #expect(percentage.value == 100.0)
    }

    @Test("create throws for negative value")
    func createNegative() {
        #expect(throws: DomainError.self) {
            try Percentage.create(-0.1)
        }
    }

    @Test("create throws for value over 100")
    func createOverHundred() {
        #expect(throws: DomainError.self) {
            try Percentage.create(100.1)
        }
    }

    // MARK: - Clamped Tests

    @Test("clamped clamps negative to zero")
    func clampedNegative() {
        let percentage = Percentage.clamped(-50.0)
        #expect(percentage.value == 0.0)
    }

    @Test("clamped clamps over 100 to 100")
    func clampedOverHundred() {
        let percentage = Percentage.clamped(150.0)
        #expect(percentage.value == 100.0)
    }

    @Test("clamped keeps valid value")
    func clampedValid() {
        let percentage = Percentage.clamped(75.5)
        #expect(percentage.value == 75.5)
    }

    // MARK: - Zero Static Property

    @Test("zero static property")
    func zeroProperty() {
        #expect(Percentage.zero.value == 0.0)
    }

    // MARK: - toStatus Tests

    @Test("toStatus returns safe for 0%")
    func statusSafeZero() throws {
        let percentage = try Percentage.create(0.0)
        #expect(percentage.toStatus() == .safe)
    }

    @Test("toStatus returns safe for 25%")
    func statusSafeMid() throws {
        let percentage = try Percentage.create(25.0)
        #expect(percentage.toStatus() == .safe)
    }

    @Test("toStatus returns safe for 49.9%")
    func statusSafeBoundary() throws {
        let percentage = try Percentage.create(49.9)
        #expect(percentage.toStatus() == .safe)
    }

    @Test("toStatus returns moderate for 50%")
    func statusModerateStart() throws {
        let percentage = try Percentage.create(50.0)
        #expect(percentage.toStatus() == .moderate)
    }

    @Test("toStatus returns moderate for 65%")
    func statusModerateMid() throws {
        let percentage = try Percentage.create(65.0)
        #expect(percentage.toStatus() == .moderate)
    }

    @Test("toStatus returns moderate for 79.9%")
    func statusModerateBoundary() throws {
        let percentage = try Percentage.create(79.9)
        #expect(percentage.toStatus() == .moderate)
    }

    @Test("toStatus returns critical for 80%")
    func statusCriticalStart() throws {
        let percentage = try Percentage.create(80.0)
        #expect(percentage.toStatus() == .critical)
    }

    @Test("toStatus returns critical for 95%")
    func statusCriticalMid() throws {
        let percentage = try Percentage.create(95.0)
        #expect(percentage.toStatus() == .critical)
    }

    @Test("toStatus returns critical for 100%")
    func statusCriticalMax() throws {
        let percentage = try Percentage.create(100.0)
        #expect(percentage.toStatus() == .critical)
    }

    // MARK: - Formatted Tests

    @Test("formatted displays whole number")
    func formattedWhole() throws {
        let percentage = try Percentage.create(75.0)
        #expect(percentage.formatted == "75%")
    }

    @Test("formatted truncates decimal to integer")
    func formattedDecimal() throws {
        let percentage = try Percentage.create(75.5)
        #expect(percentage.formatted == "75%")
    }

    @Test("formatted displays zero")
    func formattedZero() {
        #expect(Percentage.zero.formatted == "0%")
    }

    @Test("formatted displays 100")
    func formattedHundred() throws {
        let percentage = try Percentage.create(100.0)
        #expect(percentage.formatted == "100%")
    }

    // MARK: - Equatable Tests

    @Test("equatable compares values correctly")
    func equatable() throws {
        let p1 = try Percentage.create(75.5)
        let p2 = try Percentage.create(75.5)
        let p3 = try Percentage.create(80.0)

        #expect(p1 == p2)
        #expect(p1 != p3)
    }

    // MARK: - Codable Tests

    @Test("codable encodes and decodes correctly")
    func codable() throws {
        let original = try Percentage.create(65.5)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Percentage.self, from: encoded)

        #expect(original == decoded)
    }
}
