import Testing
import Foundation
@testable import AIMeterPresentation
import AIMeterDomain
import SwiftUI

/// Tests for UsageDisplayData presentation model
@Suite("UsageDisplayData Tests")
struct UsageDisplayDataTests {

    // MARK: - Initialization from Entity

    @Test("init creates display data from safe usage entity")
    func initFromSafeEntity() {
        // Arrange
        let resetDate = Date().addingTimeInterval(3600)
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(45),
            resetTime: ResetTime(resetDate)
        )

        // Act
        let displayData = UsageDisplayData(from: entity)

        // Assert
        #expect(displayData.id == entity.id)
        #expect(displayData.type == .session)
        #expect(displayData.percentage == 45)
        #expect(displayData.resetDate == resetDate)
        #expect(displayData.status == .safe)
    }

    @Test("init creates display data from moderate usage entity")
    func initFromModerateEntity() {
        // Arrange
        let resetDate = Date().addingTimeInterval(7200)
        let entity = UsageEntity(
            type: .weekly,
            percentage: Percentage.clamped(65),
            resetTime: ResetTime(resetDate)
        )

        // Act
        let displayData = UsageDisplayData(from: entity)

        // Assert
        #expect(displayData.type == .weekly)
        #expect(displayData.percentage == 65)
        #expect(displayData.status == .moderate)
    }

    @Test("init creates display data from critical usage entity")
    func initFromCriticalEntity() {
        // Arrange
        let resetDate = Date().addingTimeInterval(3600)
        let entity = UsageEntity(
            type: .opus,
            percentage: Percentage.clamped(85),
            resetTime: ResetTime(resetDate)
        )

        // Act
        let displayData = UsageDisplayData(from: entity)

        // Assert
        #expect(displayData.type == .opus)
        #expect(displayData.percentage == 85)
        #expect(displayData.status == .critical)
    }

    @Test("init converts percentage to integer correctly")
    func initConvertsPercentageToInt() {
        // Arrange - test rounding behavior
        let entity1 = UsageEntity(
            type: .sonnet,
            percentage: Percentage.clamped(75.9),
            resetTime: ResetTime(Date())
        )
        let entity2 = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(75.1),
            resetTime: ResetTime(Date())
        )

        // Act
        let displayData1 = UsageDisplayData(from: entity1)
        let displayData2 = UsageDisplayData(from: entity2)

        // Assert
        #expect(displayData1.percentage == 75)
        #expect(displayData2.percentage == 75)
    }

    // MARK: - Color Property

    @Test("color returns green for safe status")
    func colorReturnsSafeGreen() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(30),
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)

        // Act & Assert
        #expect(displayData.color == .green)
    }

    @Test("color returns orange for moderate status")
    func colorReturnsModerateOrange() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(60),
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)

        // Act & Assert
        #expect(displayData.color == .orange)
    }

    @Test("color returns red for critical status")
    func colorReturnsCriticalRed() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(90),
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)

        // Act & Assert
        #expect(displayData.color == .red)
    }

    // MARK: - Percentage Text Property

    @Test("percentageText formats correctly")
    func percentageTextFormatsCorrectly() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(75),
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)

        // Act & Assert
        #expect(displayData.percentageText == "75%")
    }

    @Test("percentageText formats zero correctly")
    func percentageTextFormatsZero() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.zero,
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)

        // Act & Assert
        #expect(displayData.percentageText == "0%")
    }

    @Test("percentageText formats hundred correctly")
    func percentageTextFormatsHundred() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(100),
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)

        // Act & Assert
        #expect(displayData.percentageText == "100%")
    }

    // MARK: - Icon Property

    @Test("icon returns checkmark for safe status")
    func iconReturnsSafeCheckmark() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(20),
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)

        // Act & Assert
        #expect(displayData.icon == "checkmark.circle.fill")
    }

    @Test("icon returns exclamation for moderate status")
    func iconReturnsModerateExclamation() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(70),
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)

        // Act & Assert
        #expect(displayData.icon == "exclamationmark.triangle.fill")
    }

    @Test("icon returns xmark for critical status")
    func iconReturnsCriticalXmark() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(95),
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)

        // Act & Assert
        #expect(displayData.icon == "xmark.circle.fill")
    }

    // MARK: - Is Critical Property

    @Test("isCritical returns false for safe usage")
    func isCriticalReturnsFalseForSafe() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(40),
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)

        // Act & Assert
        #expect(displayData.isCritical == false)
    }

    @Test("isCritical returns false for moderate usage")
    func isCriticalReturnsFalseForModerate() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(65),
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)

        // Act & Assert
        #expect(displayData.isCritical == false)
    }

    @Test("isCritical returns true for critical usage")
    func isCriticalReturnsTrueForCritical() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(82),
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)

        // Act & Assert
        #expect(displayData.isCritical == true)
    }

    // MARK: - Equatable

    @Test("equatable compares two identical display data instances")
    func equatableComparesIdentical() {
        // Arrange
        let id = UUID()
        let resetDate = Date().addingTimeInterval(3600)
        let entity1 = UsageEntity(
            id: id,
            type: .session,
            percentage: Percentage.clamped(45),
            resetTime: ResetTime(resetDate)
        )
        let entity2 = UsageEntity(
            id: id,
            type: .session,
            percentage: Percentage.clamped(45),
            resetTime: ResetTime(resetDate)
        )

        // Act
        let displayData1 = UsageDisplayData(from: entity1)
        let displayData2 = UsageDisplayData(from: entity2)

        // Assert
        #expect(displayData1 == displayData2)
    }

    @Test("equatable detects different display data instances")
    func equatableDetectsDifference() {
        // Arrange
        let entity1 = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(45),
            resetTime: ResetTime(Date())
        )
        let entity2 = UsageEntity(
            type: .weekly,
            percentage: Percentage.clamped(45),
            resetTime: ResetTime(Date())
        )

        // Act
        let displayData1 = UsageDisplayData(from: entity1)
        let displayData2 = UsageDisplayData(from: entity2)

        // Assert
        #expect(displayData1 != displayData2)
    }

    // MARK: - Edge Cases

    @Test("handles boundary at 50% for safe to moderate transition")
    func handlesBoundaryAt50Percent() {
        // Arrange
        let safeEntity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(49),
            resetTime: ResetTime(Date())
        )
        let moderateEntity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(50),
            resetTime: ResetTime(Date())
        )

        // Act
        let safeData = UsageDisplayData(from: safeEntity)
        let moderateData = UsageDisplayData(from: moderateEntity)

        // Assert
        #expect(safeData.status == .safe)
        #expect(moderateData.status == .moderate)
    }

    @Test("handles boundary at 80% for moderate to critical transition")
    func handlesBoundaryAt80Percent() {
        // Arrange
        let moderateEntity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(79),
            resetTime: ResetTime(Date())
        )
        let criticalEntity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(80),
            resetTime: ResetTime(Date())
        )

        // Act
        let moderateData = UsageDisplayData(from: moderateEntity)
        let criticalData = UsageDisplayData(from: criticalEntity)

        // Assert
        #expect(moderateData.status == .moderate)
        #expect(criticalData.status == .critical)
    }
}

