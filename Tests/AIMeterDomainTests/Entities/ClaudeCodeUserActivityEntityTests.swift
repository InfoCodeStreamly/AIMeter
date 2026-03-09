import Testing
@testable import AIMeterDomain
import Foundation

/// Tests for ClaudeCodeUserActivityEntity domain entity.
@Suite("ClaudeCodeUserActivityEntity")
struct ClaudeCodeUserActivityEntityTests {

    private let sampleDate = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Init Tests

    @Test("init stores all provided values")
    func initStoresAllValues() {
        let id = UUID()
        let models: [ClaudeCodeUserActivityEntity.ModelUsage] = [
            .init(model: "claude-3-opus", inputTokens: 100, outputTokens: 50, estimatedCostCents: 200)
        ]

        let entity = ClaudeCodeUserActivityEntity(
            id: id,
            date: sampleDate,
            email: "user@example.com",
            customerType: "enterprise",
            terminalType: "vscode",
            sessions: 5,
            linesAdded: 200,
            linesRemoved: 50,
            commits: 3,
            pullRequests: 1,
            editAccepted: 45,
            editRejected: 5,
            writeAccepted: 10,
            writeRejected: 2,
            models: models
        )

        #expect(entity.id == id)
        #expect(entity.date == sampleDate)
        #expect(entity.email == "user@example.com")
        #expect(entity.customerType == "enterprise")
        #expect(entity.terminalType == "vscode")
        #expect(entity.sessions == 5)
        #expect(entity.linesAdded == 200)
        #expect(entity.linesRemoved == 50)
        #expect(entity.commits == 3)
        #expect(entity.pullRequests == 1)
        #expect(entity.editAccepted == 45)
        #expect(entity.editRejected == 5)
        #expect(entity.writeAccepted == 10)
        #expect(entity.writeRejected == 2)
        #expect(entity.models.count == 1)
    }

    @Test("init with defaults uses api customerType and empty terminalType")
    func initDefaults() {
        let entity = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0
        )

