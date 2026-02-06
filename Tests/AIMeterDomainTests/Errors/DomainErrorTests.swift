import Testing
@testable import AIMeterDomain

@Suite("DomainError")
struct DomainErrorTests {

    // MARK: - Cases Tests

    @Test("invalidPercentage case")
    func invalidPercentageCase() {
        let error = DomainError.invalidPercentage(150.0)
        if case .invalidPercentage(let value) = error {
            #expect(value == 150.0)
        } else {
            Issue.record("Expected invalidPercentage case")
        }
    }

    @Test("emptySessionKey case")
    func emptySessionKeyCase() {
        let error = DomainError.emptySessionKey
        if case .emptySessionKey = error {
            // Success
        } else {
            Issue.record("Expected emptySessionKey case")
        }
    }

    @Test("invalidSessionKeyFormat case")
    func invalidSessionKeyFormatCase() {
        let error = DomainError.invalidSessionKeyFormat
        if case .invalidSessionKeyFormat = error {
            // Success
        } else {
            Issue.record("Expected invalidSessionKeyFormat case")
        }
    }

    @Test("sessionKeyNotFound case")
    func sessionKeyNotFoundCase() {
        let error = DomainError.sessionKeyNotFound
        if case .sessionKeyNotFound = error {
            // Success
        } else {
            Issue.record("Expected sessionKeyNotFound case")
        }
    }

    @Test("sessionKeyExpired case")
    func sessionKeyExpiredCase() {
        let error = DomainError.sessionKeyExpired
        if case .sessionKeyExpired = error {
            // Success
        } else {
            Issue.record("Expected sessionKeyExpired case")
        }
    }

    // MARK: - errorDescription Tests

