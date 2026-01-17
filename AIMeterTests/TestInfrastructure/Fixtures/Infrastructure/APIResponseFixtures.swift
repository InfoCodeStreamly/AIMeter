import Foundation
@testable import AIMeter

enum APIResponseFixtures {
    
    // MARK: - JSON Responses
    static let validUsageJSON = """
    {
        "five_hour": {
            "utilization": 45.0,
            "resets_at": "2026-01-17T20:00:00Z"
        },
        "seven_day": {
            "utilization": 30.0,
            "resets_at": "2026-01-24T00:00:00Z"
        },
        "seven_day_opus": {
            "utilization": 10.0,
            "resets_at": "2026-01-24T00:00:00Z"
        },
        "seven_day_sonnet": {
            "utilization": 25.0,
            "resets_at": "2026-01-24T00:00:00Z"
        }
    }
    """
    
    static let highUsageJSON = """
    {
        "five_hour": {
            "utilization": 95.0,
            "resets_at": "2026-01-17T20:00:00Z"
        },
        "seven_day": {
            "utilization": 85.0,
            "resets_at": "2026-01-24T00:00:00Z"
        },
        "seven_day_opus": {
            "utilization": 50.0,
            "resets_at": "2026-01-24T00:00:00Z"
        },
        "seven_day_sonnet": {
            "utilization": 70.0,
            "resets_at": "2026-01-24T00:00:00Z"
        }
    }
    """
    
    static let errorJSON = """
    {
        "error": {
            "type": "authentication_error",
            "message": "Invalid API key"
        }
    }
    """
}
