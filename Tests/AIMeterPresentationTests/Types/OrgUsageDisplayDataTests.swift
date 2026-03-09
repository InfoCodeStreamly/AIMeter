import Testing
@testable import AIMeterPresentation
import AIMeterDomain
import Foundation

/// Tests for OrgUsageSummaryDisplayData and OrgModelUsageDisplay — formatting behavior.
@Suite("OrgUsageDisplayData")
struct OrgUsageDisplayDataTests {

    // MARK: - Helpers

    private func makeSummary(
        inputTokens: Int,
        outputTokens: Int,
        costCents: Int,
        models: [OrgUsageSummaryEntity.ModelTokens] = []
    ) -> OrgUsageSummaryEntity {
        OrgUsageSummaryEntity(
            totalInputTokens: inputTokens,
            totalOutputTokens: outputTokens,
            totalCostCents: costCents,
            byModel: models,
            periodStart: Date(),
            periodEnd: Date()
        )
    }

    // MARK: - Token Compact Notation Tests

    @Test("totalInputTokens formats values below 1000 as plain integer")
    func totalInputTokensFormatsSmallNumber() {
        let entity = makeSummary(inputTokens: 500, outputTokens: 0, costCents: 0)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalInputTokens == "500")
    }

    @Test("totalInputTokens formats values from 1000 as K notation")
    func totalInputTokensFormatsThousandAsK() {
        let entity = makeSummary(inputTokens: 1000, outputTokens: 0, costCents: 0)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalInputTokens == "1K")
    }

    @Test("totalInputTokens formats 1500 as 2K")
    func totalInputTokensFormats1500As2K() {
        let entity = makeSummary(inputTokens: 1500, outputTokens: 0, costCents: 0)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalInputTokens == "2K")
    }

    @Test("totalInputTokens formats 10000 as 10K")
    func totalInputTokensFormats10000As10K() {
        let entity = makeSummary(inputTokens: 10000, outputTokens: 0, costCents: 0)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalInputTokens == "10K")
    }

    @Test("totalInputTokens formats values from 1M as M notation")
    func totalInputTokensFormatsMillionAsMNotation() {
        let entity = makeSummary(inputTokens: 1_000_000, outputTokens: 0, costCents: 0)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalInputTokens == "1.0M")
    }

    @Test("totalInputTokens formats 1500000 as 1.5M")
    func totalInputTokensFormats1500000As1_5M() {
        let entity = makeSummary(inputTokens: 1_500_000, outputTokens: 0, costCents: 0)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalInputTokens == "1.5M")
    }

    @Test("totalOutputTokens uses same K/M formatting")
    func totalOutputTokensUsesKMFormatting() {
        let entity = makeSummary(inputTokens: 0, outputTokens: 5000, costCents: 0)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalOutputTokens == "5K")
    }

    @Test("totalInputTokens formats zero as plain 0")
    func totalInputTokensFormatsZeroAsPlain() {
        let entity = makeSummary(inputTokens: 0, outputTokens: 0, costCents: 0)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalInputTokens == "0")
    }

    // MARK: - Cost Formatting Tests

    @Test("totalCostFormatted formats 0 cents as dollar zero")
    func totalCostFormattedZeroCents() {
        let entity = makeSummary(inputTokens: 0, outputTokens: 0, costCents: 0)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalCostFormatted == "$0.00")
    }

    @Test("totalCostFormatted formats 100 cents as 1 dollar")
    func totalCostFormattedOneDollar() {
        let entity = makeSummary(inputTokens: 0, outputTokens: 0, costCents: 100)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalCostFormatted == "$1.00")
    }

    @Test("totalCostFormatted formats 1250 cents as 12.50 dollars")
    func totalCostFormattedTwelveAndHalf() {
        let entity = makeSummary(inputTokens: 0, outputTokens: 0, costCents: 1250)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalCostFormatted == "$12.50")
    }

    @Test("totalCostFormatted formats 50 cents as 0.50 dollars")
    func totalCostFormattedFiftyCents() {
        let entity = makeSummary(inputTokens: 0, outputTokens: 0, costCents: 50)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalCostFormatted == "$0.50")
    }

    @Test("totalCostFormatted always shows two decimal places")
    func totalCostFormattedAlwaysTwoDecimalPlaces() {
        let entity = makeSummary(inputTokens: 0, outputTokens: 0, costCents: 500)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.totalCostFormatted == "$5.00")
    }

    // MARK: - Period Label Tests

    @Test("periodLabel is Today")
    func periodLabelIsToday() {
        let entity = makeSummary(inputTokens: 0, outputTokens: 0, costCents: 0)
        let display = OrgUsageSummaryDisplayData(from: entity)
        #expect(display.periodLabel == "Today")
    }

    // MARK: - byModel Mapping Tests

    @Test("byModel maps all model tokens from entity")
    func byModelMapsAllModelTokens() {
        let models = [
            OrgUsageSummaryEntity.ModelTokens(model: "claude-3-opus", inputTokens: 1000, outputTokens: 500),
            OrgUsageSummaryEntity.ModelTokens(model: "claude-3-sonnet", inputTokens: 2000, outputTokens: 1000)
        ]
        let entity = makeSummary(inputTokens: 3000, outputTokens: 1500, costCents: 0, models: models)
        let display = OrgUsageSummaryDisplayData(from: entity)

        #expect(display.byModel.count == 2)
    }

    @Test("byModel is empty when entity has no models")
    func byModelIsEmptyWhenNoModels() {
        let entity = makeSummary(inputTokens: 0, outputTokens: 0, costCents: 0, models: [])
        let display = OrgUsageSummaryDisplayData(from: entity)

        #expect(display.byModel.isEmpty)
    }

    // MARK: - OrgModelUsageDisplay Tests

    @Test("displayName returns Opus for model containing opus")
    func displayNameReturnsOpus() {
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            model: "claude-3-opus-20240229",
            inputTokens: 100,
            outputTokens: 50
        )
        let display = OrgModelUsageDisplay(from: modelTokens)
        #expect(display.displayName == "Opus")
    }

    @Test("displayName returns Sonnet for model containing sonnet")
    func displayNameReturnsSonnet() {
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            model: "claude-3-sonnet-20240229",
            inputTokens: 100,
            outputTokens: 50
        )
        let display = OrgModelUsageDisplay(from: modelTokens)
        #expect(display.displayName == "Sonnet")
    }

    @Test("displayName returns Haiku for model containing haiku")
    func displayNameReturnsHaiku() {
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            model: "claude-3-haiku-20240307",
            inputTokens: 100,
            outputTokens: 50
        )
        let display = OrgModelUsageDisplay(from: modelTokens)
        #expect(display.displayName == "Haiku")
    }

    @Test("displayName returns raw model name for unknown model")
    func displayNameReturnsRawModelForUnknown() {
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            model: "claude-unknown-model",
            inputTokens: 100,
            outputTokens: 50
        )
        let display = OrgModelUsageDisplay(from: modelTokens)
        #expect(display.displayName == "claude-unknown-model")
    }

    @Test("inputTokens formatted with K notation for model")
    func modelInputTokensFormattedAsK() {
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            model: "claude-3-opus",
            inputTokens: 50_000,
            outputTokens: 0
        )
        let display = OrgModelUsageDisplay(from: modelTokens)
        #expect(display.inputTokens == "50K")
    }

    @Test("outputTokens formatted with M notation for model")
    func modelOutputTokensFormattedAsM() {
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            model: "claude-3-sonnet",
            inputTokens: 0,
            outputTokens: 2_000_000
        )
        let display = OrgModelUsageDisplay(from: modelTokens)
        #expect(display.outputTokens == "2.0M")
    }

    @Test("costFormatted shows dollar amount when costCents is positive")
    func modelCostFormattedShowsDollarAmount() {
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            model: "claude-3-opus",
            inputTokens: 0,
            outputTokens: 0,
            costCents: 500
        )
        let display = OrgModelUsageDisplay(from: modelTokens)
        #expect(display.costFormatted == "$5.00")
    }

    @Test("costFormatted returns empty string when costCents is zero")
    func modelCostFormattedReturnsEmptyWhenZero() {
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            model: "claude-3-haiku",
            inputTokens: 100,
            outputTokens: 50,
            costCents: 0
        )
        let display = OrgModelUsageDisplay(from: modelTokens)
        #expect(display.costFormatted == "")
    }

    @Test("id is propagated from entity model tokens")
    func modelDisplayIdPropagatedFromEntity() {
        let id = UUID()
        let modelTokens = OrgUsageSummaryEntity.ModelTokens(
            id: id,
            model: "claude-3-opus",
            inputTokens: 0,
            outputTokens: 0
        )
        let display = OrgModelUsageDisplay(from: modelTokens)
        #expect(display.id == id)
    }

    // MARK: - Equatable Tests

    @Test("two display data instances from same entity are equal")
    func equatableSameEntity() {
        let id = UUID()
        let models = [OrgUsageSummaryEntity.ModelTokens(id: id, model: "opus", inputTokens: 100, outputTokens: 50)]
        let entity = makeSummary(inputTokens: 100, outputTokens: 50, costCents: 100, models: models)
        let display1 = OrgUsageSummaryDisplayData(from: entity)
        let display2 = OrgUsageSummaryDisplayData(from: entity)
        #expect(display1 == display2)
    }

    @Test("two display data instances from different entities are not equal")
    func equatableDifferentEntities() {
        let entity1 = makeSummary(inputTokens: 100, outputTokens: 50, costCents: 100)
        let entity2 = makeSummary(inputTokens: 200, outputTokens: 100, costCents: 200)
        let display1 = OrgUsageSummaryDisplayData(from: entity1)
        let display2 = OrgUsageSummaryDisplayData(from: entity2)
        #expect(display1 != display2)
    }
}
