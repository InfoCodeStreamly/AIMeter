import Testing
@testable import AIMeterPresentation
import Foundation

/// Tests for UIConstants to verify all values are reasonable
@Suite("UIConstants Tests")
struct UIConstantsTests {

    // MARK: - MenuBar Constants

    @Test("MenuBar width is positive and reasonable")
    func menuBarWidthIsPositiveAndReasonable() {
        // Assert
        #expect(UIConstants.MenuBar.width > 0)
        #expect(UIConstants.MenuBar.width >= 200) // Minimum reasonable width
        #expect(UIConstants.MenuBar.width <= 500) // Maximum reasonable width
        #expect(UIConstants.MenuBar.width == 300)
    }

    @Test("MenuBar minHeight is positive and less than maxHeight")
    func menuBarMinHeightIsPositiveAndLessThanMax() {
        // Assert
        #expect(UIConstants.MenuBar.minHeight > 0)
        #expect(UIConstants.MenuBar.minHeight < UIConstants.MenuBar.maxHeight)
        #expect(UIConstants.MenuBar.minHeight >= 100) // Reasonable minimum
        #expect(UIConstants.MenuBar.minHeight == 200)
    }

    @Test("MenuBar maxHeight is positive and greater than minHeight")
    func menuBarMaxHeightIsPositiveAndGreaterThanMin() {
        // Assert
        #expect(UIConstants.MenuBar.maxHeight > 0)
        #expect(UIConstants.MenuBar.maxHeight > UIConstants.MenuBar.minHeight)
        #expect(UIConstants.MenuBar.maxHeight <= 800) // Reasonable maximum
        #expect(UIConstants.MenuBar.maxHeight == 400)
    }

    @Test("MenuBar height range is reasonable")
    func menuBarHeightRangeIsReasonable() {
        // Assert
        let heightRange = UIConstants.MenuBar.maxHeight - UIConstants.MenuBar.minHeight
        #expect(heightRange > 0)
        #expect(heightRange >= 100) // Reasonable flexibility
    }

    // MARK: - Spacing Constants

    @Test("Spacing xs is positive and smallest")
    func spacingXsIsPositiveAndSmallest() {
        // Assert
        #expect(UIConstants.Spacing.xs > 0)
        #expect(UIConstants.Spacing.xs < UIConstants.Spacing.sm)
        #expect(UIConstants.Spacing.xs == 4)
    }

    @Test("Spacing sm is positive and between xs and md")
    func spacingSmIsPositiveAndBetween() {
        // Assert
        #expect(UIConstants.Spacing.sm > 0)
        #expect(UIConstants.Spacing.sm > UIConstants.Spacing.xs)
        #expect(UIConstants.Spacing.sm < UIConstants.Spacing.md)
        #expect(UIConstants.Spacing.sm == 8)
    }

    @Test("Spacing md is positive and between sm and lg")
    func spacingMdIsPositiveAndBetween() {
        // Assert
        #expect(UIConstants.Spacing.md > 0)
        #expect(UIConstants.Spacing.md > UIConstants.Spacing.sm)
        #expect(UIConstants.Spacing.md < UIConstants.Spacing.lg)
        #expect(UIConstants.Spacing.md == 12)
    }

    @Test("Spacing lg is positive and between md and xl")
    func spacingLgIsPositiveAndBetween() {
        // Assert
        #expect(UIConstants.Spacing.lg > 0)
        #expect(UIConstants.Spacing.lg > UIConstants.Spacing.md)
        #expect(UIConstants.Spacing.lg < UIConstants.Spacing.xl)
        #expect(UIConstants.Spacing.lg == 16)
    }

    @Test("Spacing xl is positive and largest")
    func spacingXlIsPositiveAndLargest() {
        // Assert
        #expect(UIConstants.Spacing.xl > 0)
        #expect(UIConstants.Spacing.xl > UIConstants.Spacing.lg)
        #expect(UIConstants.Spacing.xl == 20)
    }

    @Test("Spacing values form ascending sequence")
    func spacingValuesFormAscendingSequence() {
        // Assert
        #expect(UIConstants.Spacing.xs < UIConstants.Spacing.sm)
        #expect(UIConstants.Spacing.sm < UIConstants.Spacing.md)
        #expect(UIConstants.Spacing.md < UIConstants.Spacing.lg)
        #expect(UIConstants.Spacing.lg < UIConstants.Spacing.xl)
    }

    @Test("Spacing values are multiples of 4")
    func spacingValuesAreMultiplesOf4() {
        // Assert - following 8pt grid system
        #expect(UIConstants.Spacing.xs.truncatingRemainder(dividingBy: 4) == 0)
        #expect(UIConstants.Spacing.sm.truncatingRemainder(dividingBy: 4) == 0)
        #expect(UIConstants.Spacing.md.truncatingRemainder(dividingBy: 4) == 0)
        #expect(UIConstants.Spacing.lg.truncatingRemainder(dividingBy: 4) == 0)
        #expect(UIConstants.Spacing.xl.truncatingRemainder(dividingBy: 4) == 0)
    }

