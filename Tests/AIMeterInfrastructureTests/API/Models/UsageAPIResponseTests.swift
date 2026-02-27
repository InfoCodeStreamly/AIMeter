import Testing
@testable import AIMeterInfrastructure
import Foundation

@Suite("UsageAPIResponse")
struct UsageAPIResponseTests {

    // MARK: - Decoding Tests

    @Test("decodes complete response with all fields")
    func decodesCompleteResponse() throws {
        // Arrange
        let json = """
        {
          "five_hour": {
            "resets_at": "2026-02-06T15:00:00Z",
            "utilization": 45.5
          },
          "seven_day": {
            "resets_at": "2026-02-10T00:00:00Z",
            "utilization": 30.0
          },
          "seven_day_opus": {
            "resets_at": "2026-02-10T00:00:00Z",
            "utilization": 25.0
          },
          "seven_day_sonnet": {
            "resets_at": "2026-02-10T00:00:00Z",
            "utilization": 35.0
          },
          "seven_day_oauth_apps": {
            "resets_at": "2026-02-10T00:00:00Z",
            "utilization": 20.0
          },
          "extra_usage": {
            "is_enabled": true,
            "monthly_limit": 50.0,
            "used_credits": 12.5,
            "utilization": 25.0
          }
        }
        """.data(using: .utf8)!

        // Act
        let response = try JSONDecoder().decode(UsageAPIResponse.self, from: json)

        // Assert
        #expect(response.fiveHour != nil)
        #expect(response.fiveHour?.utilization == 45.5)
        #expect(response.fiveHour?.resetsAt == "2026-02-06T15:00:00Z")

        #expect(response.sevenDay != nil)
        #expect(response.sevenDay?.utilization == 30.0)

        #expect(response.sevenDayOpus != nil)
        #expect(response.sevenDayOpus?.utilization == 25.0)

        #expect(response.sevenDaySonnet != nil)
        #expect(response.sevenDaySonnet?.utilization == 35.0)

        #expect(response.sevenDayOauthApps != nil)
        #expect(response.sevenDayOauthApps?.utilization == 20.0)

        #expect(response.extraUsage != nil)
        #expect(response.extraUsage?.isEnabled == true)
        #expect(response.extraUsage?.monthlyLimit == 50.0)
        #expect(response.extraUsage?.usedCredits == 12.5)
        #expect(response.extraUsage?.utilization == 25.0)
    }

    @Test("decodes response with only session usage")
    func decodesSessionOnly() throws {
        // Arrange
        let json = """
        {
          "five_hour": {
            "resets_at": "2026-02-06T15:00:00Z",
            "utilization": 60.0
          }
        }
        """.data(using: .utf8)!

        // Act
        let response = try JSONDecoder().decode(UsageAPIResponse.self, from: json)

        // Assert
        #expect(response.fiveHour != nil)
        #expect(response.fiveHour?.utilization == 60.0)
        #expect(response.sevenDay == nil)
        #expect(response.sevenDayOpus == nil)
        #expect(response.sevenDaySonnet == nil)
        #expect(response.extraUsage == nil)
    }

    @Test("decodes response with fractional seconds in resets_at")
    func decodesWithFractionalSeconds() throws {
        // Arrange
        let json = """
        {
          "five_hour": {
            "resets_at": "2026-02-06T15:30:45.689Z",
            "utilization": 45.5
          }
        }
        """.data(using: .utf8)!

        // Act
        let response = try JSONDecoder().decode(UsageAPIResponse.self, from: json)

        // Assert
        #expect(response.fiveHour != nil)
        #expect(response.fiveHour?.resetsAt == "2026-02-06T15:30:45.689Z")
    }

    @Test("decodes response with zero utilization")
    func decodesZeroUtilization() throws {
        // Arrange
        let json = """
        {
          "five_hour": {
            "resets_at": "2026-02-06T15:00:00Z",
            "utilization": 0.0
          },
          "seven_day": {
            "resets_at": "2026-02-10T00:00:00Z",
            "utilization": 0.0
          }
        }
        """.data(using: .utf8)!

        // Act
        let response = try JSONDecoder().decode(UsageAPIResponse.self, from: json)

        // Assert
        #expect(response.fiveHour?.utilization == 0.0)
        #expect(response.sevenDay?.utilization == 0.0)
    }

