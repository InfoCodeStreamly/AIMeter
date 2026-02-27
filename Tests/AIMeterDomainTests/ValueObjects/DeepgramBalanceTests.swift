import Testing
@testable import AIMeterDomain

@Suite("DeepgramBalance")
struct DeepgramBalanceTests {

    // MARK: - Init Tests

    @Test("init stores amount and units")
    func initStoresValues() {
        let balance = DeepgramBalance(amount: 187.50, units: "usd")
        #expect(balance.amount == 187.50)
        #expect(balance.units == "usd")
    }

    // MARK: - displayText Tests

    @Test("displayText formats usd correctly")
    func displayTextUsd() {
        let balance = DeepgramBalance(amount: 187.50, units: "usd")
        #expect(balance.displayText == "$187.50 remaining")
    }

    @Test("displayText handles zero amount")
    func displayTextZero() {
        let balance = DeepgramBalance(amount: 0.0, units: "usd")
        #expect(balance.displayText == "$0.00 remaining")
    }

    @Test("displayText formats large amounts correctly")
    func displayTextLargeAmount() {
        let balance = DeepgramBalance(amount: 12345.67, units: "usd")
        #expect(balance.displayText == "$12345.67 remaining")
    }

    // MARK: - Equatable Tests

    @Test("same values are equal")
    func equatableSame() {
        let balance1 = DeepgramBalance(amount: 100.0, units: "usd")
        let balance2 = DeepgramBalance(amount: 100.0, units: "usd")
        #expect(balance1 == balance2)
    }

    @Test("different amounts are not equal")
    func equatableDifferentAmounts() {
        let balance1 = DeepgramBalance(amount: 100.0, units: "usd")
        let balance2 = DeepgramBalance(amount: 200.0, units: "usd")
        #expect(balance1 != balance2)
    }
}
