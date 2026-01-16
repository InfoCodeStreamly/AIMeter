import Foundation

/// Validated percentage value (0-100)
struct Percentage: Sendable, Equatable, Codable {
    let value: Double

    private nonisolated init(_ value: Double) {
        self.value = value
    }

    /// Creates validated percentage
    /// - Throws: `DomainError.invalidPercentage` if out of range
    nonisolated static func create(_ value: Double) throws -> Percentage {
        guard value >= 0, value <= 100 else {
            throw DomainError.invalidPercentage(value)
        }
        return Percentage(value)
    }

    /// Creates percentage, clamping to 0-100 range
    nonisolated static func clamped(_ value: Double) -> Percentage {
        Percentage(min(max(value, 0), 100))
    }

    /// Zero percentage
    nonisolated static var zero: Percentage { Percentage(0) }

    /// Converts to usage status
    nonisolated func toStatus() -> UsageStatus {
        switch value {
        case 0..<50: return .safe
        case 50..<80: return .moderate
        default: return .critical
        }
    }

    /// Formatted string (e.g., "75%")
    var formatted: String { "\(Int(value))%" }
}
