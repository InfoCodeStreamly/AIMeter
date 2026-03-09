import Foundation

/// Domain entity representing a single usage bucket from Admin API
public struct OrgUsageBucketEntity: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let startTime: Date
    public let endTime: Date
    public let model: String?
    public let workspaceId: String?
    public let inputTokens: Int
    public let outputTokens: Int
    public let cacheReadTokens: Int
    public let cacheCreationTokens: Int

    public nonisolated init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        model: String? = nil,
        workspaceId: String? = nil,
        inputTokens: Int,
        outputTokens: Int,
        cacheReadTokens: Int = 0,
        cacheCreationTokens: Int = 0
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.model = model
        self.workspaceId = workspaceId
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheCreationTokens = cacheCreationTokens
    }

    /// Total tokens (input + output)
    public var totalTokens: Int {
        inputTokens + outputTokens
    }
}
