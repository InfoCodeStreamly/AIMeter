import Foundation
@testable import AIMeter

final class APIResponseBuilder {
    
    // MARK: - Properties
    private var fiveHourUtilization: Double = 45.0
    private var sevenDayUtilization: Double = 30.0
    private var opusUtilization: Double = 10.0
    private var sonnetUtilization: Double = 25.0
    
    // MARK: - Builder Methods
    func withFiveHourUtilization(_ value: Double) -> Self {
        fiveHourUtilization = value
        return self
    }
    
    func withSevenDayUtilization(_ value: Double) -> Self {
        sevenDayUtilization = value
        return self
    }
    
    func critical() -> Self {
        fiveHourUtilization = 95.0
        sevenDayUtilization = 85.0
        return self
    }
    
    // MARK: - Build
    func buildJSON() -> String {
        """
        {
            "five_hour": {
                "utilization": \(fiveHourUtilization),
                "resets_at": "2026-01-17T20:00:00Z"
            },
            "seven_day": {
                "utilization": \(sevenDayUtilization),
                "resets_at": "2026-01-24T00:00:00Z"
            },
            "seven_day_opus": {
                "utilization": \(opusUtilization),
                "resets_at": "2026-01-24T00:00:00Z"
            },
            "seven_day_sonnet": {
                "utilization": \(sonnetUtilization),
                "resets_at": "2026-01-24T00:00:00Z"
            }
        }
        """
    }
    
    func buildData() -> Data {
        buildJSON().data(using: .utf8)!
    }
}
