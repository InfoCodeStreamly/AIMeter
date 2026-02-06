import Testing
@testable import AIMeterInfrastructure
import AIMeterDomain
import Foundation

@Suite("WidgetData")
struct WidgetDataTests {

    // MARK: - from() Tests

    @Test("from creates WidgetData with valid session and weekly")
    func fromValidSessionAndWeekly() {
        // Arrange
        let sessionResetDate = Date().addingTimeInterval(3600)
        let weeklyResetDate = Date().addingTimeInterval(7 * 24 * 3600)

        let session = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(45),
            resetTime: ResetTime(sessionResetDate)
        )
        let weekly = UsageEntity(
            type: .weekly,
            percentage: Percentage.clamped(65),
            resetTime: ResetTime(weeklyResetDate)
        )

        let usages = [session, weekly]

        // Act
        let widgetData = WidgetData.from(usages: usages)

        // Assert
        #expect(widgetData != nil)
        #expect(widgetData?.sessionPercentage == 45)
        #expect(widgetData?.weeklyPercentage == 65)
        #expect(widgetData?.sessionStatus == "safe")
        #expect(widgetData?.weeklyStatus == "moderate")
        #expect(widgetData?.sessionResetDate != nil)
        #expect(widgetData?.weeklyResetDate != nil)
        #expect(widgetData?.extraUsageEnabled == false)
        #expect(widgetData?.extraUsageSpent == "$0.00")
        #expect(widgetData?.extraUsageLimit == "$0.00")
        #expect(widgetData?.extraUsagePercentage == 0)
    }

    @Test("from returns nil without session")
    func fromWithoutSession() {
        // Arrange
        let weekly = UsageEntity(
            type: .weekly,
            percentage: Percentage.clamped(65),
            resetTime: ResetTime(Date())
        )
        let opus = UsageEntity(
            type: .opus,
            percentage: Percentage.clamped(30),
            resetTime: ResetTime(Date())
        )

        let usages = [weekly, opus]

        // Act
        let widgetData = WidgetData.from(usages: usages)

        // Assert
        #expect(widgetData == nil)
    }

    @Test("from returns nil without weekly")
    func fromWithoutWeekly() {
        // Arrange
        let session = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(45),
            resetTime: ResetTime(Date())
        )
        let sonnet = UsageEntity(
            type: .sonnet,
            percentage: Percentage.clamped(20),
            resetTime: ResetTime(Date())
        )

        let usages = [session, sonnet]

        // Act
        let widgetData = WidgetData.from(usages: usages)

        // Assert
        #expect(widgetData == nil)
    }

    @Test("from with extraUsage maps extra fields correctly")
    func fromWithExtraUsage() {
        // Arrange
        let session = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(30),
            resetTime: ResetTime(Date())
        )
        let weekly = UsageEntity(
            type: .weekly,
            percentage: Percentage.clamped(50),
            resetTime: ResetTime(Date())
        )

        let extraUsage = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 50.0,
            usedCredits: 12.5,
            utilization: Percentage.clamped(25)
        )

        let usages = [session, weekly]

        // Act
        let widgetData = WidgetData.from(usages: usages, extraUsage: extraUsage)

        // Assert
        #expect(widgetData != nil)
        #expect(widgetData?.extraUsageEnabled == true)
        #expect(widgetData?.extraUsageSpent == "$12.50")
        #expect(widgetData?.extraUsageLimit == "$50.00")
        #expect(widgetData?.extraUsagePercentage == 25)
    }

    @Test("from without extraUsage defaults to zero values")
    func fromWithoutExtraUsage() {
        // Arrange
        let session = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(45),
            resetTime: ResetTime(Date())
        )
        let weekly = UsageEntity(
            type: .weekly,
            percentage: Percentage.clamped(65),
            resetTime: ResetTime(Date())
        )

        let usages = [session, weekly]

        // Act
        let widgetData = WidgetData.from(usages: usages, extraUsage: nil)

        // Assert
        #expect(widgetData != nil)
        #expect(widgetData?.extraUsageEnabled == false)
        #expect(widgetData?.extraUsageSpent == "$0.00")
        #expect(widgetData?.extraUsageLimit == "$0.00")
        #expect(widgetData?.extraUsagePercentage == 0)
    }

    @Test("from maps status correctly for critical usage")
    func fromWithCriticalStatus() {
        // Arrange
        let session = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(85),
            resetTime: ResetTime(Date())
        )
        let weekly = UsageEntity(
            type: .weekly,
            percentage: Percentage.clamped(95),
            resetTime: ResetTime(Date())
        )

        let usages = [session, weekly]

        // Act
        let widgetData = WidgetData.from(usages: usages)

        // Assert
        #expect(widgetData != nil)
        #expect(widgetData?.sessionStatus == "critical")
        #expect(widgetData?.weeklyStatus == "critical")
    }

    // MARK: - Codable Tests

    @Test("codable encodes and decodes correctly")
    func codableRoundtrip() throws {
        // Arrange
        let now = Date()
        let widgetData = WidgetData(
            sessionPercentage: 45,
            weeklyPercentage: 65,
            lastUpdated: now,
            sessionStatus: .safe,
            weeklyStatus: .moderate,
            sessionResetDate: now.addingTimeInterval(3600),
            weeklyResetDate: now.addingTimeInterval(7 * 24 * 3600),
            extraUsageEnabled: true,
            extraUsageSpent: "$12.50",
            extraUsageLimit: "$50.00",
            extraUsagePercentage: 25
        )

        // Act
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(widgetData)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WidgetData.self, from: encoded)

        // Assert
        #expect(decoded.sessionPercentage == 45)
        #expect(decoded.weeklyPercentage == 65)
        #expect(decoded.sessionStatus == "safe")
        #expect(decoded.weeklyStatus == "moderate")
        #expect(decoded.extraUsageEnabled == true)
        #expect(decoded.extraUsageSpent == "$12.50")
        #expect(decoded.extraUsageLimit == "$50.00")
        #expect(decoded.extraUsagePercentage == 25)
    }

    @Test("codable roundtrip with nil reset dates")
    func codableWithNilResetDates() throws {
        // Arrange
        let widgetData = WidgetData(
            sessionPercentage: 20,
            weeklyPercentage: 30,
            lastUpdated: Date(),
            sessionStatus: .safe,
            weeklyStatus: .safe,
            sessionResetDate: nil,
            weeklyResetDate: nil
        )

        // Act
        let encoded = try JSONEncoder().encode(widgetData)
        let decoded = try JSONDecoder().decode(WidgetData.self, from: encoded)

        // Assert
        #expect(decoded.sessionResetDate == nil)
        #expect(decoded.weeklyResetDate == nil)
    }

    @Test("codable with boundary percentage values")
    func codableWithBoundaryValues() throws {
        // Arrange
        let widgetData = WidgetData(
            sessionPercentage: 0,
            weeklyPercentage: 100,
            lastUpdated: Date(),
            sessionStatus: .safe,
            weeklyStatus: .critical
        )

        // Act
        let encoded = try JSONEncoder().encode(widgetData)
        let decoded = try JSONDecoder().decode(WidgetData.self, from: encoded)

        // Assert
        #expect(decoded.sessionPercentage == 0)
        #expect(decoded.weeklyPercentage == 100)
        #expect(decoded.sessionStatus == "safe")
        #expect(decoded.weeklyStatus == "critical")
    }
}