    // MARK: - CornerRadius Constants

    @Test("CornerRadius small is positive and smallest")
    func cornerRadiusSmallIsPositiveAndSmallest() {
        // Assert
        #expect(UIConstants.CornerRadius.small > 0)
        #expect(UIConstants.CornerRadius.small < UIConstants.CornerRadius.medium)
        #expect(UIConstants.CornerRadius.small == 6)
    }

    @Test("CornerRadius medium is positive and between small and large")
    func cornerRadiusMediumIsPositiveAndBetween() {
        // Assert
        #expect(UIConstants.CornerRadius.medium > 0)
        #expect(UIConstants.CornerRadius.medium > UIConstants.CornerRadius.small)
        #expect(UIConstants.CornerRadius.medium < UIConstants.CornerRadius.large)
        #expect(UIConstants.CornerRadius.medium == 10)
    }

    @Test("CornerRadius large is positive and largest")
    func cornerRadiusLargeIsPositiveAndLargest() {
        // Assert
        #expect(UIConstants.CornerRadius.large > 0)
        #expect(UIConstants.CornerRadius.large > UIConstants.CornerRadius.medium)
        #expect(UIConstants.CornerRadius.large == 14)
    }

    @Test("CornerRadius values form ascending sequence")
    func cornerRadiusValuesFormAscendingSequence() {
        // Assert
        #expect(UIConstants.CornerRadius.small < UIConstants.CornerRadius.medium)
        #expect(UIConstants.CornerRadius.medium < UIConstants.CornerRadius.large)
    }

    @Test("CornerRadius values are reasonable for UI")
    func cornerRadiusValuesAreReasonableForUI() {
        // Assert
        #expect(UIConstants.CornerRadius.small >= 4)
        #expect(UIConstants.CornerRadius.small <= 10)
        #expect(UIConstants.CornerRadius.medium >= 8)
        #expect(UIConstants.CornerRadius.medium <= 15)
        #expect(UIConstants.CornerRadius.large >= 10)
        #expect(UIConstants.CornerRadius.large <= 20)
    }

    // MARK: - Animation Constants

    @Test("Animation fast is positive and fastest")
    func animationFastIsPositiveAndFastest() {
        // Assert
        #expect(UIConstants.Animation.fast > 0)
        #expect(UIConstants.Animation.fast < UIConstants.Animation.normal)
        #expect(UIConstants.Animation.fast == 0.2)
    }

    @Test("Animation normal is positive and between fast and slow")
    func animationNormalIsPositiveAndBetween() {
        // Assert
        #expect(UIConstants.Animation.normal > 0)
        #expect(UIConstants.Animation.normal > UIConstants.Animation.fast)
        #expect(UIConstants.Animation.normal < UIConstants.Animation.slow)
        #expect(UIConstants.Animation.normal == 0.3)
    }

    @Test("Animation slow is positive and slowest")
    func animationSlowIsPositiveAndSlowest() {
        // Assert
        #expect(UIConstants.Animation.slow > 0)
        #expect(UIConstants.Animation.slow > UIConstants.Animation.normal)
        #expect(UIConstants.Animation.slow == 0.5)
    }

    @Test("Animation durations form ascending sequence")
    func animationDurationsFormAscendingSequence() {
        // Assert
        #expect(UIConstants.Animation.fast < UIConstants.Animation.normal)
        #expect(UIConstants.Animation.normal < UIConstants.Animation.slow)
    }

    @Test("Animation durations are reasonable for UI")
    func animationDurationsAreReasonableForUI() {
        // Assert - animations should feel responsive
        #expect(UIConstants.Animation.fast >= 0.1)
        #expect(UIConstants.Animation.fast <= 0.3)
        #expect(UIConstants.Animation.normal >= 0.2)
        #expect(UIConstants.Animation.normal <= 0.5)
        #expect(UIConstants.Animation.slow >= 0.3)
        #expect(UIConstants.Animation.slow <= 1.0)
    }

    // MARK: - ProgressCircle Constants (Legacy)

    @Test("ProgressCircle primarySize is positive and larger than secondary")
    func progressCirclePrimarySizeIsPositiveAndLarger() {
        // Assert
        #expect(UIConstants.ProgressCircle.primarySize > 0)
        #expect(UIConstants.ProgressCircle.primarySize > UIConstants.ProgressCircle.secondarySize)
        #expect(UIConstants.ProgressCircle.primarySize == 48)
    }

    @Test("ProgressCircle secondarySize is positive")
    func progressCircleSecondarySizeIsPositive() {
        // Assert
        #expect(UIConstants.ProgressCircle.secondarySize > 0)
        #expect(UIConstants.ProgressCircle.secondarySize == 36)
    }

