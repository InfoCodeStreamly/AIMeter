import Foundation
@testable import AIMeter

enum ResetTimeFixtures {
    
    // MARK: - Base Values (SSOT)
    static var inOneHour: Date {
        Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    }
    
    static var inFiveHours: Date {
        Calendar.current.date(byAdding: .hour, value: 5, to: Date())!
    }
    
    static var inSevenDays: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    }
    
    static var expired: Date {
        Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
    }
}