    @Test("decodes response with 100 percent utilization")
    func decodesMaxUtilization() throws {
        // Arrange
        let json = """
        {
          "five_hour": {
            "resets_at": "2026-02-06T15:00:00Z",
            "utilization": 100.0
          }
        }
        """.data(using: .utf8)!

        // Act
        let response = try JSONDecoder().decode(UsageAPIResponse.self, from: json)

        // Assert
        #expect(response.fiveHour?.utilization == 100.0)
    }

    @Test("decodes extra usage with partial fields")
    func decodesExtraUsagePartial() throws {
        // Arrange
        let json = """
        {
          "extra_usage": {
            "is_enabled": false
          }
        }
        """.data(using: .utf8)!

        // Act
        let response = try JSONDecoder().decode(UsageAPIResponse.self, from: json)

        // Assert
        #expect(response.extraUsage != nil)
        #expect(response.extraUsage?.isEnabled == false)
        #expect(response.extraUsage?.monthlyLimit == nil)
        #expect(response.extraUsage?.usedCredits == nil)
        #expect(response.extraUsage?.utilization == nil)
    }

    @Test("decodes extra usage with all nil optional fields")
    func decodesExtraUsageAllNil() throws {
        // Arrange
        let json = """
        {
          "extra_usage": {}
        }
        """.data(using: .utf8)!

        // Act
        let response = try JSONDecoder().decode(UsageAPIResponse.self, from: json)

        // Assert
        #expect(response.extraUsage != nil)
        #expect(response.extraUsage?.isEnabled == nil)
        #expect(response.extraUsage?.monthlyLimit == nil)
        #expect(response.extraUsage?.usedCredits == nil)
        #expect(response.extraUsage?.utilization == nil)
    }

    @Test("decodes empty response")
    func decodesEmptyResponse() throws {
        // Arrange
        let json = "{}".data(using: .utf8)!

        // Act
        let response = try JSONDecoder().decode(UsageAPIResponse.self, from: json)

        // Assert
        #expect(response.fiveHour == nil)
        #expect(response.sevenDay == nil)
        #expect(response.sevenDayOpus == nil)
        #expect(response.sevenDaySonnet == nil)
        #expect(response.extraUsage == nil)
    }

    // MARK: - UsagePeriodData Tests

    @Test("UsagePeriodData decodes correctly")
    func usagePeriodDataDecodes() throws {
        // Arrange
        let json = """
        {
          "resets_at": "2026-02-06T15:00:00Z",
          "utilization": 45.5
        }
        """.data(using: .utf8)!

        // Act
        let data = try JSONDecoder().decode(UsagePeriodData.self, from: json)

        // Assert
        #expect(data.resetsAt == "2026-02-06T15:00:00Z")
        #expect(data.utilization == 45.5)
    }

    // MARK: - ExtraUsageData Tests

    @Test("ExtraUsageData decodes all fields")
    func extraUsageDataDecodesComplete() throws {
        // Arrange
        let json = """
        {
          "is_enabled": true,
          "monthly_limit": 50.0,
          "used_credits": 12.5,
          "utilization": 25.0
        }
        """.data(using: .utf8)!

        // Act
        let data = try JSONDecoder().decode(ExtraUsageData.self, from: json)

        // Assert
        #expect(data.isEnabled == true)
        #expect(data.monthlyLimit == 50.0)
        #expect(data.usedCredits == 12.5)
        #expect(data.utilization == 25.0)
    }

    @Test("ExtraUsageData decodes with disabled")
    func extraUsageDataDisabled() throws {
        // Arrange
        let json = """
        {
          "is_enabled": false
        }
        """.data(using: .utf8)!

        // Act
        let data = try JSONDecoder().decode(ExtraUsageData.self, from: json)

        // Assert
        #expect(data.isEnabled == false)
    }

    // MARK: - Realistic API Response Tests

