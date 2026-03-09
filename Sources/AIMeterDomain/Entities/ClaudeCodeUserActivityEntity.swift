import Foundation

/// Domain entity representing a single user's Claude Code activity for a day
public struct ClaudeCodeUserActivityEntity: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let date: Date
    public let email: String
    public let customerType: String
    public let terminalType: String
    public let sessions: Int
    public let linesAdded: Int
    public let linesRemoved: Int
    public let commits: Int
    public let pullRequests: Int
    public let editAccepted: Int
    public let editRejected: Int
    public let writeAccepted: Int
    public let writeRejected: Int
    public let models: [ModelUsage]

    public nonisolated init(
        id: UUID = UUID(),
        date: Date,
        email: String,
        customerType: String = "api",
        terminalType: String = "",
        sessions: Int,
        linesAdded: Int,
        linesRemoved: Int,
        commits: Int = 0,
        pullRequests: Int = 0,
        editAccepted: Int = 0,
        editRejected: Int = 0,
        writeAccepted: Int = 0,
        writeRejected: Int = 0,
        models: [ModelUsage] = []
    ) {
        self.id = id
        self.date = date
        self.email = email
        self.customerType = customerType
        self.terminalType = terminalType
        self.sessions = sessions
        self.linesAdded = linesAdded
        self.linesRemoved = linesRemoved
        self.commits = commits
        self.pullRequests = pullRequests
        self.editAccepted = editAccepted
        self.editRejected = editRejected
        self.writeAccepted = writeAccepted
        self.writeRejected = writeRejected
        self.models = models
    }

    /// Tool acceptance rate as percentage (0-100)
    public var acceptanceRate: Double {
        let totalAccepted = editAccepted + writeAccepted
        let totalActions = totalAccepted + editRejected + writeRejected
        guard totalActions > 0 else { return 0 }
        return Double(totalAccepted) / Double(totalActions) * 100.0
    }

    /// Total estimated cost across all models (in cents)
    public var totalEstimatedCostCents: Int {
        models.reduce(0) { $0 + $1.estimatedCostCents }
    }
}

// MARK: - Nested Types

extension ClaudeCodeUserActivityEntity {
    /// Per-model usage breakdown
    public struct ModelUsage: Sendable, Equatable {
        public let model: String
        public let inputTokens: Int
        public let outputTokens: Int
        public let estimatedCostCents: Int

        public nonisolated init(
            model: String,
            inputTokens: Int,
            outputTokens: Int,
            estimatedCostCents: Int
        ) {
            self.model = model
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
            self.estimatedCostCents = estimatedCostCents
        }
    }
}