// MARK: - UsageViewState Tests

@Suite("UsageViewState Tests")
struct UsageViewStateTests {

    // MARK: - Loading State

    @Test("loading state returns correct properties")
    func loadingStateReturnsCorrectProperties() {
        // Arrange
        let state = UsageViewState.loading

        // Assert
        #expect(state.isLoading == true)
        #expect(state.data.isEmpty)
        #expect(state.errorMessage == nil)
        #expect(state.hasData == false)
    }

    // MARK: - Loaded State

    @Test("loaded state with data returns correct properties")
    func loadedStateWithDataReturnsCorrectProperties() {
        // Arrange
        let entity = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(45),
            resetTime: ResetTime(Date())
        )
        let displayData = UsageDisplayData(from: entity)
        let state = UsageViewState.loaded([displayData])

        // Assert
        #expect(state.isLoading == false)
        #expect(state.data.count == 1)
        #expect(state.data.first == displayData)
        #expect(state.errorMessage == nil)
        #expect(state.hasData == true)
    }

    @Test("loaded state with empty data returns correct properties")
    func loadedStateWithEmptyDataReturnsCorrectProperties() {
        // Arrange
        let state = UsageViewState.loaded([])

        // Assert
        #expect(state.isLoading == false)
        #expect(state.data.isEmpty)
        #expect(state.errorMessage == nil)
        #expect(state.hasData == false)
    }

    @Test("loaded state with multiple items returns all data")
    func loadedStateWithMultipleItemsReturnsAllData() {
        // Arrange
        let entity1 = UsageEntity(
            type: .session,
            percentage: Percentage.clamped(45),
            resetTime: ResetTime(Date())
        )
        let entity2 = UsageEntity(
            type: .weekly,
            percentage: Percentage.clamped(65),
            resetTime: ResetTime(Date())
        )
        let displayData1 = UsageDisplayData(from: entity1)
        let displayData2 = UsageDisplayData(from: entity2)
        let state = UsageViewState.loaded([displayData1, displayData2])

        // Assert
        #expect(state.data.count == 2)
        #expect(state.hasData == true)
    }

    // MARK: - Error State

    @Test("error state returns correct properties")
    func errorStateReturnsCorrectProperties() {
        // Arrange
        let errorMessage = "Network connection failed"
        let state = UsageViewState.error(errorMessage)

        // Assert
        #expect(state.isLoading == false)
        #expect(state.data.isEmpty)
        #expect(state.errorMessage == errorMessage)
        #expect(state.hasData == false)
    }

    // MARK: - Needs Setup State

    @Test("needsSetup state returns correct properties")
    func needsSetupStateReturnsCorrectProperties() {
        // Arrange
        let state = UsageViewState.needsSetup

        // Assert
        #expect(state.isLoading == false)
        #expect(state.data.isEmpty)
        #expect(state.errorMessage == nil)
        #expect(state.hasData == false)
    }

    // MARK: - Equatable

    @Test("equatable compares loading states correctly")
    func equatableComparesLoadingStates() {
        // Arrange
        let state1 = UsageViewState.loading
        let state2 = UsageViewState.loading

        // Assert
        #expect(state1 == state2)
    }

    @Test("equatable compares loaded states with same data")
    func equatableComparesLoadedStatesWithSameData() {
        // Arrange
        let id = UUID()
        let resetDate = Date()
        let entity1 = UsageEntity(
            id: id,
            type: .session,
            percentage: Percentage.clamped(45),
            resetTime: ResetTime(resetDate)
        )
        let entity2 = UsageEntity(
            id: id,
            type: .session,
            percentage: Percentage.clamped(45),
            resetTime: ResetTime(resetDate)
        )
        let displayData1 = UsageDisplayData(from: entity1)
        let displayData2 = UsageDisplayData(from: entity2)

        let state1 = UsageViewState.loaded([displayData1])
        let state2 = UsageViewState.loaded([displayData2])

        // Assert
        #expect(state1 == state2)
    }

    @Test("equatable compares error states with same message")
    func equatableComparesErrorStatesWithSameMessage() {
        // Arrange
        let state1 = UsageViewState.error("Connection failed")
        let state2 = UsageViewState.error("Connection failed")

        // Assert
        #expect(state1 == state2)
    }

    @Test("equatable detects different error messages")
    func equatableDetectsDifferentErrorMessages() {
        // Arrange
        let state1 = UsageViewState.error("Connection failed")
        let state2 = UsageViewState.error("Timeout")

        // Assert
        #expect(state1 != state2)
    }

    @Test("equatable compares needsSetup states correctly")
    func equatableComparesNeedsSetupStates() {
        // Arrange
        let state1 = UsageViewState.needsSetup
        let state2 = UsageViewState.needsSetup

        // Assert
        #expect(state1 == state2)
    }

    @Test("equatable detects different state types")
    func equatableDetectsDifferentStateTypes() {
        // Arrange
        let state1 = UsageViewState.loading
        let state2 = UsageViewState.needsSetup
        let state3 = UsageViewState.error("Error")
        let state4 = UsageViewState.loaded([])

        // Assert
        #expect(state1 != state2)
        #expect(state1 != state3)
        #expect(state1 != state4)
        #expect(state2 != state3)
        #expect(state2 != state4)
        #expect(state3 != state4)
    }
}
