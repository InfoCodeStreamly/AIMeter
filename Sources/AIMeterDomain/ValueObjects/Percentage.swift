import Foundation

/// Validated percentage value (0-100)
public struct Percentage: Sendable, Equatable, Codable {
    public let value: Double

    private nonisolated init(_ value: Double) {
        self.value = value
    }

    /// Creates validated percentage
    /// - Throws: `DomainError.invalidPercentage` if out of range
    public nonisolated static func create(_ value: Double) throws -> Percentage {
        guard value >= 0, value <= 100 else {
            throw DomainError.invalidPercentage(value)
        }
        return Percentage(value)
    }

    /// Creates percentage, clamping to 0-100 range
    public nonisolated static func clamped(_ value: Double) -> Percentage {
        Percentage(min(max(value, 0), 100))
    }

    /// Zero percentage
    public nonisolated static var zero: Percentage { Percentage(0) }

    /// Converts to usage status
    public nonisolated func toStatus() -> UsageStatus {
        switch value {
        case 0..<50: return .safe
        case 50..<80: return .moderate
        default: return .critical
        }
    }

    /// Formatted string (e.g., "75%")
    public var formatted: String { "\(Int(value))%" }
}
