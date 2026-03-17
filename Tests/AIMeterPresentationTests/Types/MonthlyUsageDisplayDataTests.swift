import Testing
@testable import AIMeterPresentation
@testable import AIMeterDomain
import Foundation

@Suite("MonthlyUsageDisplayData")
struct MonthlyUsageDisplayDataTests {

    private let start = Date(timeIntervalSince1970: 1_740_000_000)
    private let end = Date(timeIntervalSince1970: 1_742_592_000)

    // MARK: - Cost Formatting

    @Test("formats total cost as dollars")
    func formatsTotalCostAsDollars() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCostCents: 31240,
            periodStart: start,
            periodEnd: end
        )
        let display = MonthlyUsageDisplayData(from: entity)
        #expect(display.totalCostFormatted == "$312.40")
    }

    @Test("formats zero cost")
    func formatsZeroCost() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCostCents: 0,
            periodStart: start,
            periodEnd: end
        )
        let display = MonthlyUsageDisplayData(from: entity)
        #expect(display.totalCostFormatted == "$0.00")
    }

    // MARK: - Token Formatting

    @Test("formats tokens in millions")
    func formatsTokensInMillions() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 24_500_000,
            totalOutputTokens: 8_200_000,
            totalCostCents: 0,
            periodStart: start,
            periodEnd: end
        )
        let display = MonthlyUsageDisplayData(from: entity)
        #expect(display.totalInputTokens == "24.5M")
        #expect(display.totalOutputTokens == "8.2M")
    }

    @Test("formats tokens in thousands")
    func formatsTokensInThousands() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 5_000,
            totalOutputTokens: 500,
            totalCostCents: 0,
            periodStart: start,
            periodEnd: end
        )
        let display = MonthlyUsageDisplayData(from: entity)
        #expect(display.totalInputTokens == "5K")
        #expect(display.totalOutputTokens == "500")
    }

    // MARK: - Top Spender

    @Test("shows top spender when multiple keys")
    func showsTopSpenderWhenMultipleKeys() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCostCents: 1000,
            periodStart: start,
            periodEnd: end,
            byApiKey: [
                .init(apiKeyId: "apikey_01abcdef13mgcgAA", inputTokens: 0, outputTokens: 0, estimatedCostCents: 870),
                .init(apiKeyId: "apikey_02xyz", inputTokens: 0, outputTokens: 0, estimatedCostCents: 130)
            ]
        )
        let display = MonthlyUsageDisplayData(from: entity)
        #expect(display.topSpender != nil)
        #expect(display.topSpender!.contains("13mgcgAA"))
        #expect(display.topSpender!.contains("87%"))
    }

    @Test("no top spender with single key")
    func noTopSpenderWithSingleKey() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCostCents: 1000,
            periodStart: start,
            periodEnd: end,
            byApiKey: [
                .init(apiKeyId: "key1", inputTokens: 0, outputTokens: 0, estimatedCostCents: 1000)
            ]
        )
        let display = MonthlyUsageDisplayData(from: entity)
        #expect(display.topSpender == nil)
    }

    @Test("shows api key name when available")
    func showsApiKeyNameWhenAvailable() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCostCents: 1000,
            periodStart: start,
            periodEnd: end,
            byApiKey: [
                .init(apiKeyId: "key1", apiKeyName: "Anton", inputTokens: 0, outputTokens: 0, estimatedCostCents: 800),
                .init(apiKeyId: "key2", inputTokens: 0, outputTokens: 0, estimatedCostCents: 200)
            ]
        )
        let display = MonthlyUsageDisplayData(from: entity)
        #expect(display.topSpender!.contains("Anton"))
    }

    // MARK: - Top Model

    @Test("shows top model with cost")
    func showsTopModelWithCost() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCostCents: 1000,
            periodStart: start,
            periodEnd: end,
            byModel: [
                .init(model: "claude-sonnet-4-6", inputTokens: 0, outputTokens: 0, costCents: 900),
                .init(model: "claude-haiku-4-5", inputTokens: 0, outputTokens: 0, costCents: 100)
            ]
        )
        let display = MonthlyUsageDisplayData(from: entity)
        #expect(display.topModel != nil)
        #expect(display.topModel!.contains("Sonnet"))
        #expect(display.topModel!.contains("90%"))
    }

    // MARK: - Model Display

    @Test("humanReadableModel maps known models")
    func humanReadableModelMapsKnown() {
        #expect(MonthlyUsageDisplayData.humanReadableModel("claude-opus-4-6") == "Opus")
        #expect(MonthlyUsageDisplayData.humanReadableModel("claude-sonnet-4-6") == "Sonnet")
        #expect(MonthlyUsageDisplayData.humanReadableModel("claude-haiku-4-5") == "Haiku")
        #expect(MonthlyUsageDisplayData.humanReadableModel("other") == "Other")
        #expect(MonthlyUsageDisplayData.humanReadableModel("custom-model") == "custom-model")
    }

    // MARK: - Per-Key Display

    @Test("ApiKeyUsageDisplay masks key ID")
    func apiKeyUsageDisplayMasksKeyId() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCostCents: 1000,
            periodStart: start,
            periodEnd: end,
            byApiKey: [
                .init(apiKeyId: "apikey_01abcdef13mgcgAA", inputTokens: 5_000_000, outputTokens: 2_000_000, estimatedCostCents: 1000)
            ]
        )
        let display = MonthlyUsageDisplayData(from: entity)
        #expect(display.byApiKey.count == 1)
        #expect(display.byApiKey[0].displayName == "...13mgcgAA")
        #expect(display.byApiKey[0].costFormatted == "$10.00")
        #expect(display.byApiKey[0].percentage == 100)
        #expect(display.byApiKey[0].tokensFormatted == "7.0M")
    }

    // MARK: - Per-Model Display

    @Test("ModelUsageDisplay calculates percentage")
    func modelUsageDisplayCalculatesPercentage() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCostCents: 1000,
            periodStart: start,
            periodEnd: end,
            byModel: [
                .init(model: "claude-sonnet-4-6", inputTokens: 0, outputTokens: 0, costCents: 750),
                .init(model: "claude-haiku-4-5", inputTokens: 0, outputTokens: 0, costCents: 250)
            ]
        )
        let display = MonthlyUsageDisplayData(from: entity)
        #expect(display.byModel[0].percentage == 75)
        #expect(display.byModel[1].percentage == 25)
    }

    // MARK: - Daily Cost Display

    @Test("DailyCostDisplay formats date and cost")
    func dailyCostDisplayFormatsDateAndCost() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCostCents: 0,
            periodStart: start,
            periodEnd: end,
            dailyCosts: [
                .init(date: start, costCents: 2500)
            ]
        )
        let display = MonthlyUsageDisplayData(from: entity)
        #expect(display.dailyCosts.count == 1)
        #expect(display.dailyCosts[0].costFormatted == "$25.00")
        #expect(display.dailyCosts[0].costCents == 2500)
    }
}