    @Test("invalidPercentage error description")
    func invalidPercentageDescription() {
        let error = DomainError.invalidPercentage(150.0)
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description!.contains("150"))
    }

    @Test("invalidPercentage description for negative value")
    func invalidPercentageNegativeDescription() {
        let error = DomainError.invalidPercentage(-10.0)
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description!.contains("-10"))
    }

    @Test("emptySessionKey error description")
    func emptySessionKeyDescription() {
        let error = DomainError.emptySessionKey
        let description = error.errorDescription

        #expect(description != nil)
        #expect(!description!.isEmpty)
    }

    @Test("invalidSessionKeyFormat error description")
    func invalidSessionKeyFormatDescription() {
        let error = DomainError.invalidSessionKeyFormat
        let description = error.errorDescription

        #expect(description != nil)
        #expect(!description!.isEmpty)
    }

    @Test("sessionKeyNotFound error description")
    func sessionKeyNotFoundDescription() {
        let error = DomainError.sessionKeyNotFound
        let description = error.errorDescription

        #expect(description != nil)
        #expect(!description!.isEmpty)
    }

    @Test("sessionKeyExpired error description")
    func sessionKeyExpiredDescription() {
        let error = DomainError.sessionKeyExpired
        let description = error.errorDescription

        #expect(description != nil)
        #expect(!description!.isEmpty)
    }

    // MARK: - Equatable Tests

    @Test("invalidPercentage equality with same value")
    func invalidPercentageEqualitySame() {
        let error1 = DomainError.invalidPercentage(150.0)
        let error2 = DomainError.invalidPercentage(150.0)
        #expect(error1 == error2)
    }

    @Test("invalidPercentage inequality with different values")
    func invalidPercentageInequalityDifferent() {
        let error1 = DomainError.invalidPercentage(150.0)
        let error2 = DomainError.invalidPercentage(-10.0)
        #expect(error1 != error2)
    }

    @Test("emptySessionKey equality")
    func emptySessionKeyEquality() {
        let error1 = DomainError.emptySessionKey
        let error2 = DomainError.emptySessionKey
        #expect(error1 == error2)
    }

    @Test("invalidSessionKeyFormat equality")
    func invalidSessionKeyFormatEquality() {
        let error1 = DomainError.invalidSessionKeyFormat
        let error2 = DomainError.invalidSessionKeyFormat
        #expect(error1 == error2)
    }

    @Test("sessionKeyNotFound equality")
    func sessionKeyNotFoundEquality() {
        let error1 = DomainError.sessionKeyNotFound
        let error2 = DomainError.sessionKeyNotFound
        #expect(error1 == error2)
    }

    @Test("sessionKeyExpired equality")
    func sessionKeyExpiredEquality() {
        let error1 = DomainError.sessionKeyExpired
        let error2 = DomainError.sessionKeyExpired
        #expect(error1 == error2)
    }

    @Test("different error cases are not equal")
    func differentCasesNotEqual() {
        let error1 = DomainError.emptySessionKey
        let error2 = DomainError.invalidSessionKeyFormat
        let error3 = DomainError.sessionKeyNotFound
        let error4 = DomainError.sessionKeyExpired
        let error5 = DomainError.invalidPercentage(150.0)

        #expect(error1 != error2)
        #expect(error1 != error3)
        #expect(error1 != error4)
        #expect(error1 != error5)
        #expect(error2 != error3)
        #expect(error2 != error4)
        #expect(error2 != error5)
        #expect(error3 != error4)
        #expect(error3 != error5)
        #expect(error4 != error5)
    }

    // MARK: - LocalizedError Conformance

    @Test("all errors provide localized descriptions")
    func localizedDescriptions() {
        let errors: [DomainError] = [
            .invalidPercentage(150.0),
            .emptySessionKey,
            .invalidSessionKeyFormat,
            .sessionKeyNotFound,
            .sessionKeyExpired
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    // MARK: - Sendable Conformance

    @Test("sendable conformance compiles")
    func sendableConformance() {
        let error: DomainError = .emptySessionKey
        let closure: @Sendable () -> DomainError = { error }
        #expect(closure() == .emptySessionKey)
    }

    // MARK: - Error Throwing Tests

    @Test("can be thrown as Error")
    func throwableAsError() {
        do {
            throw DomainError.emptySessionKey
        } catch {
            #expect(error is DomainError)
            if let domainError = error as? DomainError {
                #expect(domainError == .emptySessionKey)
            }
        }
    }

    @Test("can be caught with specific type")
    func catchSpecificType() {
        var caught = false
        do {
            throw DomainError.invalidSessionKeyFormat
        } catch let error as DomainError {
            caught = true
            #expect(error == .invalidSessionKeyFormat)
        } catch {
            Issue.record("Unexpected error type")
        }
        #expect(caught)
    }

    @Test("invalidPercentage can be pattern matched")
    func patternMatch() {
        let error = DomainError.invalidPercentage(200.0)
        var matched = false

        switch error {
        case .invalidPercentage(let value):
            matched = true
            #expect(value == 200.0)
        default:
            Issue.record("Pattern match failed")
        }

        #expect(matched)
    }

    // MARK: - Edge Cases

    @Test("invalidPercentage with zero")
    func invalidPercentageZero() {
        let error = DomainError.invalidPercentage(0.0)
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description!.contains("0"))
    }

    @Test("invalidPercentage with very large value")
    func invalidPercentageVeryLarge() {
        let error = DomainError.invalidPercentage(999999.0)
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description!.contains("999999"))
    }

    @Test("invalidPercentage with decimal value")
    func invalidPercentageDecimal() {
        let error = DomainError.invalidPercentage(150.5)
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description!.contains("150"))
    }

    // MARK: - Description Content Tests

    @Test("error descriptions are meaningful")
    func meaningfulDescriptions() {
        let errors: [DomainError] = [
            .invalidPercentage(150.0),
            .emptySessionKey,
            .invalidSessionKeyFormat,
            .sessionKeyNotFound,
            .sessionKeyExpired
        ]

        for error in errors {
            let description = error.errorDescription!
            // Verify description has reasonable length (not just placeholder)
            #expect(description.count > 10)
        }
    }
}
