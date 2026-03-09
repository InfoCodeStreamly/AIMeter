import Testing
@testable import AIMeterDomain
import Foundation

/// Tests for OrgUsageSummaryEntity domain entity.
@Suite("OrgUsageSummaryEntity")
struct OrgUsageSummaryEntityTests {

    private let periodStart = Date(timeIntervalSince1970: 1_700_000_000)
    private let periodEnd   = Date(timeIntervalSince1970: 1_700_086_400)

    // MARK: - Init Tests

    @Test("init stores all provided values")
    func initStoresAllValues() {
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            model: "claude-3-opus",
            inputTokens: 1000,
            outputTokens: 500
        )

        let entity = OrgUsageSummaryEntity(
            totalInputTokens: 10000,
            totalOutputTokens: 5000,
            totalCostCents: 2500,
            currency: "USD",
            byModel: [modelTokens],
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        #expect(entity.totalInputTokens == 10000)
        #expect(entity.totalOutputTokens == 5000)
        #expect(entity.totalCostCents == 2500)
        #expect(entity.currency == "USD")
        #expect(entity.byModel.count == 1)
        #expect(entity.periodStart == periodStart)
        #expect(entity.periodEnd == periodEnd)
    }

    @Test("init with default currency uses USD")
    func initDefaultCurrency() {
        let entity = OrgUsageSummaryEntity(
            totalInputTokens: 100,
            totalOutputTokens: 50,
            totalCostCents: 0,
            byModel: [],
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        #expect(entity.currency == "USD")
    }

    @Test("init with empty byModel stores empty array")
    func initEmptyByModel() {
        let entity = OrgUsageSummaryEntity(
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCostCents: 0,
            byModel: [],
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        #expect(entity.byModel.isEmpty)
    }

    @Test("init with multiple models stores all models")
    func initMultipleModels() {
        let models = [
            OrgUsageSummaryEntity.ModelTokens(model: "claude-3-opus", inputTokens: 1000, outputTokens: 500),
            OrgUsageSummaryEntity.ModelTokens(model: "claude-3-sonnet", inputTokens: 2000, outputTokens: 1000),
            OrgUsageSummaryEntity.ModelTokens(model: "claude-3-haiku", inputTokens: 500, outputTokens: 250)
        ]

        let entity = OrgUsageSummaryEntity(
            totalInputTokens: 3500,
            totalOutputTokens: 1750,
            totalCostCents: 1000,
            byModel: models,
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        #expect(entity.byModel.count == 3)
    }

    // MARK: - totalTokens Computed Property Tests

    @Test("totalTokens returns sum of input and output")
    func totalTokensReturnsSumOfInputAndOutput() {
        let entity = OrgUsageSummaryEntity(
            totalInputTokens: 10000,
            totalOutputTokens: 5000,
            totalCostCents: 0,
            byModel: [],
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        #expect(entity.totalTokens == 15000)
    }

    @Test("totalTokens returns zero when both are zero")
    func totalTokensReturnsZeroForZeroTokens() {
        let entity = OrgUsageSummaryEntity(
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCostCents: 0,
            byModel: [],
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        #expect(entity.totalTokens == 0)
    }

    @Test("totalTokens handles large numbers")
    func totalTokensHandlesLargeNumbers() {
        let entity = OrgUsageSummaryEntity(
            totalInputTokens: 1_000_000,
            totalOutputTokens: 500_000,
            totalCostCents: 0,
            byModel: [],
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        #expect(entity.totalTokens == 1_500_000)
    }

    // MARK: - ModelTokens Nested Type Tests

    @Test("ModelTokens stores all provided values")
    func modelTokensStoresAllValues() {
        let id = UUID()
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            id: id,
            model: "claude-3-opus",
            inputTokens: 1000,
            outputTokens: 500,
            costCents: 250
        )

        #expect(modelTokens.id == id)
        #expect(modelTokens.model == "claude-3-opus")
        #expect(modelTokens.inputTokens == 1000)
        #expect(modelTokens.outputTokens == 500)
        #expect(modelTokens.costCents == 250)
    }

    @Test("ModelTokens default costCents is zero")
    func modelTokensDefaultCostCentsZero() {
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            model: "claude-3-haiku",
            inputTokens: 100,
            outputTokens: 50
        )

        #expect(modelTokens.costCents == 0)
    }

    @Test("ModelTokens totalTokens returns sum of input and output")
    func modelTokensTotalTokens() {
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            model: "claude-3-opus",
            inputTokens: 1000,
            outputTokens: 500
        )

        #expect(modelTokens.totalTokens == 1500)
    }

    @Test("ModelTokens generates unique id when not provided")
    func modelTokensGeneratesUniqueId() {
        let tokens1 = OrgUsageSummaryEntity.ModelTokens(model: "opus", inputTokens: 100, outputTokens: 50)
        let tokens2 = OrgUsageSummaryEntity.ModelTokens(model: "opus", inputTokens: 100, outputTokens: 50)

        #expect(tokens1.id != tokens2.id)
    }

    // MARK: - Equatable Tests

    @Test("two entities with same values are equal")
    func equatableSameValues() {
        let models = [
            OrgUsageSummaryEntity.ModelTokens(model: "claude-3-opus", inputTokens: 1000, outputTokens: 500)
        ]

        let entity1 = OrgUsageSummaryEntity(
            totalInputTokens: 1000,
            totalOutputTokens: 500,
            totalCostCents: 250,
            byModel: models,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
        let entity2 = OrgUsageSummaryEntity(
            totalInputTokens: 1000,
            totalOutputTokens: 500,
            totalCostCents: 250,
            byModel: models,
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        #expect(entity1 == entity2)
    }

    @Test("two entities with different token counts are not equal")
    func equatableDifferentTokens() {
        let entity1 = OrgUsageSummaryEntity(
            totalInputTokens: 1000,
            totalOutputTokens: 500,
            totalCostCents: 250,
            byModel: [],
            periodStart: periodStart,
            periodEnd: periodEnd
        )
        let entity2 = OrgUsageSummaryEntity(
            totalInputTokens: 2000,
            totalOutputTokens: 500,
            totalCostCents: 250,
            byModel: [],
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        #expect(entity1 != entity2)
    }

    @Test("two entities with different cost are not equal")
    func equatableDifferentCost() {
        let entity1 = OrgUsageSummaryEntity(
            totalInputTokens: 1000,
            totalOutputTokens: 500,
            totalCostCents: 100,
            byModel: [],
            periodStart: periodStart,
            periodEnd: periodEnd
        )
        let entity2 = OrgUsageSummaryEntity(
            totalInputTokens: 1000,
            totalOutputTokens: 500,
            totalCostCents: 999,
            byModel: [],
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        #expect(entity1 != entity2)
    }

    @Test("two entities with different currency are not equal")
    func equatableDifferentCurrency() {
        let entity1 = OrgUsageSummaryEntity(
            totalInputTokens: 1000,
            totalOutputTokens: 500,
            totalCostCents: 250,
            currency: "USD",
            byModel: [],
            periodStart: periodStart,
            periodEnd: periodEnd
        )
        let entity2 = OrgUsageSummaryEntity(
            totalInputTokens: 1000,
            totalOutputTokens: 500,
            totalCostCents: 250,
            currency: "EUR",
            byModel: [],
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        #expect(entity1 != entity2)
    }
}
