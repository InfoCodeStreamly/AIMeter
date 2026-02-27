import Foundation

/// Deepgram account balance information
public struct DeepgramBalance: Sendable, Equatable {
    public let amount: Double
    public let units: String

    public nonisolated init(amount: Double, units: String) {
        self.amount = amount
        self.units = units
    }

    /// Formatted display text, e.g. "$187.50 remaining"
    public var displayText: String {
        let formatted = String(format: "%.2f", amount)
        let symbol = units.lowercased() == "usd" ? "$" : units.uppercased() + " "
        return "\(symbol)\(formatted) remaining"
    }
}
