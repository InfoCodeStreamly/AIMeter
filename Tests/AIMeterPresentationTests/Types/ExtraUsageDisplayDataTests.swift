import Testing
@testable import AIMeterPresentation
import AIMeterDomain
import SwiftUI

/// Tests for ExtraUsageDisplayData presentation model
@Suite("ExtraUsageDisplayData Tests")
struct ExtraUsageDisplayDataTests {

    // MARK: - Manual Initialization

    @Test("init creates display data with all properties")
    func initCreatesDisplayDataWithAllProperties() {
        // Arrange & Act
        let displayData = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$12.50",
            monthlyLimit: "$100.00",
            remainingCredits: "$87.50",
            percentage: 12,
            status: .safe
        )

        // Assert
        #expect(displayData.isEnabled == true)
        #expect(displayData.usedCredits == "$12.50")
        #expect(displayData.monthlyLimit == "$100.00")
        #expect(displayData.remainingCredits == "$87.50")
        #expect(displayData.percentage == 12)
        #expect(displayData.status == .safe)
    }

    @Test("init creates disabled display data")
    func initCreatesDisabledDisplayData() {
        // Arrange & Act
        let displayData = ExtraUsageDisplayData(
            isEnabled: false,
            usedCredits: "$0.00",
            monthlyLimit: "$0.00",
            remainingCredits: "$0.00",
            percentage: 0,
            status: .safe
        )

        // Assert
        #expect(displayData.isEnabled == false)
        #expect(displayData.percentage == 0)
    }

    // MARK: - Initialization from Entity

    @Test("init from entity creates safe status display data")
    func initFromEntityCreatesSafeDisplayData() {
        // Arrange
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 25.0,
            utilization: Percentage.clamped(25)
        )

        // Act
        let displayData = ExtraUsageDisplayData(from: entity)

        // Assert
        #expect(displayData.isEnabled == true)
        #expect(displayData.usedCredits == "$25.00")
        #expect(displayData.monthlyLimit == "$100.00")
        #expect(displayData.remainingCredits == "$75.00")
        #expect(displayData.percentage == 25)
        #expect(displayData.status == .safe)
    }

    @Test("init from entity creates moderate status display data")
    func initFromEntityCreatesModerateDisplayData() {
        // Arrange
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 200.0,
            usedCredits: 130.0,
            utilization: Percentage.clamped(65)
        )

        // Act
        let displayData = ExtraUsageDisplayData(from: entity)

        // Assert
        #expect(displayData.percentage == 65)
        #expect(displayData.status == .moderate)
        #expect(displayData.usedCredits == "$130.00")
        #expect(displayData.monthlyLimit == "$200.00")
        #expect(displayData.remainingCredits == "$70.00")
    }

    @Test("init from entity creates critical status display data")
    func initFromEntityCreatesCriticalDisplayData() {
        // Arrange
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 90.0,
            utilization: Percentage.clamped(90)
        )

        // Act
        let displayData = ExtraUsageDisplayData(from: entity)

        // Assert
        #expect(displayData.percentage == 90)
        #expect(displayData.status == .critical)
        #expect(displayData.remainingCredits == "$10.00")
    }

    @Test("init from disabled entity")
    func initFromDisabledEntity() {
        // Arrange
        let entity = ExtraUsageEntity.disabled()

        // Act
        let displayData = ExtraUsageDisplayData(from: entity)

        // Assert
        #expect(displayData.isEnabled == false)
        #expect(displayData.usedCredits == "$0.00")
        #expect(displayData.monthlyLimit == "$0.00")
        #expect(displayData.remainingCredits == "$0.00")
        #expect(displayData.percentage == 0)
    }

    @Test("init from entity formats credits with two decimals")
    func initFromEntityFormatsCreditsWithTwoDecimals() {
        // Arrange
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 150.456,
            usedCredits: 45.678,
            utilization: Percentage.clamped(30)
        )

        // Act
        let displayData = ExtraUsageDisplayData(from: entity)

        // Assert
        #expect(displayData.usedCredits == "$45.68")
        #expect(displayData.monthlyLimit == "$150.46")
        #expect(displayData.remainingCredits == "$104.78")
    }

    // MARK: - Color Property

    @Test("color returns green for safe status")
    func colorReturnsGreenForSafe() {
        // Arrange
        let displayData = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$30.00",
            monthlyLimit: "$100.00",
            remainingCredits: "$70.00",
            percentage: 30,
            status: .safe
        )

        // Act & Assert
        #expect(displayData.color == .green)
    }

    @Test("color returns orange for moderate status")
    func colorReturnsOrangeForModerate() {
        // Arrange
        let displayData = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$60.00",
            monthlyLimit: "$100.00",
            remainingCredits: "$40.00",
            percentage: 60,
            status: .moderate
        )

        // Act & Assert
        #expect(displayData.color == .orange)
    }

    @Test("color returns red for critical status")
    func colorReturnsRedForCritical() {
        // Arrange
        let displayData = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$85.00",
            monthlyLimit: "$100.00",
            remainingCredits: "$15.00",
            percentage: 85,
            status: .critical
        )

        // Act & Assert
        #expect(displayData.color == .red)
    }

    // MARK: - Percentage Text Property

    @Test("percentageText formats correctly")
    func percentageTextFormatsCorrectly() {
        // Arrange
        let displayData = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$42.50",
            monthlyLimit: "$100.00",
            remainingCredits: "$57.50",
            percentage: 42,
            status: .safe
        )

        // Act & Assert
        #expect(displayData.percentageText == "42%")
    }

    @Test("percentageText formats zero")
    func percentageTextFormatsZero() {
        // Arrange
        let displayData = ExtraUsageDisplayData(
            isEnabled: false,
            usedCredits: "$0.00",
            monthlyLimit: "$0.00",
            remainingCredits: "$0.00",
            percentage: 0,
            status: .safe
        )

        // Act & Assert
        #expect(displayData.percentageText == "0%")
    }

    @Test("percentageText formats hundred")
    func percentageTextFormatsHundred() {
        // Arrange
        let displayData = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$100.00",
            monthlyLimit: "$100.00",
            remainingCredits: "$0.00",
            percentage: 100,
            status: .critical
        )

        // Act & Assert
        #expect(displayData.percentageText == "100%")
    }

    // MARK: - Usage Summary Property

    @Test("usageSummary formats correctly")
    func usageSummaryFormatsCorrectly() {
        // Arrange
        let displayData = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$42.50",
            monthlyLimit: "$100.00",
            remainingCredits: "$57.50",
            percentage: 42,
            status: .safe
        )

        // Act & Assert
        #expect(displayData.usageSummary == "$42.50 / $100.00")
    }

    @Test("usageSummary formats zero usage")
    func usageSummaryFormatsZeroUsage() {
        // Arrange
        let displayData = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$0.00",
            monthlyLimit: "$200.00",
            remainingCredits: "$200.00",
            percentage: 0,
            status: .safe
        )

        // Act & Assert
        #expect(displayData.usageSummary == "$0.00 / $200.00")
    }

    @Test("usageSummary formats full usage")
    func usageSummaryFormatsFullUsage() {
        // Arrange
        let displayData = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$150.00",
            monthlyLimit: "$150.00",
            remainingCredits: "$0.00",
            percentage: 100,
            status: .critical
        )

        // Act & Assert
        #expect(displayData.usageSummary == "$150.00 / $150.00")
    }

    // MARK: - Icon Property

    @Test("icon returns checkmark for safe status")
    func iconReturnsCheckmarkForSafe() {
        // Arrange
        let displayData = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$20.00",
            monthlyLimit: "$100.00",
            remainingCredits: "$80.00",
            percentage: 20,
            status: .safe
        )

        // Act & Assert
        #expect(displayData.icon == "checkmark.circle.fill")
    }

    @Test("icon returns exclamation for moderate status")
    func iconReturnsExclamationForModerate() {
        // Arrange
        let displayData = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$70.00",
            monthlyLimit: "$100.00",
            remainingCredits: "$30.00",
            percentage: 70,
            status: .moderate
        )

        // Act & Assert
        #expect(displayData.icon == "exclamationmark.triangle.fill")
    }

    @Test("icon returns xmark for critical status")
    func iconReturnsXmarkForCritical() {
        // Arrange
        let displayData = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$95.00",
            monthlyLimit: "$100.00",
            remainingCredits: "$5.00",
            percentage: 95,
            status: .critical
        )

        // Act & Assert
        #expect(displayData.icon == "xmark.circle.fill")
    }

    // MARK: - Edge Cases

    @Test("handles boundary at 50% for safe to moderate transition")
    func handlesBoundaryAt50Percent() {
        // Arrange
        let safeEntity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 49.0,
            utilization: Percentage.clamped(49)
        )
        let moderateEntity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 50.0,
            utilization: Percentage.clamped(50)
        )

        // Act
        let safeData = ExtraUsageDisplayData(from: safeEntity)
        let moderateData = ExtraUsageDisplayData(from: moderateEntity)

        // Assert
        #expect(safeData.status == .safe)
        #expect(moderateData.status == .moderate)
    }

    @Test("handles boundary at 80% for moderate to critical transition")
    func handlesBoundaryAt80Percent() {
        // Arrange
        let moderateEntity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 79.0,
            utilization: Percentage.clamped(79)
        )
        let criticalEntity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 80.0,
            utilization: Percentage.clamped(80)
        )

        // Act
        let moderateData = ExtraUsageDisplayData(from: moderateEntity)
        let criticalData = ExtraUsageDisplayData(from: criticalEntity)

        // Assert
        #expect(moderateData.status == .moderate)
        #expect(criticalData.status == .critical)
    }

    @Test("handles zero monthly limit")
    func handlesZeroMonthlyLimit() {
        // Arrange
        let entity = ExtraUsageEntity(
            isEnabled: false,
            monthlyLimit: 0.0,
            usedCredits: 0.0,
            utilization: Percentage.zero
        )

        // Act
        let displayData = ExtraUsageDisplayData(from: entity)

        // Assert
        #expect(displayData.monthlyLimit == "$0.00")
        #expect(displayData.usedCredits == "$0.00")
        #expect(displayData.remainingCredits == "$0.00")
        #expect(displayData.usageSummary == "$0.00 / $0.00")
    }

    @Test("handles large credit amounts")
    func handlesLargeCreditAmounts() {
        // Arrange
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 9999.99,
            usedCredits: 5432.10,
            utilization: Percentage.clamped(54)
        )

        // Act
        let displayData = ExtraUsageDisplayData(from: entity)

        // Assert
        #expect(displayData.monthlyLimit == "$9999.99")
        #expect(displayData.usedCredits == "$5432.10")
        #expect(displayData.remainingCredits == "$4567.89")
    }

    @Test("handles very small fractional credits")
    func handlesVerySmallFractionalCredits() {
        // Arrange
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 0.006,
            utilization: Percentage.clamped(0.006)
        )

        // Act
        let displayData = ExtraUsageDisplayData(from: entity)

        // Assert
        #expect(displayData.usedCredits == "$0.01")
        #expect(displayData.remainingCredits == "$99.99")
    }

    // MARK: - Identifiable

    @Test("each instance has unique id")
    func eachInstanceHasUniqueId() {
        // Arrange & Act
        let displayData1 = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$50.00",
            monthlyLimit: "$100.00",
            remainingCredits: "$50.00",
            percentage: 50,
            status: .moderate
        )
        let displayData2 = ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$50.00",
            monthlyLimit: "$100.00",
            remainingCredits: "$50.00",
            percentage: 50,
            status: .moderate
        )

        // Assert
        #expect(displayData1.id != displayData2.id)
    }

    @Test("id is generated for entity initialization")
    func idIsGeneratedForEntityInitialization() {
        // Arrange
        let entity = ExtraUsageEntity(
            isEnabled: true,
            monthlyLimit: 100.0,
            usedCredits: 50.0,
            utilization: Percentage.clamped(50)
        )

        // Act
        let displayData1 = ExtraUsageDisplayData(from: entity)
        let displayData2 = ExtraUsageDisplayData(from: entity)

        // Assert
        #expect(displayData1.id != displayData2.id)
    }
}
