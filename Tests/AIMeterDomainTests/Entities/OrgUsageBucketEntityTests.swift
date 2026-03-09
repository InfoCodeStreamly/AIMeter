import Testing
@testable import AIMeterDomain
import Foundation

/// Tests for OrgUsageBucketEntity domain entity.
@Suite("OrgUsageBucketEntity")
struct OrgUsageBucketEntityTests {

    private let startTime = Date(timeIntervalSince1970: 1_700_000_000)
    private let endTime   = Date(timeIntervalSince1970: 1_700_003_600)

    // MARK: - Init Tests

    @Test("init stores all provided values")
    func initStoresAllValues() {
        let id = UUID()
        let entity = OrgUsageBucketEntity(
            id: id,
            startTime: startTime,
            endTime: endTime,
            model: "claude-3-opus",
            workspaceId: "ws-abc",
            inputTokens: 1000,
            outputTokens: 500,
            cacheReadTokens: 200,
            cacheCreationTokens: 100
        )

        #expect(entity.id == id)
        #expect(entity.startTime == startTime)
        #expect(entity.endTime == endTime)
        #expect(entity.model == "claude-3-opus")
        #expect(entity.workspaceId == "ws-abc")
        #expect(entity.inputTokens == 1000)
        #expect(entity.outputTokens == 500)
        #expect(entity.cacheReadTokens == 200)
        #expect(entity.cacheCreationTokens == 100)
    }

    @Test("init with defaults uses zero for cache tokens")
    func initDefaultsZeroCacheTokens() {
        let entity = OrgUsageBucketEntity(
            startTime: startTime,
            endTime: endTime,
            inputTokens: 100,
            outputTokens: 50
        )

        #expect(entity.cacheReadTokens == 0)
        #expect(entity.cacheCreationTokens == 0)
    }

    @Test("init with defaults uses nil for model and workspaceId")
    func initDefaultsNilOptionals() {
        let entity = OrgUsageBucketEntity(
            startTime: startTime,
            endTime: endTime,
            inputTokens: 100,
            outputTokens: 50
        )

        #expect(entity.model == nil)
        #expect(entity.workspaceId == nil)
    }

    @Test("init generates unique id when not provided")
    func initGeneratesUniqueId() {
        let entity1 = OrgUsageBucketEntity(
            startTime: startTime,
            endTime: endTime,
            inputTokens: 100,
            outputTokens: 50
        )
        let entity2 = OrgUsageBucketEntity(
            startTime: startTime,
            endTime: endTime,
            inputTokens: 100,
            outputTokens: 50
        )

        #expect(entity1.id != entity2.id)
    }

    // MARK: - totalTokens Tests

    @Test("totalTokens returns sum of input and output tokens")
    func totalTokensReturnsSumOfInputAndOutput() {
        let entity = OrgUsageBucketEntity(
            startTime: startTime,
            endTime: endTime,
            inputTokens: 1000,
            outputTokens: 500
        )

        #expect(entity.totalTokens == 1500)
    }

    @Test("totalTokens returns zero when both tokens are zero")
    func totalTokensReturnsZeroForZeroTokens() {
        let entity = OrgUsageBucketEntity(
            startTime: startTime,
            endTime: endTime,
            inputTokens: 0,
            outputTokens: 0
        )

        #expect(entity.totalTokens == 0)
    }

    @Test("totalTokens returns input only when output is zero")
    func totalTokensInputOnly() {
        let entity = OrgUsageBucketEntity(
            startTime: startTime,
            endTime: endTime,
            inputTokens: 300,
            outputTokens: 0
        )

        #expect(entity.totalTokens == 300)
    }

    @Test("totalTokens handles large token counts")
    func totalTokensLargeCounts() {
        let entity = OrgUsageBucketEntity(
            startTime: startTime,
            endTime: endTime,
            inputTokens: 1_000_000,
            outputTokens: 500_000
        )

        #expect(entity.totalTokens == 1_500_000)
    }

    // MARK: - Equatable Tests

    @Test("two entities with same id are equal")
    func equatableSameId() {
        let id = UUID()
        let entity1 = OrgUsageBucketEntity(
            id: id,
            startTime: startTime,
            endTime: endTime,
            inputTokens: 100,
            outputTokens: 50
        )
        let entity2 = OrgUsageBucketEntity(
            id: id,
            startTime: startTime,
            endTime: endTime,
            inputTokens: 100,
            outputTokens: 50
        )

        #expect(entity1 == entity2)
    }

    @Test("two entities with different ids are not equal")
    func equatableDifferentIds() {
        let entity1 = OrgUsageBucketEntity(
            startTime: startTime,
            endTime: endTime,
            inputTokens: 100,
            outputTokens: 50
        )
        let entity2 = OrgUsageBucketEntity(
            startTime: startTime,
            endTime: endTime,
            inputTokens: 100,
            outputTokens: 50
        )

        #expect(entity1 != entity2)
    }

    @Test("two entities with same id but different tokens are not equal")
    func equatableSameIdDifferentTokens() {
        let id = UUID()
        let entity1 = OrgUsageBucketEntity(
            id: id,
            startTime: startTime,
            endTime: endTime,
            inputTokens: 100,
            outputTokens: 50
        )
        let entity2 = OrgUsageBucketEntity(
            id: id,
            startTime: startTime,
            endTime: endTime,
            inputTokens: 999,
            outputTokens: 50
        )

        #expect(entity1 != entity2)
    }

    // MARK: - Identifiable Tests

    @Test("entity conforms to Identifiable and exposes id")
    func identifiableExposesId() {
        let id = UUID()
        let entity = OrgUsageBucketEntity(
            id: id,
            startTime: startTime,
            endTime: endTime,
            inputTokens: 100,
            outputTokens: 50
        )

        #expect(entity.id == id)
    }
}
