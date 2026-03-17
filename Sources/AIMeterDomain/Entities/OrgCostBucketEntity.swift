import Foundation

/// Domain entity representing a single cost bucket from Admin API
public struct OrgCostBucketEntity: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let startTime: Date
    public let endTime: Date
    public let workspaceId: String?
    public let costDescription: String?
    public let model: String?
    public let costType: String?
    public let amountCents: Int
    public let currency: String

    public nonisolated init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        workspaceId: String? = nil,
        costDescription: String? = nil,
        model: String? = nil,
        costType: String? = nil,
        amountCents: Int,
        currency: String = "USD"
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.workspaceId = workspaceId
        self.costDescription = costDescription
        self.model = model
        self.costType = costType
        self.amountCents = amountCents
        self.currency = currency
    }

    /// Amount in dollars (e.g., 1250 cents → 12.50)
    public var amountDollars: Double {
        Double(amountCents) / 100.0
    }
}
