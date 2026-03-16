import Foundation
import Testing
@testable import AIMeterDomain

/// Tests for APIKeyRateLimitEntity domain entity, validating usage percent computations.
@Suite("APIKeyRateLimitEntity")
struct APIKeyRateLimitEntityTests {

    // MARK: - Initialization

    @Test("init stores all provided values correctly")
    func initStoresAllValues() {
        // Arrange
        let resetDate = Date().addingTimeInterval(60)

        // Act
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            requestsResetTime: resetDate,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            inputTokensResetTime: resetDate,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000,
            outputTokensResetTime: resetDate
        )

        // Assert
        #expect(entity.requestsLimit == 1000)
        #expect(entity.requestsRemaining == 850)
        #expect(entity.requestsResetTime == resetDate)
        #expect(entity.inputTokensLimit == 450_000)
        #expect(entity.inputTokensRemaining == 425_000)
        #expect(entity.inputTokensResetTime == resetDate)
        #expect(entity.outputTokensLimit == 90_000)
        #expect(entity.outputTokensRemaining == 85_000)
        #expect(entity.outputTokensResetTime == resetDate)
    }

    @Test("init accepts nil reset times")
    func initAcceptsNilResetTimes() {
        // Act
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 500,
            inputTokensLimit: 100_000,
            inputTokensRemaining: 50_000,
            outputTokensLimit: 20_000,
            outputTokensRemaining: 10_000
        )

        // Assert
        #expect(entity.requestsResetTime == nil)
        #expect(entity.inputTokensResetTime == nil)
        #expect(entity.outputTokensResetTime == nil)
    }

    // MARK: - requestsUsagePercent

    @Test("requestsUsagePercent computes 15% when 850 of 1000 remaining")
    func requestsUsagePercentComputes15Percent() {
        // Arrange — 1000 limit, 850 remaining → 150 used → 15%
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act & Assert
        #expect(entity.requestsUsagePercent == 15.0)
    }

    @Test("requestsUsagePercent computes 0% when all remaining")
    func requestsUsagePercentZeroWhenAllRemaining() {
        // Arrange — 100% remaining → 0% used
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 1000,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act & Assert
        #expect(entity.requestsUsagePercent == 0.0)
    }

    @Test("requestsUsagePercent computes 100% when none remaining")
    func requestsUsagePercentHundredWhenNoneRemaining() {
        // Arrange — 0 remaining → 100% used
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 0,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act & Assert
        #expect(entity.requestsUsagePercent == 100.0)
    }

    @Test("requestsUsagePercent returns 0 when limit is 0 to avoid division by zero")
    func requestsUsagePercentZeroWhenLimitIsZero() {
        // Arrange — edge case: 0 limit must not cause division by zero
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 0,
            requestsRemaining: 0,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act & Assert
        #expect(entity.requestsUsagePercent == 0.0)
    }

    // MARK: - inputTokensUsagePercent

    @Test("inputTokensUsagePercent computes approx 5.6% when 425000 of 450000 remaining")
    func inputTokensUsagePercentComputesCorrectly() {
        // Arrange — 450000 limit, 425000 remaining → 25000 used → ~5.56%
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act
        let percent = entity.inputTokensUsagePercent

        // Assert — within 0.01% tolerance
        let expected = 25_000.0 / 450_000.0 * 100.0
        #expect(abs(percent - expected) < 0.01)
    }

    @Test("inputTokensUsagePercent returns 0 when limit is 0")
    func inputTokensUsagePercentZeroWhenLimitIsZero() {
        // Arrange
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 0,
            inputTokensRemaining: 0,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act & Assert
        #expect(entity.inputTokensUsagePercent == 0.0)
    }

    @Test("inputTokensUsagePercent computes 0% when all tokens remaining")
    func inputTokensUsagePercentZeroWhenAllRemaining() {
        // Arrange
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 100_000,
            inputTokensRemaining: 100_000,
            outputTokensLimit: 1,
            outputTokensRemaining: 1
        )

        // Act & Assert
        #expect(entity.inputTokensUsagePercent == 0.0)
    }

    // MARK: - outputTokensUsagePercent

    @Test("outputTokensUsagePercent computes approximately 5.6% when 85000 of 90000 remaining")
    func outputTokensUsagePercentComputesCorrectly() {
        // Arrange — 90000 limit, 85000 remaining → 5000 used → ~5.56%
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000
        )

        // Act
        let percent = entity.outputTokensUsagePercent

        // Assert
        let expected = 5_000.0 / 90_000.0 * 100.0
        #expect(abs(percent - expected) < 0.01)
    }

    @Test("outputTokensUsagePercent returns 0 when limit is 0")
    func outputTokensUsagePercentZeroWhenLimitIsZero() {
        // Arrange
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 0,
            outputTokensRemaining: 0
        )

        // Act & Assert
        #expect(entity.outputTokensUsagePercent == 0.0)
    }

    @Test("outputTokensUsagePercent computes 100% when all tokens consumed")
    func outputTokensUsagePercentHundredWhenAllConsumed() {
        // Arrange
        let entity = APIKeyRateLimitEntity(
            requestsLimit: 1,
            requestsRemaining: 1,
            inputTokensLimit: 1,
            inputTokensRemaining: 1,
            outputTokensLimit: 50_000,
            outputTokensRemaining: 0
        )

        // Act & Assert
        #expect(entity.outputTokensUsagePercent == 100.0)
    }

    // MARK: - Equatable

    @Test("two entities with same values are equal")
    func equatableSameValues() {
        // Arrange
        let date = Date()
        let entity1 = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            requestsResetTime: date,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000
        )
        let entity2 = APIKeyRateLimitEntity(
            requestsLimit: 1000,
            requestsRemaining: 850,
            requestsResetTime: date,
            inputTokensLimit: 450_000,
            inputTokensRemaining: 425_000,
            outputTokensLimit: 90_000,
            outputTokensRemaining: 85_000
        )

        // Assert
        #expect(entity1 == entity2)
    }

    @Test("two entities with different remaining values are not equal")
    func equatableDifferentValues() {
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

        // Assert
        #expect(entity1 != entity2)
    }
}
