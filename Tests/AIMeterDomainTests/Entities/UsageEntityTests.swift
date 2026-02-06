import Testing
import Foundation
@testable import AIMeterDomain

@Suite("UsageEntity")
struct UsageEntityTests {

    // MARK: - Initialization Tests

    @Test("initialization with valid values")
    func initialization() throws {
        let percentage = try Percentage.create(75.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let entity = UsageEntity(
            type: .session,
            percentage: percentage,
            resetTime: resetTime
        )

        #expect(entity.type == .session)
        #expect(entity.percentage == percentage)
        #expect(entity.resetTime == resetTime)
    }

    // MARK: - Status Tests

    @Test("status returns safe for low percentage")
    func statusSafe() throws {
        let percentage = try Percentage.create(25.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let entity = UsageEntity(type: .session, percentage: percentage, resetTime: resetTime)

        #expect(entity.status == .safe)
    }

    @Test("status returns moderate for mid percentage")
    func statusModerate() throws {
        let percentage = try Percentage.create(65.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let entity = UsageEntity(type: .session, percentage: percentage, resetTime: resetTime)

        #expect(entity.status == .moderate)
    }

    @Test("status returns critical for high percentage")
    func statusCritical() throws {
        let percentage = try Percentage.create(85.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let entity = UsageEntity(type: .session, percentage: percentage, resetTime: resetTime)

        #expect(entity.status == .critical)
    }

    @Test("status matches percentage toStatus")
    func statusMatchesPercentage() throws {
        let percentage = try Percentage.create(50.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let entity = UsageEntity(type: .session, percentage: percentage, resetTime: resetTime)

        #expect(entity.status == percentage.toStatus())
    }

    // MARK: - isCritical Tests

    @Test("isCritical is true for critical status")
    func isCriticalTrue() throws {
        let percentage = try Percentage.create(90.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let entity = UsageEntity(type: .session, percentage: percentage, resetTime: resetTime)

        #expect(entity.isCritical == true)
    }

    @Test("isCritical is false for safe status")
    func isCriticalFalseSafe() throws {
        let percentage = try Percentage.create(30.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let entity = UsageEntity(type: .session, percentage: percentage, resetTime: resetTime)

        #expect(entity.isCritical == false)
    }

    @Test("isCritical is false for moderate status")
    func isCriticalFalseModerate() throws {
        let percentage = try Percentage.create(65.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let entity = UsageEntity(type: .session, percentage: percentage, resetTime: resetTime)

        #expect(entity.isCritical == false)
    }

    @Test("isCritical at boundary 80%")
    func isCriticalBoundary() throws {
        let percentage = try Percentage.create(80.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let entity = UsageEntity(type: .session, percentage: percentage, resetTime: resetTime)

        #expect(entity.isCritical == true)
    }

    // MARK: - withPercentage Tests

    @Test("withPercentage creates new entity with updated percentage")
    func withPercentageCreatesNew() throws {
        let originalPercentage = try Percentage.create(50.0)
        let newPercentage = try Percentage.create(75.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let original = UsageEntity(type: .session, percentage: originalPercentage, resetTime: resetTime)

        let updated = original.withPercentage(newPercentage)

        #expect(updated.percentage == newPercentage)
        #expect(updated.type == original.type)
        #expect(updated.resetTime == original.resetTime)
        #expect(original.percentage == originalPercentage) // Original unchanged
    }

    @Test("withPercentage preserves type")
    func withPercentagePreservesType() throws {
        let originalPercentage = try Percentage.create(50.0)
        let newPercentage = try Percentage.create(75.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let original = UsageEntity(type: .weekly, percentage: originalPercentage, resetTime: resetTime)

        let updated = original.withPercentage(newPercentage)

        #expect(updated.type == .weekly)
    }

    @Test("withPercentage preserves resetTime")
    func withPercentagePreservesResetTime() throws {
        let originalPercentage = try Percentage.create(50.0)
        let newPercentage = try Percentage.create(75.0)
        let resetTime = ResetTime(Date(timeIntervalSince1970: 1704067200))
        let original = UsageEntity(type: .session, percentage: originalPercentage, resetTime: resetTime)

        let updated = original.withPercentage(newPercentage)

        #expect(updated.resetTime == resetTime)
    }

    // MARK: - Factory Method Tests

    @Test("defaultSession creates session entity")
    func defaultSession() {
        let entity = UsageEntity.defaultSession()

        #expect(entity.type == .session)
        #expect(entity.percentage == Percentage.zero)
        #expect(entity.status == .safe)
    }

    @Test("defaultWeekly creates weekly entity")
    func defaultWeekly() {
        let entity = UsageEntity.defaultWeekly()

        #expect(entity.type == .weekly)
        #expect(entity.percentage == Percentage.zero)
        #expect(entity.status == .safe)
    }

    @Test("allDefaults creates all usage types")
    func allDefaults() {
        let entities = UsageEntity.allDefaults()

        #expect(entities.count == 4)
        #expect(entities.contains { $0.type == .session })
        #expect(entities.contains { $0.type == .weekly })
        #expect(entities.contains { $0.type == .opus })
        #expect(entities.contains { $0.type == .sonnet })
    }

    @Test("allDefaults creates entities with zero percentage")
    func allDefaultsZeroPercentage() {
        let entities = UsageEntity.allDefaults()

        for entity in entities {
            #expect(entity.percentage == Percentage.zero)
        }
    }

    @Test("allDefaults creates entities with future reset times")
    func allDefaultsFutureResetTimes() {
        let entities = UsageEntity.allDefaults()

        for entity in entities {
            #expect(!entity.resetTime.isExpired)
        }
    }

    // MARK: - Identifiable Tests

    @Test("id is unique for different entities")
    func identifiableUnique() throws {
        let percentage = try Percentage.create(50.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let entity1 = UsageEntity(type: .session, percentage: percentage, resetTime: resetTime)
        let entity2 = UsageEntity(type: .weekly, percentage: percentage, resetTime: resetTime)

        #expect(entity1.id != entity2.id)
    }

    @Test("id is a UUID")
    func identifiableHasUUID() throws {
        let percentage = try Percentage.create(50.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let entity = UsageEntity(type: .session, percentage: percentage, resetTime: resetTime)

        // id is a UUID, not derived from type
        #expect(entity.id != UUID())
    }

    // MARK: - Equatable Tests

    @Test("equatable compares all fields")
    func equatable() throws {
        let percentage = try Percentage.create(50.0)
        let resetTime = ResetTime(Date(timeIntervalSince1970: 1704067200))
        let id = UUID()
        let lastUpdated = Date()

        let entity1 = UsageEntity(id: id, type: .session, percentage: percentage, resetTime: resetTime, lastUpdated: lastUpdated)
        let entity2 = UsageEntity(id: id, type: .session, percentage: percentage, resetTime: resetTime, lastUpdated: lastUpdated)
        let entity3 = UsageEntity(id: id, type: .weekly, percentage: percentage, resetTime: resetTime, lastUpdated: lastUpdated)

        #expect(entity1 == entity2)
        #expect(entity1 != entity3)
    }

    @Test("equatable with different percentages")
    func equatableDifferentPercentages() throws {
        let percentage1 = try Percentage.create(50.0)
        let percentage2 = try Percentage.create(75.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let id = UUID()
        let lastUpdated = Date()

        let entity1 = UsageEntity(id: id, type: .session, percentage: percentage1, resetTime: resetTime, lastUpdated: lastUpdated)
        let entity2 = UsageEntity(id: id, type: .session, percentage: percentage2, resetTime: resetTime, lastUpdated: lastUpdated)

        #expect(entity1 != entity2)
    }

    // MARK: - Sendable Conformance

    @Test("sendable conformance compiles")
    func sendableConformance() throws {
        let percentage = try Percentage.create(50.0)
        let resetTime = ResetTime(Date().addingTimeInterval(3600))
        let entity = UsageEntity(type: .session, percentage: percentage, resetTime: resetTime)

        let closure: @Sendable () -> UsageEntity = { entity }
        #expect(closure().type == .session)
    }

    // MARK: - Integration Tests

    @Test("entity reflects status changes across boundaries")
    func statusChangesBoundaries() throws {
        let resetTime = ResetTime(Date().addingTimeInterval(3600))

        let safePercentage = try Percentage.create(49.9)
        let safeEntity = UsageEntity(type: .session, percentage: safePercentage, resetTime: resetTime)
        #expect(safeEntity.status == .safe)
        #expect(safeEntity.isCritical == false)

        let moderatePercentage = try Percentage.create(50.0)
        let moderateEntity = safeEntity.withPercentage(moderatePercentage)
        #expect(moderateEntity.status == .moderate)
        #expect(moderateEntity.isCritical == false)

        let criticalPercentage = try Percentage.create(80.0)
        let criticalEntity = moderateEntity.withPercentage(criticalPercentage)
        #expect(criticalEntity.status == .critical)
        #expect(criticalEntity.isCritical == true)
    }
}
