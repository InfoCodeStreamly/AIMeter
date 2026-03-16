import Foundation
import Testing
@testable import AIMeterPresentation
import AIMeterDomain

/// Tests for APIKeyRateLimitDisplayData presentation model.
@Suite("APIKeyRateLimitDisplayData")
struct APIKeyRateLimitDisplayDataTests {

    // MARK: - Requests Formatting

    @Test("requestsRemaining formats as remaining-slash-limit")
    func requestsRemainingFormatsWithSlashSeparator() {
        // Arrange — 850 remaining out of 1000
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert — verify the remaining/limit slash pattern using the locale-aware formatter
        let parts = displayData.requestsRemaining.components(separatedBy: "/")
        #expect(parts.count == 2)
        // The numeric values must be present regardless of locale grouping separator
        let remaining = parts[0].replacingOccurrences(of: ",", with: "")
        let limit = parts[1].replacingOccurrences(of: ",", with: "")
        #expect(remaining == "850")
        #expect(limit == "1000")
    }

    @Test("requestsRemaining formats both zero as 0-slash-0")
    func requestsRemainingFormatsZeroValues() {
        // Arrange — edge case: all zeros
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 0,
            requestsRemaining: 0,
            inputTokensLimit: 0,
            inputTokensRemaining: 0,
            outputTokensLimit: 0,
            outputTokensRemaining: 0
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.requestsRemaining == "0/0")
    }

    @Test("requestsRemaining formats large limit with correct numeric values")
    func requestsRemainingFormatsLargeLimitWithCorrectValues() {
        // Arrange — 4500 / 5000
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 5000,
            requestsRemaining: 4500,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert — verify the slash-separated format with locale-independent numeric check
        let parts = displayData.requestsRemaining.components(separatedBy: "/")
        #expect(parts.count == 2)
        let remaining = parts[0].replacingOccurrences(of: ",", with: "")
        let limit = parts[1].replacingOccurrences(of: ",", with: "")
        #expect(remaining == "4500")
        #expect(limit == "5000")
    }

    // MARK: - Input Tokens Formatting

    @Test("inputTokensRemaining formats in K notation when values are in thousands")
    func inputTokensRemainingFormatsInKNotation() {
        // Arrange — 425000 remaining out of 450000
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.inputTokensRemaining == "425K/450K")
    }

    @Test("inputTokensRemaining formats in M notation when values are in millions")
    func inputTokensRemainingFormatsInMNotation() {
        // Arrange — 1.5M remaining out of 2M
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 2_000_000,
            inputTokensRemaining: 1_500_000,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.inputTokensRemaining == "1.5M/2.0M")
    }

    @Test("inputTokensRemaining formats small values without K or M suffix")
    func inputTokensRemainingFormatsSmallValuesWithoutSuffix() {
        // Arrange — values under 1000
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 500,
            inputTokensRemaining: 250,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.inputTokensRemaining == "250/500")
    }

    // MARK: - Output Tokens Formatting

    @Test("outputTokensRemaining formats 85K slash 90K for typical values")
    func outputTokensRemainingFormatsInKNotation() {
        // Arrange — 85000 remaining out of 90000
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.outputTokensRemaining == "85K/90K")
    }

    @Test("outputTokensRemaining formats both zeros as 0-slash-0")
    func outputTokensRemainingFormatsZeroValues() {
        // Arrange
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 0,
            outputTokensRemaining: 0
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.outputTokensRemaining == "0/0")
    }

    // MARK: - Percent Fields

    @Test("requestsPercent is 15 when 850 of 1000 remaining")
    func requestsPercentIs15WhenCorrectValues() {
        // Arrange — 150 used out of 1000 → 15%
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.requestsPercent == 15)
    }

    @Test("inputTokensPercent rounds correctly for 425000 of 450000 remaining")
    func inputTokensPercentRoundsCorrectly() {
        // Arrange — 25000 used out of 450000 → ~5.56% → Int truncates to 5
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert — Int(5.56) = 5
        #expect(displayData.inputTokensPercent == 5)
    }

    @Test("outputTokensPercent rounds correctly for 85000 of 90000 remaining")
    func outputTokensPercentRoundsCorrectly() {
        // Arrange — 5000 used out of 90000 → ~5.56% → Int truncates to 5
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.outputTokensPercent == 5)
    }

    @Test("all percents are 0 when all tokens remaining")
    func allPercentsZeroWhenAllRemaining() {
        // Arrange
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 1000,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 450_000,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 90_000
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.requestsPercent == 0)
        #expect(displayData.inputTokensPercent == 0)
        #expect(displayData.outputTokensPercent == 0)
    }

    @Test("all percents are 100 when all tokens consumed")
    func allPercentsHundredWhenAllConsumed() {
        // Arrange
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 0,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 0,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 0
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.requestsPercent == 100)
        #expect(displayData.inputTokensPercent == 100)
        #expect(displayData.outputTokensPercent == 100)
    }

    @Test("percents are 0 when limits are 0 to avoid division by zero")
    func percentsAreZeroWhenLimitsAreZero() {
        // Arrange — all limits are 0 (edge case)
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 0,
            requestsRemaining: 0,
            inputTokensLimit: 0,
            inputTokensRemaining: 0,
            outputTokensLimit: 0,
            outputTokensRemaining: 0
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.requestsPercent == 0)
        #expect(displayData.inputTokensPercent == 0)
        #expect(displayData.outputTokensPercent == 0)
    }

    // MARK: - Reset Label

    @Test("nextResetLabel shows seconds when reset is less than 60 seconds away")
    func nextResetLabelShowsSecondsWhenLessThan60s() {
        // Arrange — reset in 30 seconds
        let resetDate = Date().addingTimeInterval(30)
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            requestsResetTime: resetDate,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert — label should be "resets in Xs" where X is near 30
        #expect(displayData.nextResetLabel.hasPrefix("resets in "))
        #expect(displayData.nextResetLabel.hasSuffix("s"))
        #expect(!displayData.nextResetLabel.hasSuffix("m"))
    }

    @Test("nextResetLabel shows minutes suffix when reset is 60 or more seconds away")
    func nextResetLabelShowsMinutesSuffixWhenMoreThan60s() {
        // Arrange — reset in 600 seconds (nominally 10 min, but truncation may yield 9m)
        let resetDate = Date().addingTimeInterval(600)
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            requestsResetTime: resetDate,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert — label uses minutes suffix and starts with the expected prefix
        #expect(displayData.nextResetLabel.hasPrefix("resets in "))
        #expect(displayData.nextResetLabel.hasSuffix("m"))
        // Verify the minute value is in expected range (9–10m, accounting for execution time)
        let label = displayData.nextResetLabel
        let minuteStr = label
            .replacingOccurrences(of: "resets in ", with: "")
            .replacingOccurrences(of: "m", with: "")
        let minutes = Int(minuteStr) ?? 0
        #expect(minutes >= 9 && minutes <= 10)
    }

    @Test("nextResetLabel shows resets now when reset time is in the past")
    func nextResetLabelShowsResetsNowWhenInPast() {
        // Arrange — reset time was 10 seconds ago
        let resetDate = Date().addingTimeInterval(-10)
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            requestsResetTime: resetDate,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.nextResetLabel == "resets now")
    }

    @Test("nextResetLabel is empty when no reset times provided")
    func nextResetLabelIsEmptyWhenNoResetTimes() {
        // Arrange — no reset times
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData.nextResetLabel == "")
    }

    @Test("nextResetLabel uses earliest of multiple reset times")
    func nextResetLabelUsesEarliestResetTime() {
        // Arrange — earliest resets in ~300s (nominally 5m), others much later.
        // The earliest must produce a lower minute count than the others.
        let now = Date()
        let earliest = now.addingTimeInterval(300)    // ~5 minutes
        let middle = now.addingTimeInterval(1800)     // 30 minutes
        let latest = now.addingTimeInterval(3600)     // 60 minutes
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            requestsResetTime: middle,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            inputTokensResetTime: earliest,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000,
            outputTokensResetTime: latest
        )

        // Act
        let displayData = APIKeyRateLimitDisplayData(from: entity)

        // Assert — label picks the earliest (5m) not the later ones (30m or 60m)
        let label = displayData.nextResetLabel
        #expect(label.hasPrefix("resets in "))
        #expect(label.hasSuffix("m"))
        let minuteStr = label
            .replacingOccurrences(of: "resets in ", with: "")
            .replacingOccurrences(of: "m", with: "")
        let minutes = Int(minuteStr) ?? 999
        // Must be less than 10 minutes — confirming the earliest date was chosen
        #expect(minutes < 10)
    }

    // MARK: - Equatable

    @Test("two display data instances with same entity are equal")
    func equatableSameEntity() {
        // Arrange
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000
        )

        // Act
        let displayData1 = APIKeyRateLimitDisplayData(from: entity)
        let displayData2 = APIKeyRateLimitDisplayData(from: entity)

        // Assert
        #expect(displayData1 == displayData2)
    }

    @Test("two display data instances with different entities are not equal")
    func equatableDifferentEntities() {
        // Arrange
        let entity1 = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000
        )
        let entity2 = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 500,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 300_000,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 45_000
        )

        // Act
        let displayData1 = APIKeyRateLimitDisplayData(from: entity1)
        let displayData2 = APIKeyRateLimitDisplayData(from: entity2)

        // Assert
        #expect(displayData1 != displayData2)
    }
}
