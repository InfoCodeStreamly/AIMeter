import Testing
@testable import AIMeterApplication
import Foundation

/// Tests for Usage DTOs (Codable conformance) following Clean Architecture principles
@Suite
struct UsageDTOTests {

    // MARK: - UsageResponseDTO Tests

    @Test("UsageResponseDTO decodes all four limits")
    func responseDecodesAllLimits() throws {
        // Arrange
        let json = """
        {
            "session_limit": {
                "percentage_used": 45.5,
                "reset_at": "2026-02-06T12:00:00Z"
            },
            "weekly_limit": {
                "percentage_used": 30.0,
                "reset_at": "2026-02-10T00:00:00Z"
            },
            "opus_limit": {
                "percentage_used": 80.0,
                "reset_at": "2026-02-06T15:00:00Z"
            },
            "sonnet_limit": {
                "percentage_used": 60.0,
                "reset_at": "2026-02-06T18:00:00Z"
            }
        }
        """

        // Act
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(UsageResponseDTO.self, from: data)

        // Assert
        #expect(dto.sessionLimit != nil)
        #expect(dto.sessionLimit?.percentageUsed == 45.5)
        #expect(dto.sessionLimit?.resetAt == "2026-02-06T12:00:00Z")

        #expect(dto.weeklyLimit != nil)
        #expect(dto.weeklyLimit?.percentageUsed == 30.0)

        #expect(dto.opusLimit != nil)
        #expect(dto.opusLimit?.percentageUsed == 80.0)

        #expect(dto.sonnetLimit != nil)
        #expect(dto.sonnetLimit?.percentageUsed == 60.0)
    }

    @Test("UsageResponseDTO handles missing limits as nil")
    func responseHandlesMissingLimits() throws {
        // Arrange
        let json = """
        {
            "session_limit": {
                "percentage_used": 45.0,
                "reset_at": "2026-02-06T12:00:00Z"
            }
        }
        """

        // Act
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(UsageResponseDTO.self, from: data)

        // Assert
        #expect(dto.sessionLimit != nil)
        #expect(dto.weeklyLimit == nil)
        #expect(dto.opusLimit == nil)
        #expect(dto.sonnetLimit == nil)
    }

    @Test("UsageResponseDTO decodes empty object with all nils")
    func responseDecodesEmptyObject() throws {
        // Arrange
        let json = "{}"

        // Act
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(UsageResponseDTO.self, from: data)

        // Assert
        #expect(dto.sessionLimit == nil)
        #expect(dto.weeklyLimit == nil)
        #expect(dto.opusLimit == nil)
        #expect(dto.sonnetLimit == nil)
    }

    @Test("UsageResponseDTO handles null values")
    func responseHandlesNullValues() throws {
        // Arrange
        let json = """
        {
            "session_limit": {
                "percentage_used": 45.0,
                "reset_at": "2026-02-06T12:00:00Z"
            },
            "weekly_limit": null,
            "opus_limit": null,
            "sonnet_limit": null
        }
        """

        // Act
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(UsageResponseDTO.self, from: data)

        // Assert
        #expect(dto.sessionLimit != nil)
        #expect(dto.weeklyLimit == nil)
        #expect(dto.opusLimit == nil)
        #expect(dto.sonnetLimit == nil)
    }

    // MARK: - UsageLimitDTO Tests

    @Test("UsageLimitDTO decodes valid JSON")
    func limitDecodesValidJSON() throws {
        // Arrange
        let json = """
        {
            "percentage_used": 75.5,
            "reset_at": "2026-02-06T12:00:00Z"
        }
        """

        // Act
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(UsageLimitDTO.self, from: data)

        // Assert
        #expect(dto.percentageUsed == 75.5)
        #expect(dto.resetAt == "2026-02-06T12:00:00Z")
    }

    @Test("UsageLimitDTO decodes zero percentage")
    func limitDecodesZeroPercentage() throws {
        // Arrange
        let json = """
        {
            "percentage_used": 0.0,
            "reset_at": "2026-02-06T12:00:00Z"
        }
        """

        // Act
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(UsageLimitDTO.self, from: data)

        // Assert
        #expect(dto.percentageUsed == 0.0)
    }

    @Test("UsageLimitDTO decodes 100 percentage")
    func limitDecodes100Percentage() throws {
        // Arrange
        let json = """
        {
            "percentage_used": 100.0,
            "reset_at": "2026-02-06T12:00:00Z"
        }
        """

        // Act
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(UsageLimitDTO.self, from: data)

        // Assert
        #expect(dto.percentageUsed == 100.0)
    }

    @Test("UsageLimitDTO decodes over 100 percentage")
    func limitDecodesOver100Percentage() throws {
        // Arrange
        let json = """
        {
            "percentage_used": 150.0,
            "reset_at": "2026-02-06T12:00:00Z"
        }
        """

        // Act
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(UsageLimitDTO.self, from: data)

        // Assert
        // DTO should decode raw value without clamping
        #expect(dto.percentageUsed == 150.0)
    }

    @Test("UsageLimitDTO decodes negative percentage")
    func limitDecodesNegativePercentage() throws {
        // Arrange
        let json = """
        {
            "percentage_used": -10.0,
            "reset_at": "2026-02-06T12:00:00Z"
        }
        """

        // Act
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(UsageLimitDTO.self, from: data)

        // Assert
        // DTO should decode raw value without validation
        #expect(dto.percentageUsed == -10.0)
    }

