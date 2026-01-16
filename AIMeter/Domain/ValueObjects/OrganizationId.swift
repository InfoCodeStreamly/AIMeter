import Foundation

/// Validated Claude organization UUID
struct OrganizationId: Sendable, Equatable, Codable {
    let value: String

    private nonisolated init(_ value: String) {
        self.value = value
    }

    /// Creates validated organization ID
    /// - Throws: `DomainError.invalidOrganizationId` if invalid
    nonisolated static func create(_ value: String) throws -> OrganizationId {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw DomainError.invalidOrganizationId("empty")
        }

        guard trimmed.count >= 10 else {
            throw DomainError.invalidOrganizationId(trimmed)
        }

        return OrganizationId(trimmed)
    }
}