    @Test("ProgressCircle primaryLineWidth is positive and larger than secondary")
    func progressCirclePrimaryLineWidthIsPositiveAndLarger() {
        // Assert
        #expect(UIConstants.ProgressCircle.primaryLineWidth > 0)
        #expect(UIConstants.ProgressCircle.primaryLineWidth > UIConstants.ProgressCircle.secondaryLineWidth)
        #expect(UIConstants.ProgressCircle.primaryLineWidth == 6)
    }

    @Test("ProgressCircle secondaryLineWidth is positive")
    func progressCircleSecondaryLineWidthIsPositive() {
        // Assert
        #expect(UIConstants.ProgressCircle.secondaryLineWidth > 0)
        #expect(UIConstants.ProgressCircle.secondaryLineWidth == 4)
    }

    @Test("ProgressCircle line widths are reasonable for sizes")
    func progressCircleLineWidthsAreReasonableForSizes() {
        // Assert - line width should be proportional to circle size
        let primaryRatio = UIConstants.ProgressCircle.primaryLineWidth / UIConstants.ProgressCircle.primarySize
        let secondaryRatio = UIConstants.ProgressCircle.secondaryLineWidth / UIConstants.ProgressCircle.secondarySize

        #expect(primaryRatio >= 0.08) // At least 8% of size
        #expect(primaryRatio <= 0.2)   // At most 20% of size
        #expect(secondaryRatio >= 0.08)
        #expect(secondaryRatio <= 0.2)
    }

    // MARK: - ProgressBar Constants

    @Test("ProgressBar height is positive and reasonable")
    func progressBarHeightIsPositiveAndReasonable() {
        // Assert
        #expect(UIConstants.ProgressBar.height > 0)
        #expect(UIConstants.ProgressBar.height >= 4)
        #expect(UIConstants.ProgressBar.height <= 16)
        #expect(UIConstants.ProgressBar.height == 8)
    }

    @Test("ProgressBar cornerRadius is positive and less than height")
    func progressBarCornerRadiusIsPositiveAndLessThanHeight() {
        // Assert
        #expect(UIConstants.ProgressBar.cornerRadius > 0)
        #expect(UIConstants.ProgressBar.cornerRadius <= UIConstants.ProgressBar.height)
        #expect(UIConstants.ProgressBar.cornerRadius == 4)
    }

    @Test("ProgressBar cornerRadius is half of height for rounded appearance")
    func progressBarCornerRadiusIsHalfOfHeight() {
        // Assert - typical design pattern for progress bars
        #expect(UIConstants.ProgressBar.cornerRadius == UIConstants.ProgressBar.height / 2)
    }

    // MARK: - Thresholds Constants

    @Test("Thresholds safe is positive and less than moderate")
    func thresholdsSafeIsPositiveAndLessThanModerate() {
        // Assert
        #expect(UIConstants.Thresholds.safe > 0)
        #expect(UIConstants.Thresholds.safe < UIConstants.Thresholds.moderate)
        #expect(UIConstants.Thresholds.safe == 50)
    }

    @Test("Thresholds moderate is positive and less than 100")
    func thresholdsModerateIsPositiveAndLessThan100() {
        // Assert
        #expect(UIConstants.Thresholds.moderate > 0)
        #expect(UIConstants.Thresholds.moderate < 100)
        #expect(UIConstants.Thresholds.moderate == 80)
    }

    @Test("Thresholds form valid percentage ranges")
    func thresholdsFormValidPercentageRanges() {
        // Assert - thresholds should divide 0-100 into reasonable ranges
        #expect(UIConstants.Thresholds.safe >= 30) // Safe range should be significant
        #expect(UIConstants.Thresholds.safe <= 70)
        #expect(UIConstants.Thresholds.moderate >= 70) // Moderate should start after safe
        #expect(UIConstants.Thresholds.moderate <= 90)

        // Critical range (above moderate) should exist
        let criticalRange = 100 - UIConstants.Thresholds.moderate
        #expect(criticalRange >= 10) // At least 10% for critical
    }

    @Test("Thresholds align with domain model")
    func thresholdsAlignWithDomainModel() {
        // Assert - these match the Percentage.toStatus() logic
        #expect(UIConstants.Thresholds.safe == 50)  // Safe: 0-49%
        #expect(UIConstants.Thresholds.moderate == 80) // Moderate: 50-79%, Critical: 80-100%
    }

    // MARK: - Settings Window Constants

    @Test("Settings windowWidth is positive and reasonable")
    func settingsWindowWidthIsPositiveAndReasonable() {
        // Assert
        #expect(UIConstants.Settings.windowWidth > 0)
        #expect(UIConstants.Settings.windowWidth >= 400)
        #expect(UIConstants.Settings.windowWidth <= 600)
        #expect(UIConstants.Settings.windowWidth == 450)
    }