    @Test("decodes realistic API response")
    func decodesRealisticResponse() throws {
        // Arrange - simulates real API response
        let json = """
        {
          "five_hour": {
            "resets_at": "2026-02-06T18:45:30.123Z",
            "utilization": 67.8
          },
          "seven_day": {
            "resets_at": "2026-02-13T00:00:00Z",
            "utilization": 42.3
          },
          "seven_day_opus": {
            "resets_at": "2026-02-13T00:00:00Z",
            "utilization": 35.1
          },
          "seven_day_sonnet": {
            "resets_at": "2026-02-13T00:00:00Z",
            "utilization": 48.9
          },
          "extra_usage": {
            "is_enabled": true,
            "monthly_limit": 100.0,
            "used_credits": 23.45,
            "utilization": 23.45
          }
        }
        """.data(using: .utf8)!

        // Act
        let response = try JSONDecoder().decode(UsageAPIResponse.self, from: json)

        // Assert
        #expect(response.fiveHour?.utilization == 67.8)
        #expect(response.sevenDay?.utilization == 42.3)
        #expect(response.sevenDayOpus?.utilization == 35.1)
        #expect(response.sevenDaySonnet?.utilization == 48.9)
        #expect(response.extraUsage?.isEnabled == true)
        #expect(response.extraUsage?.usedCredits == 23.45)
    }

    @Test("decodes response with high precision decimal values")
    func decodesHighPrecisionValues() throws {
        // Arrange
        let json = """
        {
          "five_hour": {
            "resets_at": "2026-02-06T15:00:00Z",
            "utilization": 45.5678901234
          }
        }
        """.data(using: .utf8)!

        // Act
        let response = try JSONDecoder().decode(UsageAPIResponse.self, from: json)

        // Assert
        #expect(response.fiveHour?.utilization == 45.5678901234)
    }

    // MARK: - Optional Field Resilience Tests

    @Test("UsagePeriodData decodes with null utilization")
    func usagePeriodDataNullUtilization() throws {
        let json = """
        {
          "resets_at": "2026-02-06T15:00:00Z",
          "utilization": null
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(UsagePeriodData.self, from: json)
        #expect(data.utilization == nil)
        #expect(data.resetsAt == "2026-02-06T15:00:00Z")
    }

    @Test("UsagePeriodData decodes with null resetsAt")
    func usagePeriodDataNullResetsAt() throws {
        let json = """
        {
          "resets_at": null,
          "utilization": 45.0
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(UsagePeriodData.self, from: json)
        #expect(data.utilization == 45.0)
        #expect(data.resetsAt == nil)
    }

    @Test("UsagePeriodData decodes with missing utilization field")
    func usagePeriodDataMissingUtilization() throws {
        let json = """
        {
          "resets_at": "2026-02-06T15:00:00Z"
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(UsagePeriodData.self, from: json)
        #expect(data.utilization == nil)
        #expect(data.resetsAt == "2026-02-06T15:00:00Z")
    }

    @Test("UsagePeriodData decodes with missing resetsAt field")
    func usagePeriodDataMissingResetsAt() throws {
        let json = """
        {
          "utilization": 80.0
        }
        """.data(using: .utf8)!

        let data = try JSONDecoder().decode(UsagePeriodData.self, from: json)
        #expect(data.utilization == 80.0)
        #expect(data.resetsAt == nil)
    }

    @Test("UsagePeriodData decodes empty object")
    func usagePeriodDataEmpty() throws {
        let json = "{}".data(using: .utf8)!

        let data = try JSONDecoder().decode(UsagePeriodData.self, from: json)
        #expect(data.utilization == nil)
        #expect(data.resetsAt == nil)
    }

    @Test("full response with partial period data decodes")
    func fullResponseWithPartialPeriodData() throws {
        let json = """
        {
          "five_hour": {
            "utilization": 50.0
          },
          "seven_day": {
            "resets_at": "2026-02-10T00:00:00Z"
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(UsageAPIResponse.self, from: json)
        #expect(response.fiveHour?.utilization == 50.0)
        #expect(response.fiveHour?.resetsAt == nil)
        #expect(response.sevenDay?.utilization == nil)
        #expect(response.sevenDay?.resetsAt == "2026-02-10T00:00:00Z")
    }
}
