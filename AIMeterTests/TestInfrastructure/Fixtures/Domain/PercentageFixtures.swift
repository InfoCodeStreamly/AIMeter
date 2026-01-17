import Foundation
@testable import AIMeter

enum PercentageFixtures {
    
    // MARK: - Base Values (SSOT)
    static let zero: Double = 0.0
    static let safe: Double = 45.0
    static let moderate: Double = 75.0
    static let high: Double = 85.0
    static let critical: Double = 95.0
    static let full: Double = 100.0
    static let overLimit: Double = 105.0
    
    // MARK: - Percentage Objects
    static var safePercentage: Percentage {
        try! Percentage.create(safe)
    }
    
    static var highPercentage: Percentage {
        try! Percentage.create(high)
    }
    
    static var criticalPercentage: Percentage {
        try! Percentage.create(critical)
    }
}