        #expect(entity.customerType == "api")
        #expect(entity.terminalType == "")
        #expect(entity.commits == 0)
        #expect(entity.pullRequests == 0)
        #expect(entity.editAccepted == 0)
        #expect(entity.editRejected == 0)
        #expect(entity.writeAccepted == 0)
        #expect(entity.writeRejected == 0)
        #expect(entity.models.isEmpty)
    }

    @Test("init generates unique id when not provided")
    func initGeneratesUniqueId() {
        let entity1 = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0
        )
        let entity2 = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0
        )

        #expect(entity1.id != entity2.id)
    }

    // MARK: - acceptanceRate Tests

    @Test("acceptanceRate returns 90 percent for 45 accepted and 5 rejected edits")
    func acceptanceRateWith45AcceptedAnd5Rejected() {
        let entity = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0,
            editAccepted: 45,
            editRejected: 5,
            writeAccepted: 0,
            writeRejected: 0
        )

        #expect(entity.acceptanceRate == 90.0)
    }

    @Test("acceptanceRate includes both edit and write actions in calculation")
    func acceptanceRateIncludesBothEditAndWrite() {
        // editAccepted=45, writeAccepted=0, editRejected=5, writeRejected=0
        // total accepted = 45, total = 50 → 90%
        let entity = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0,
            editAccepted: 45,
            editRejected: 5
        )

        #expect(entity.acceptanceRate == 90.0)
    }

    @Test("acceptanceRate combines edit and write accepted counts in numerator")
    func acceptanceRateCombinesEditAndWrite() {
        // editAccepted=40, writeAccepted=5, editRejected=5, writeRejected=0
        // total accepted = 45, total = 50 → 90%
        let entity = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0,
            editAccepted: 40,
            editRejected: 5,
            writeAccepted: 5,
            writeRejected: 0
        )

        #expect(entity.acceptanceRate == 90.0)
    }

    @Test("acceptanceRate returns 100 percent when all accepted")
    func acceptanceRateReturns100WhenAllAccepted() {
        let entity = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0,
            editAccepted: 10,
            editRejected: 0
        )

        #expect(entity.acceptanceRate == 100.0)
    }

    @Test("acceptanceRate returns 0 percent when all rejected")
    func acceptanceRateReturns0WhenAllRejected() {
        let entity = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0,
            editAccepted: 0,
            editRejected: 10
        )

        #expect(entity.acceptanceRate == 0.0)
    }

    @Test("acceptanceRate returns 0 percent when no actions taken")
    func acceptanceRateReturns0WhenNoActions() {
        let entity = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0
        )

        #expect(entity.acceptanceRate == 0.0)
    }

    @Test("acceptanceRate returns 50 percent for equal accepted and rejected")
    func acceptanceRateReturns50WhenEqual() {
        let entity = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0,
            editAccepted: 5,
            editRejected: 5
        )

        #expect(entity.acceptanceRate == 50.0)
    }

    // MARK: - totalEstimatedCostCents Tests

    @Test("totalEstimatedCostCents returns sum of all model costs")
    func totalEstimatedCostCentsSumsAllModels() {
        let models: [ClaudeCodeUserActivityEntity.ModelUsage] = [
            .init(model: "claude-3-opus", inputTokens: 100, outputTokens: 50, estimatedCostCents: 500),
            .init(model: "claude-3-sonnet", inputTokens: 200, outputTokens: 100, estimatedCostCents: 250)
        ]

        let entity = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0,
            models: models
        )

        #expect(entity.totalEstimatedCostCents == 750)
    }

    @Test("totalEstimatedCostCents returns zero for empty models")
    func totalEstimatedCostCentsReturnsZeroForEmptyModels() {
        let entity = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0,
            models: []
        )

        #expect(entity.totalEstimatedCostCents == 0)
    }

    @Test("totalEstimatedCostCents handles single model")
    func totalEstimatedCostCentsSingleModel() {
        let models: [ClaudeCodeUserActivityEntity.ModelUsage] = [
            .init(model: "claude-3-haiku", inputTokens: 50, outputTokens: 25, estimatedCostCents: 100)
        ]

        let entity = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0,
            models: models
        )

        #expect(entity.totalEstimatedCostCents == 100)
    }

    @Test("totalEstimatedCostCents handles zero cost models")
    func totalEstimatedCostCentsWithZeroCostModels() {
        let models: [ClaudeCodeUserActivityEntity.ModelUsage] = [
            .init(model: "claude-3-haiku", inputTokens: 50, outputTokens: 25, estimatedCostCents: 0),
            .init(model: "claude-3-opus", inputTokens: 100, outputTokens: 50, estimatedCostCents: 0)
        ]

        let entity = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0,
            models: models
        )

        #expect(entity.totalEstimatedCostCents == 0)
    }

    // MARK: - ModelUsage Nested Type Tests

    @Test("ModelUsage stores all provided values")
    func modelUsageStoresAllValues() {
        let modelUsage = ClaudeCodeUserActivityEntity.ModelUsage(
            model: "claude-3-opus",
            inputTokens: 1000,
            outputTokens: 500,
            estimatedCostCents: 2000
        )

        #expect(modelUsage.model == "claude-3-opus")
        #expect(modelUsage.inputTokens == 1000)
        #expect(modelUsage.outputTokens == 500)
        #expect(modelUsage.estimatedCostCents == 2000)
    }

    @Test("ModelUsage equality works correctly")
    func modelUsageEquality() {
        let model1 = ClaudeCodeUserActivityEntity.ModelUsage(
            model: "claude-3-opus",
            inputTokens: 100,
            outputTokens: 50,
            estimatedCostCents: 200
        )
        let model2 = ClaudeCodeUserActivityEntity.ModelUsage(
            model: "claude-3-opus",
            inputTokens: 100,
            outputTokens: 50,
            estimatedCostCents: 200
        )

        #expect(model1 == model2)
    }

    // MARK: - Equatable Tests

    @Test("two entities with same id and values are equal")
    func equatableSameValues() {
        let id = UUID()
        let entity1 = ClaudeCodeUserActivityEntity(
            id: id,
            date: sampleDate,
            email: "user@example.com",
            sessions: 5,
            linesAdded: 100,
            linesRemoved: 20
        )
        let entity2 = ClaudeCodeUserActivityEntity(
            id: id,
            date: sampleDate,
            email: "user@example.com",
            sessions: 5,
            linesAdded: 100,
            linesRemoved: 20
        )

        #expect(entity1 == entity2)
    }

    @Test("two entities with different ids are not equal")
    func equatableDifferentIds() {
        let entity1 = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0
        )
        let entity2 = ClaudeCodeUserActivityEntity(
            date: sampleDate,
            email: "user@example.com",
            sessions: 1,
            linesAdded: 0,
            linesRemoved: 0
        )

        #expect(entity1 != entity2)
    }
}
