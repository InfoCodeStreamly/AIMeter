import Foundation
import AIMeterDomain

/// Display data for team Claude Code analytics
public struct ClaudeCodeAnalyticsDisplayData: Sendable, Equatable {
    public let users: [UserActivityDisplay]
    public let totalSessions: Int
    public let totalLinesAdded: Int
    public let totalCostFormatted: String

    public init(from entities: [ClaudeCodeUserActivityEntity]) {
        self.users = entities.map { UserActivityDisplay(from: $0) }
        self.totalSessions = entities.reduce(0) { $0 + $1.sessions }
        self.totalLinesAdded = entities.reduce(0) { $0 + $1.linesAdded }
        let totalCostCents = entities.reduce(0) { $0 + $1.totalEstimatedCostCents }
        self.totalCostFormatted = String(format: "$%.2f", Double(totalCostCents) / 100.0)
    }
}

/// Display data for a single user's activity
public struct UserActivityDisplay: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let email: String
    public let sessions: Int
    public let linesAdded: Int
    public let linesRemoved: Int
    public let commits: Int
    public let pullRequests: Int
    public let costFormatted: String
    public let acceptanceRate: Int

    public init(from entity: ClaudeCodeUserActivityEntity) {
        self.id = entity.id
        self.email = entity.email
        self.sessions = entity.sessions
        self.linesAdded = entity.linesAdded
        self.linesRemoved = entity.linesRemoved
        self.commits = entity.commits
        self.pullRequests = entity.pullRequests
        self.costFormatted = String(format: "$%.2f", Double(entity.totalEstimatedCostCents) / 100.0)
        self.acceptanceRate = Int(entity.acceptanceRate)
    }
}