    @Test("UsageLimitDTO decodes integer percentage as double")
    func limitDecodesIntegerPercentage() throws {
        // Arrange
        let json = """
        {
            "percentage_used": 45,
            "reset_at": "2026-02-06T12:00:00Z"
        }
        """

        // Act
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(UsageLimitDTO.self, from: data)

        // Assert
        #expect(dto.percentageUsed == 45.0)
    }

    @Test("UsageLimitDTO decodes various resetAt formats")
    func limitDecodesVariousResetAtFormats() throws {
        // Arrange
        let formats = [
            "2026-02-06T12:00:00Z",
            "2026-02-06T12:00:00.000Z",
            "2026-02-06T12:00:00+00:00",
            "2026-02-06T12:00:00-05:00"
        ]

        for resetAt in formats {
            let json = """
            {
                "percentage_used": 45.0,
                "reset_at": "\(resetAt)"
            }
            """

            // Act
            let data = Data(json.utf8)
            let dto = try JSONDecoder().decode(UsageLimitDTO.self, from: data)

            // Assert
            #expect(dto.resetAt == resetAt, "Failed to decode: \(resetAt)")
        }
    }

    @Test("UsageLimitDTO fails to decode missing percentage_used")
    func limitFailsToDecodeMissingPercentage() throws {
        // Arrange
        let json = """
        {
            "reset_at": "2026-02-06T12:00:00Z"
        }
        """

        // Act & Assert
        let data = Data(json.utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(UsageLimitDTO.self, from: data)
        }
    }

    @Test("UsageLimitDTO fails to decode missing reset_at")
    func limitFailsToDecodeMissingResetAt() throws {
        // Arrange
        let json = """
        {
            "percentage_used": 45.0
        }
        """

        // Act & Assert
        let data = Data(json.utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(UsageLimitDTO.self, from: data)
        }
    }

    @Test("UsageLimitDTO fails to decode invalid JSON")
    func limitFailsToDecodeInvalidJSON() throws {
        // Arrange
        let json = "not valid json"

        // Act & Assert
        let data = Data(json.utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(UsageLimitDTO.self, from: data)
        }
    }

    // MARK: - UsageDTO Tests

    @Test("UsageDTO decodes valid JSON")
    func usageDecodesValidJSON() throws {
        // Arrange
        let json = """
        {
            "type": "session",
            "percentage_used": 45.5,
            "reset_at": "2026-02-06T12:00:00Z"
        }
        """

        // Act
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(UsageDTO.self, from: data)

        // Assert
        #expect(dto.type == "session")
        #expect(dto.percentageUsed == 45.5)
        #expect(dto.resetAt == "2026-02-06T12:00:00Z")
    }

    @Test("UsageDTO decodes all usage types")
    func usageDecodesAllTypes() throws {
        // Arrange
        let types = ["session", "weekly", "opus", "sonnet"]

        for type in types {
            let json = """
            {
                "type": "\(type)",
                "percentage_used": 50.0,
                "reset_at": "2026-02-06T12:00:00Z"
            }
            """

            // Act
            let data = Data(json.utf8)
            let dto = try JSONDecoder().decode(UsageDTO.self, from: data)

            // Assert
            #expect(dto.type == type, "Failed to decode type: \(type)")
        }
    }

    @Test("UsageDTO decodes custom type string")
    func usageDecodesCustomType() throws {
        // Arrange
        let json = """
        {
            "type": "custom_type",
            "percentage_used": 50.0,
            "reset_at": "2026-02-06T12:00:00Z"
        }
        """

        // Act
        let data = Data(json.utf8)
        let dto = try JSONDecoder().decode(UsageDTO.self, from: data)

        // Assert
        #expect(dto.type == "custom_type")
    }

    // MARK: - Round-trip Encoding Tests

    @Test("UsageResponseDTO encodes and decodes correctly")
    func responseRoundTrip() throws {
        // Arrange
        let original = UsageResponseDTO(
            sessionLimit: UsageLimitDTO(percentageUsed: 45.5, resetAt: "2026-02-06T12:00:00Z"),
            weeklyLimit: UsageLimitDTO(percentageUsed: 30.0, resetAt: "2026-02-10T00:00:00Z"),
            opusLimit: nil,
            sonnetLimit: nil
        )

        // Act
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UsageResponseDTO.self, from: encoded)

        // Assert
        #expect(decoded.sessionLimit?.percentageUsed == 45.5)
        #expect(decoded.weeklyLimit?.percentageUsed == 30.0)
        #expect(decoded.opusLimit == nil)
        #expect(decoded.sonnetLimit == nil)
    }

    @Test("UsageLimitDTO encodes and decodes correctly")
    func limitRoundTrip() throws {
        // Arrange
        let original = UsageLimitDTO(
            percentageUsed: 75.5,
            resetAt: "2026-02-06T12:00:00Z"
        )

        // Act
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UsageLimitDTO.self, from: encoded)

        // Assert
        #expect(decoded.percentageUsed == 75.5)
        #expect(decoded.resetAt == "2026-02-06T12:00:00Z")
    }

    @Test("UsageDTO encodes and decodes correctly")
    func usageRoundTrip() throws {
        // Arrange
        let original = UsageDTO(
            type: "session",
            percentageUsed: 45.5,
            resetAt: "2026-02-06T12:00:00Z"
        )

        // Act
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UsageDTO.self, from: encoded)

        // Assert
        #expect(decoded.type == "session")
        #expect(decoded.percentageUsed == 45.5)
        #expect(decoded.resetAt == "2026-02-06T12:00:00Z")
    }
}
