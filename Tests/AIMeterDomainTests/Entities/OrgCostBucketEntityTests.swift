import Testing
@testable import AIMeterDomain
import Foundation

/// Tests for OrgCostBucketEntity domain entity.
@Suite("OrgCostBucketEntity")
struct OrgCostBucketEntityTests {

    private let startTime = Date(timeIntervalSince1970: 1_700_000_000)
    private let endTime   = Date(timeIntervalSince1970: 1_700_003_600)

    // MARK: - Init Tests

    @Test("init stores all provided values")
    func initStoresAllValues() {
        let id = UUID()
        let entity = OrgCostBucketEntity(
            id: id,
            startTime: startTime,
            endTime: endTime,
            workspaceId: "ws-abc",
            costDescription: "Claude API usage",
            amountCents: 1250,
            currency: "USD"
        )

        #expect(entity.id == id)
        #expect(entity.startTime == startTime)
        #expect(entity.endTime == endTime)
        #expect(entity.workspaceId == "ws-abc")
        #expect(entity.costDescription == "Claude API usage")
        #expect(entity.amountCents == 1250)
        #expect(entity.currency == "USD")
    }

    @Test("init with defaults uses USD currency")
    func initDefaultsUSDCurrency() {
        let entity = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 500
        )

        #expect(entity.currency == "USD")
    }

    @Test("init with defaults uses nil for optional fields")
    func initDefaultsNilOptionals() {
        let entity = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 100
        )

        #expect(entity.workspaceId == nil)
        #expect(entity.costDescription == nil)
    }

    @Test("init generates unique id when not provided")
    func initGeneratesUniqueId() {
        let entity1 = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 100
        )
        let entity2 = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 100
        )

        #expect(entity1.id != entity2.id)
    }

    // MARK: - amountDollars Tests

    @Test("amountDollars converts 1250 cents to 12.50 dollars")
    func amountDollarsConverts1250CentsToCorrectDollars() {
        let entity = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 1250
        )

        #expect(entity.amountDollars == 12.5)
    }

    @Test("amountDollars converts 100 cents to 1.00 dollar")
    func amountDollarsConverts100CentsToOneDollar() {
        let entity = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 100
        )

        #expect(entity.amountDollars == 1.0)
    }

    @Test("amountDollars returns zero for zero cents")
    func amountDollarsReturnsZeroForZero() {
        let entity = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 0
        )

        #expect(entity.amountDollars == 0.0)
    }

    @Test("amountDollars converts 1 cent to 0.01 dollar")
    func amountDollarsConverts1CentToOnePenny() {
        let entity = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 1
        )

        #expect(entity.amountDollars == 0.01)
    }

    @Test("amountDollars converts large amount correctly")
    func amountDollarsConvertsLargeAmount() {
        let entity = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 100_000
        )

        #expect(entity.amountDollars == 1000.0)
    }

    @Test("amountDollars divides by 100")
    func amountDollarsDividesByHundred() {
        let entity = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 750
        )

        #expect(entity.amountDollars == 7.5)
    }

    // MARK: - costDescription Property Tests

    @Test("costDescription stores provided string value")
    func costDescriptionStoresValue() {
        let entity = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            costDescription: "Monthly API charges",
            amountCents: 500
        )

        #expect(entity.costDescription == "Monthly API charges")
    }

    @Test("costDescription is nil when not provided")
    func costDescriptionIsNilByDefault() {
        let entity = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 500
        )

        #expect(entity.costDescription == nil)
    }

    // MARK: - Equatable Tests

    @Test("two entities with same id and values are equal")
    func equatableSameValues() {
        let id = UUID()
        let entity1 = OrgCostBucketEntity(
            id: id,
            startTime: startTime,
            endTime: endTime,
            amountCents: 1250
        )
        let entity2 = OrgCostBucketEntity(
            id: id,
            startTime: startTime,
            endTime: endTime,
            amountCents: 1250
        )

        #expect(entity1 == entity2)
    }

    @Test("two entities with different ids are not equal")
    func equatableDifferentIds() {
        let entity1 = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 1250
        )
        let entity2 = OrgCostBucketEntity(
            startTime: startTime,
            endTime: endTime,
            amountCents: 1250
        )

        #expect(entity1 != entity2)
    }

    @Test("two entities with same id but different amount are not equal")
    func equatableSameIdDifferentAmount() {
        let id = UUID()
        let entity1 = OrgCostBucketEntity(
            id: id,
            startTime: startTime,
            endTime: endTime,
            amountCents: 100
        )
        let entity2 = OrgCostBucketEntity(
            id: id,
            startTime: startTime,
            endTime: endTime,
            amountCents: 999
        )

        #expect(entity1 != entity2)
    }
}
