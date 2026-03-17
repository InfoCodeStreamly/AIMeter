import Testing
@testable import AIMeterDomain
import Foundation

@Suite("MonthlyUsageEntity")
struct MonthlyUsageEntityTests {

    private let start = Date(timeIntervalSince1970: 1_740_000_000)
    private let end = Date(timeIntervalSince1970: 1_742_592_000)

    @Test("totalTokens returns sum of input and output")
    func totalTokensReturnsSum() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 10_000,
            totalOutputTokens: 5_000,
            totalCostCents: 1250,
            periodStart: start,
            periodEnd: end
        )
        #expect(entity.totalTokens == 15_000)
    }

    @Test("default values for empty entity")
    func defaultValues() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 0,
            totalOutputTokens: 0,
            totalCostCents: 0,
            periodStart: start,
            periodEnd: end
        )
        #expect(entity.byApiKey.isEmpty)
        #expect(entity.byModel.isEmpty)
        #expect(entity.dailyCosts.isEmpty)
        #expect(entity.currency == "USD")
    }

    @Test("equatable compares all fields")
    func equatableComparesAllFields() {
        let a = MonthlyUsageEntity(
            totalInputTokens: 100,
            totalOutputTokens: 50,
            totalCostCents: 500,
            periodStart: start,
            periodEnd: end
        )
        let b = MonthlyUsageEntity(
            totalInputTokens: 100,
            totalOutputTokens: 50,
            totalCostCents: 500,
            periodStart: start,
            periodEnd: end
        )
        #expect(a == b)
    }

    // MARK: - ApiKeyUsage

    @Test("ApiKeyUsage totalTokens returns sum")
    func apiKeyUsageTotalTokens() {
        let usage = MonthlyUsageEntity.ApiKeyUsage(
            apiKeyId: "key1",
            inputTokens: 5000,
            outputTokens: 2000,
            estimatedCostCents: 300
        )
        #expect(usage.totalTokens == 7000)
    }

    @Test("ApiKeyUsage with name")
    func apiKeyUsageWithName() {
        let usage = MonthlyUsageEntity.ApiKeyUsage(
            apiKeyId: "key1",
            apiKeyName: "Production Key",
            inputTokens: 1000,
            outputTokens: 500,
            estimatedCostCents: 100
        )
        #expect(usage.apiKeyName == "Production Key")
    }

    // MARK: - ModelUsage

    @Test("ModelUsage totalTokens returns sum")
    func modelUsageTotalTokens() {
        let usage = MonthlyUsageEntity.ModelUsage(
            model: "claude-sonnet-4-6",
            inputTokens: 10_000,
            outputTokens: 3_000,
            costCents: 500
        )
        #expect(usage.totalTokens == 13_000)
    }

    // MARK: - DailyCost

    @Test("DailyCost stores date and cost")
    func dailyCostStoresValues() {
        let date = Date(timeIntervalSince1970: 1_740_000_000)
        let cost = MonthlyUsageEntity.DailyCost(date: date, costCents: 250)
        #expect(cost.costCents == 250)
        #expect(cost.date == date)
    }

    // MARK: - Full Entity

    @Test("entity with all nested data")
    func entityWithAllNestedData() {
        let entity = MonthlyUsageEntity(
            totalInputTokens: 50_000,
            totalOutputTokens: 20_000,
            totalCostCents: 3000,
            currency: "USD",
            periodStart: start,
            periodEnd: end,
            byApiKey: [
                .init(apiKeyId: "key1", inputTokens: 30_000, outputTokens: 12_000, estimatedCostCents: 2000),
                .init(apiKeyId: "key2", inputTokens: 20_000, outputTokens: 8_000, estimatedCostCents: 1000)
            ],
            byModel: [
                .init(model: "sonnet", inputTokens: 40_000, outputTokens: 15_000, costCents: 2500),
                .init(model: "haiku", inputTokens: 10_000, outputTokens: 5_000, costCents: 500)
            ],
            dailyCosts: [
                .init(date: start, costCents: 1500),
                .init(date: end, costCents: 1500)
            ]
        )

        #expect(entity.byApiKey.count == 2)
        #expect(entity.byModel.count == 2)
        #expect(entity.dailyCosts.count == 2)
        #expect(entity.totalTokens == 70_000)
    }
}
