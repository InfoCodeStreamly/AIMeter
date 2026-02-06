import Testing
@testable import AIMeterInfrastructure
import AIMeterDomain
import AIMeterApplication
import Foundation

@Suite("APIUsageMapper")
struct APIUsageMapperTests {

    // MARK: - toDomain Tests

    @Test("toDomain with all 4 periods creates 4 entities")
    func toDomainWithAllPeriods() {
        // Arrange
        let response = UsageAPIResponse(
            fiveHour: UsagePeriodData(utilization: 45.5, resetsAt: "2026-02-06T15:00:00Z"),
            sevenDay: UsagePeriodData(utilization: 30.0, resetsAt: "2026-02-10T00:00:00Z"),
            sevenDayOpus: UsagePeriodData(utilization: 25.0, resetsAt: "2026-02-10T00:00:00Z"),
            sevenDaySonnet: UsagePeriodData(utilization: 35.0, resetsAt: "2026-02-10T00:00:00Z"),
            sevenDayOauthApps: nil,
            extraUsage: nil
        )

        // Act
        let entities = APIUsageMapper.toDomain(response)

        // Assert
        #expect(entities.count == 4)

        let session = entities.first(where: { $0.type == .session })
        #expect(session != nil)
        #expect(session?.percentage.value == 45.5)

        let weekly = entities.first(where: { $0.type == .weekly })
        #expect(weekly != nil)
        #expect(weekly?.percentage.value == 30.0)

        let opus = entities.first(where: { $0.type == .opus })
        #expect(opus != nil)
        #expect(opus?.percentage.value == 25.0)

        let sonnet = entities.first(where: { $0.type == .sonnet })
        #expect(sonnet != nil)
        #expect(sonnet?.percentage.value == 35.0)
    }

    @Test("toDomain with only fiveHour creates 1 session entity")
    func toDomainWithOnlySession() {
        // Arrange
        let response = UsageAPIResponse(
            fiveHour: UsagePeriodData(utilization: 60.0, resetsAt: "2026-02-06T15:00:00Z"),
            sevenDay: nil,
            sevenDayOpus: nil,
            sevenDaySonnet: nil,
            sevenDayOauthApps: nil,
            extraUsage: nil
        )

        // Act
        let entities = APIUsageMapper.toDomain(response)

        // Assert
        #expect(entities.count == 1)
        #expect(entities[0].type == .session)
        #expect(entities[0].percentage.value == 60.0)
    }

    @Test("toDomain with only sevenDay creates 1 weekly entity")
    func toDomainWithOnlyWeekly() {
        // Arrange
        let response = UsageAPIResponse(
            fiveHour: nil,
            sevenDay: UsagePeriodData(utilization: 40.0, resetsAt: "2026-02-10T00:00:00Z"),
            sevenDayOpus: nil,
            sevenDaySonnet: nil,
            sevenDayOauthApps: nil,
            extraUsage: nil
        )

        // Act
        let entities = APIUsageMapper.toDomain(response)

        // Assert
        #expect(entities.count == 1)
        #expect(entities[0].type == .weekly)
        #expect(entities[0].percentage.value == 40.0)
    }

    @Test("toDomain maps utilization to Percentage correctly")
    func toDomainMapsUtilizationCorrectly() {
        // Arrange
        let response = UsageAPIResponse(
            fiveHour: UsagePeriodData(utilization: 0.0, resetsAt: "2026-02-06T15:00:00Z"),
            sevenDay: UsagePeriodData(utilization: 100.0, resetsAt: "2026-02-10T00:00:00Z"),
            sevenDayOpus: UsagePeriodData(utilization: 49.9, resetsAt: "2026-02-10T00:00:00Z"),
            sevenDaySonnet: UsagePeriodData(utilization: 85.5, resetsAt: "2026-02-10T00:00:00Z"),
            sevenDayOauthApps: nil,
            extraUsage: nil
        )

        // Act
        let entities = APIUsageMapper.toDomain(response)

        // Assert
        #expect(entities.count == 4)

        let session = entities.first(where: { $0.type == .session })
        #expect(session?.percentage.value == 0.0)
        #expect(session?.status == .safe)

        let weekly = entities.first(where: { $0.type == .weekly })
        #expect(weekly?.percentage.value == 100.0)
        #expect(weekly?.status == .critical)

        let opus = entities.first(where: { $0.type == .opus })
        #expect(opus?.percentage.value == 49.9)
        #expect(opus?.status == .safe)

        let sonnet = entities.first(where: { $0.type == .sonnet })
        #expect(sonnet?.percentage.value == 85.5)
        #expect(sonnet?.status == .critical)
    }

    @Test("toDomain with no periods creates empty array")
    func toDomainWithNoPeriods() {
        // Arrange
        let response = UsageAPIResponse(
            fiveHour: nil,
            sevenDay: nil,
            sevenDayOpus: nil,
            sevenDaySonnet: nil,
            sevenDayOauthApps: nil,
            extraUsage: nil
        )

        // Act
        let entities = APIUsageMapper.toDomain(response)

        // Assert
        #expect(entities.isEmpty)
    }