    @Test("Settings windowHeight is positive and reasonable")
    func settingsWindowHeightIsPositiveAndReasonable() {
        // Assert
        #expect(UIConstants.Settings.windowHeight > 0)
        #expect(UIConstants.Settings.windowHeight >= 400)
        #expect(UIConstants.Settings.windowHeight <= 700)
        #expect(UIConstants.Settings.windowHeight == 520)
    }

    @Test("Settings window has reasonable aspect ratio")
    func settingsWindowHasReasonableAspectRatio() {
        // Assert
        let aspectRatio = UIConstants.Settings.windowWidth / UIConstants.Settings.windowHeight
        #expect(aspectRatio >= 0.6) // Not too tall
        #expect(aspectRatio <= 1.2)  // Not too wide
    }

    // MARK: - SettingsCard Constants

    @Test("SettingsCard padding is positive and reasonable")
    func settingsCardPaddingIsPositiveAndReasonable() {
        // Assert
        #expect(UIConstants.SettingsCard.padding > 0)
        #expect(UIConstants.SettingsCard.padding >= 8)
        #expect(UIConstants.SettingsCard.padding <= 24)
        #expect(UIConstants.SettingsCard.padding == 16)
    }

    @Test("SettingsCard spacing is positive and reasonable")
    func settingsCardSpacingIsPositiveAndReasonable() {
        // Assert
        #expect(UIConstants.SettingsCard.spacing > 0)
        #expect(UIConstants.SettingsCard.spacing >= 8)
        #expect(UIConstants.SettingsCard.spacing <= 24)
        #expect(UIConstants.SettingsCard.spacing == 16)
    }

    @Test("SettingsCard borderWidth is positive and subtle")
    func settingsCardBorderWidthIsPositiveAndSubtle() {
        // Assert
        #expect(UIConstants.SettingsCard.borderWidth > 0)
        #expect(UIConstants.SettingsCard.borderWidth <= 2) // Should be subtle
        #expect(UIConstants.SettingsCard.borderWidth == 0.5)
    }

    @Test("SettingsCard borderOpacity is valid percentage")
    func settingsCardBorderOpacityIsValidPercentage() {
        // Assert
        #expect(UIConstants.SettingsCard.borderOpacity >= 0)
        #expect(UIConstants.SettingsCard.borderOpacity <= 1)
        #expect(UIConstants.SettingsCard.borderOpacity == 0.2)
    }

    @Test("SettingsCard border is subtle for glassmorphism")
    func settingsCardBorderIsSubtleForGlassmorphism() {
        // Assert - border should be very subtle for glassmorphism design
        #expect(UIConstants.SettingsCard.borderOpacity <= 0.3)
        #expect(UIConstants.SettingsCard.borderWidth <= 1.0)
    }

    // MARK: - Cross-Category Consistency

    @Test("all CGFloat values are non-negative")
    func allCGFloatValuesAreNonNegative() {
        // Assert - collect all CGFloat constants
        let values: [CGFloat] = [
            UIConstants.MenuBar.width,
            UIConstants.MenuBar.minHeight,
            UIConstants.MenuBar.maxHeight,
            UIConstants.Spacing.xs,
            UIConstants.Spacing.sm,
            UIConstants.Spacing.md,
            UIConstants.Spacing.lg,
            UIConstants.Spacing.xl,
            UIConstants.CornerRadius.small,
            UIConstants.CornerRadius.medium,
            UIConstants.CornerRadius.large,
            UIConstants.ProgressCircle.primarySize,
            UIConstants.ProgressCircle.secondarySize,
            UIConstants.ProgressCircle.primaryLineWidth,
            UIConstants.ProgressCircle.secondaryLineWidth,
            UIConstants.ProgressBar.height,
            UIConstants.ProgressBar.cornerRadius,
            UIConstants.Settings.windowWidth,
            UIConstants.Settings.windowHeight,
            UIConstants.SettingsCard.padding,
            UIConstants.SettingsCard.spacing,
            UIConstants.SettingsCard.borderWidth
        ]

        for value in values {
            #expect(value >= 0, "All CGFloat values should be non-negative, found: \(value)")
        }
    }

    @Test("all Double values are non-negative")
    func allDoubleValuesAreNonNegative() {
        // Assert - collect all Double constants
        let values: [Double] = [
            UIConstants.Animation.fast,
            UIConstants.Animation.normal,
            UIConstants.Animation.slow,
            UIConstants.Thresholds.safe,
            UIConstants.Thresholds.moderate,
            UIConstants.SettingsCard.borderOpacity
        ]

        for value in values {
            #expect(value >= 0, "All Double values should be non-negative, found: \(value)")
        }
    }
}
