import Testing
@testable import AIMeterApplication
import AIMeterDomain
import Foundation

/// Tests for UsageMapper following Clean Architecture principles
@Suite
struct UsageMapperTests {

    // MARK: - Success Path Tests

    @Test("toDomain maps all four limits correctly")
    func toDomainMapsAllLimits() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: UsageLimitDTO(
                percentageUsed: 45.5,
                resetAt: "2026-02-06T12:00:00Z"
            ),
            weeklyLimit: UsageLimitDTO(
                percentageUsed: 30.0,
                resetAt: "2026-02-10T00:00:00Z"
            ),
            opusLimit: UsageLimitDTO(
                percentageUsed: 80.0,
                resetAt: "2026-02-06T15:00:00Z"
            ),
            sonnetLimit: UsageLimitDTO(
                percentageUsed: 60.0,
                resetAt: "2026-02-06T18:00:00Z"
            )
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

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
        #expect(opus?.percentage.value == 80.0)

        let sonnet = entities.first(where: { $0.type == .sonnet })
        #expect(sonnet != nil)
        #expect(sonnet?.percentage.value == 60.0)
    }

    @Test("toDomain maps session limit correctly")
    func toDomainMapsSessionLimit() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: UsageLimitDTO(
                percentageUsed: 25.5,
                resetAt: "2026-02-06T12:30:00Z"
            ),
            weeklyLimit: nil,
            opusLimit: nil,
            sonnetLimit: nil
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

        // Assert
        #expect(entities.count == 1)
        #expect(entities[0].type == .session)
        #expect(entities[0].percentage.value == 25.5)
    }

    @Test("toDomain maps weekly limit correctly")
    func toDomainMapsWeeklyLimit() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: nil,
            weeklyLimit: UsageLimitDTO(
                percentageUsed: 15.0,
                resetAt: "2026-02-10T00:00:00Z"
            ),
            opusLimit: nil,
            sonnetLimit: nil
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

        // Assert
        #expect(entities.count == 1)
        #expect(entities[0].type == .weekly)
        #expect(entities[0].percentage.value == 15.0)
    }

    @Test("toDomain clamps percentage above 100")
    func toDomainClampsHighPercentage() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: UsageLimitDTO(
                percentageUsed: 150.0,
                resetAt: "2026-02-06T12:00:00Z"
            ),
            weeklyLimit: nil,
            opusLimit: nil,
            sonnetLimit: nil
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

        // Assert
        #expect(entities.count == 1)
        #expect(entities[0].percentage.value == 100.0)
    }

    @Test("toDomain clamps percentage below 0")
    func toDomainClampsNegativePercentage() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: UsageLimitDTO(
                percentageUsed: -10.0,
                resetAt: "2026-02-06T12:00:00Z"
            ),
            weeklyLimit: nil,
            opusLimit: nil,
            sonnetLimit: nil
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

        // Assert
        #expect(entities.count == 1)
        #expect(entities[0].percentage.value == 0.0)
    }

    @Test("toDomain handles 0 percent correctly")
    func toDomainHandlesZeroPercent() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: UsageLimitDTO(
                percentageUsed: 0.0,
                resetAt: "2026-02-06T12:00:00Z"
            ),
            weeklyLimit: nil,
            opusLimit: nil,
            sonnetLimit: nil
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

        // Assert
        #expect(entities.count == 1)
        #expect(entities[0].percentage.value == 0.0)
    }

    @Test("toDomain handles 100 percent correctly")
    func toDomainHandles100Percent() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: UsageLimitDTO(
                percentageUsed: 100.0,
                resetAt: "2026-02-06T12:00:00Z"
            ),
            weeklyLimit: nil,
            opusLimit: nil,
            sonnetLimit: nil
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

        // Assert
        #expect(entities.count == 1)
        #expect(entities[0].percentage.value == 100.0)
    }

    // MARK: - Nil Handling Tests

    @Test("toDomain skips nil limits")
    func toDomainSkipsNilLimits() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: UsageLimitDTO(
                percentageUsed: 45.0,
                resetAt: "2026-02-06T12:00:00Z"
            ),
            weeklyLimit: nil,
            opusLimit: UsageLimitDTO(
                percentageUsed: 80.0,
                resetAt: "2026-02-06T15:00:00Z"
            ),
            sonnetLimit: nil
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

        // Assert
        #expect(entities.count == 2)
        #expect(entities.contains(where: { $0.type == .session }))
        #expect(entities.contains(where: { $0.type == .opus }))
        #expect(!entities.contains(where: { $0.type == .weekly }))
        #expect(!entities.contains(where: { $0.type == .sonnet }))
    }

    @Test("toDomain returns empty array when all limits nil")
    func toDomainReturnsEmptyWhenAllNil() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: nil,
            weeklyLimit: nil,
            opusLimit: nil,
            sonnetLimit: nil
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

        // Assert
        #expect(entities.isEmpty)
    }

    // MARK: - Invalid resetAt Tests

    @Test("toDomain skips limit with invalid resetAt format")
    func toDomainSkipsInvalidResetAt() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: UsageLimitDTO(
                percentageUsed: 45.0,
                resetAt: "invalid-date"
            ),
            weeklyLimit: UsageLimitDTO(
                percentageUsed: 30.0,
                resetAt: "2026-02-10T00:00:00Z"
            ),
            opusLimit: nil,
            sonnetLimit: nil
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

        // Assert
        // Should skip session (invalid) but include weekly (valid)
        #expect(entities.count == 1)
        #expect(entities[0].type == .weekly)
    }

    @Test("toDomain skips limit with empty resetAt")
    func toDomainSkipsEmptyResetAt() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: UsageLimitDTO(
                percentageUsed: 45.0,
                resetAt: ""
            ),
            weeklyLimit: nil,
            opusLimit: nil,
            sonnetLimit: nil
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

        // Assert
        #expect(entities.isEmpty)
    }

    @Test("toDomain skips all limits with invalid resetAt")
    func toDomainSkipsAllInvalidResetAt() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: UsageLimitDTO(
                percentageUsed: 45.0,
                resetAt: "not-a-date"
            ),
            weeklyLimit: UsageLimitDTO(
                percentageUsed: 30.0,
                resetAt: "also-invalid"
            ),
            opusLimit: UsageLimitDTO(
                percentageUsed: 80.0,
                resetAt: "2026/02/06"
            ),
            sonnetLimit: UsageLimitDTO(
                percentageUsed: 60.0,
                resetAt: "02-06-2026"
            )
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

        // Assert
        #expect(entities.isEmpty)
    }

    // MARK: - Mixed Valid/Invalid Tests

    @Test("toDomain handles mix of valid and invalid limits")
    func toDomainHandlesMixedValidity() throws {
        // Arrange
        let dto = UsageResponseDTO(
            sessionLimit: UsageLimitDTO(
                percentageUsed: 45.0,
                resetAt: "invalid"
            ),
            weeklyLimit: UsageLimitDTO(
                percentageUsed: 30.0,
                resetAt: "2026-02-10T00:00:00Z"
            ),
            opusLimit: nil,
            sonnetLimit: UsageLimitDTO(
                percentageUsed: 60.0,
                resetAt: "2026-02-06T18:00:00Z"
            )
        )

        // Act
        let entities = UsageMapper.toDomain(dto)

        // Assert
        #expect(entities.count == 2)
        #expect(entities.contains(where: { $0.type == .weekly }))
        #expect(entities.contains(where: { $0.type == .sonnet }))
    }

    // MARK: - ISO8601 Format Tests

    @Test("toDomain accepts various valid ISO8601 formats")
    func toDomainAcceptsValidISO8601() throws {
        // Arrange
        let validFormats = [
            "2026-02-06T12:00:00Z",
            "2026-02-06T12:00:00.000Z",
            "2026-02-06T12:00:00+00:00",
            "2026-02-06T12:00:00-05:00"
        ]

        for resetAt in validFormats {
            let dto = UsageResponseDTO(
                sessionLimit: UsageLimitDTO(
                    percentageUsed: 45.0,
                    resetAt: resetAt
                ),
                weeklyLimit: nil,
                opusLimit: nil,
                sonnetLimit: nil
            )

            // Act
            let entities = UsageMapper.toDomain(dto)

            // Assert
            #expect(entities.count == 1, "Failed to parse: \(resetAt)")
        }
    }
}