    @Test("toDomain with invalid ISO8601 date skips entity")
    func toDomainWithInvalidDate() {
        // Arrange
        let response = UsageAPIResponse(
            fiveHour: UsagePeriodData(utilization: 45.5, resetsAt: "invalid-date"),
            sevenDay: UsagePeriodData(utilization: 30.0, resetsAt: "2026-02-10T00:00:00Z"),
            sevenDayOpus: nil,
            sevenDaySonnet: nil,
            sevenDayOauthApps: nil,
            extraUsage: nil
        )

        // Act
        let entities = APIUsageMapper.toDomain(response)

        // Assert
        #expect(entities.count == 1)
        #expect(entities[0].type == .weekly)
    }

    @Test("toDomain maps resetTime correctly")
    func toDomainMapsResetTime() {
        // Arrange
        let expectedDate = "2026-02-06T15:30:45Z"
        let response = UsageAPIResponse(
            fiveHour: UsagePeriodData(utilization: 45.5, resetsAt: expectedDate),
            sevenDay: nil,
            sevenDayOpus: nil,
            sevenDaySonnet: nil,
            sevenDayOauthApps: nil,
            extraUsage: nil
        )

        // Act
        let entities = APIUsageMapper.toDomain(response)

        // Assert
        #expect(entities.count == 1)
        #expect(entities[0].resetTime.date > Date())
    }

    // MARK: - toExtraUsageEntity Tests

    @Test("toExtraUsageEntity with valid enabled data")
    func toExtraUsageEntityWithValidData() {
        // Arrange
        let data = ExtraUsageData(
            isEnabled: true,
            monthlyLimit: 50.0,
            usedCredits: 12.5,
            utilization: 25.0
        )

        // Act
        let entity = APIUsageMapper.toExtraUsageEntity(data)

        // Assert
        #expect(entity != nil)
        #expect(entity?.isEnabled == true)
        #expect(entity?.monthlyLimit == 50.0)
        #expect(entity?.usedCredits == 12.5)
        #expect(entity?.utilization.value == 25.0)
    }

    @Test("toExtraUsageEntity with nil data returns nil")
    func toExtraUsageEntityWithNil() {
        // Act
        let entity = APIUsageMapper.toExtraUsageEntity(nil)

        // Assert
        #expect(entity == nil)
    }

    @Test("toExtraUsageEntity with isEnabled false returns nil")
    func toExtraUsageEntityWithDisabled() {
        // Arrange
        let data = ExtraUsageData(
            isEnabled: false,
            monthlyLimit: 50.0,
            usedCredits: 12.5,
            utilization: 25.0
        )

        // Act
        let entity = APIUsageMapper.toExtraUsageEntity(data)

        // Assert
        #expect(entity == nil)
    }

    @Test("toExtraUsageEntity with isEnabled nil returns nil")
    func toExtraUsageEntityWithNilEnabled() {
        // Arrange
        let data = ExtraUsageData(
            isEnabled: nil,
            monthlyLimit: 50.0,
            usedCredits: 12.5,
            utilization: 25.0
        )

        // Act
        let entity = APIUsageMapper.toExtraUsageEntity(data)

        // Assert
        #expect(entity == nil)
    }

    @Test("toExtraUsageEntity with nil values defaults to zero")
    func toExtraUsageEntityWithNilValues() {
        // Arrange
        let data = ExtraUsageData(
            isEnabled: true,
            monthlyLimit: nil,
            usedCredits: nil,
            utilization: nil
        )

        // Act
        let entity = APIUsageMapper.toExtraUsageEntity(data)

        // Assert
        #expect(entity != nil)
        #expect(entity?.monthlyLimit == 0.0)
        #expect(entity?.usedCredits == 0.0)
        #expect(entity?.utilization.value == 0.0)
    }

    @Test("toExtraUsageEntity clamps out of range utilization")
    func toExtraUsageEntityClampsUtilization() {
        // Arrange
        let data = ExtraUsageData(
            isEnabled: true,
            monthlyLimit: 50.0,
            usedCredits: 60.0,
            utilization: 120.0
        )

        // Act
        let entity = APIUsageMapper.toExtraUsageEntity(data)

        // Assert
        #expect(entity != nil)
        #expect(entity?.utilization.value == 100.0)
    }

    @Test("toExtraUsageEntity with zero values")
    func toExtraUsageEntityWithZeroValues() {
        // Arrange
        let data = ExtraUsageData(
            isEnabled: true,
            monthlyLimit: 0.0,
            usedCredits: 0.0,
            utilization: 0.0
        )

        // Act
        let entity = APIUsageMapper.toExtraUsageEntity(data)

        // Assert
        #expect(entity != nil)
        #expect(entity?.monthlyLimit == 0.0)
        #expect(entity?.usedCredits == 0.0)
        #expect(entity?.utilization.value == 0.0)
    }
}
