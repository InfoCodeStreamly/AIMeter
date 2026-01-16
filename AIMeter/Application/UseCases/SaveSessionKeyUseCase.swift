import Foundation

/// Use case for saving and validating session key
final class SaveSessionKeyUseCase: Sendable {
    private let sessionKeyRepository: any SessionKeyRepository

    init(sessionKeyRepository: any SessionKeyRepository) {
        self.sessionKeyRepository = sessionKeyRepository
    }

    /// Executes the use case
    /// - Parameter rawKey: Raw session key string
    /// - Returns: Validated organization ID (nil for OAuth tokens)
    /// - Throws: Validation or storage errors
    func execute(rawKey: String) async throws -> OrganizationId? {
        // Validate and create session key
        let sessionKey = try SessionKey.create(rawKey)

        // Validate by fetching organization (nil for OAuth tokens)
        let organizationId = try await sessionKeyRepository.fetchOrganizationId(using: sessionKey)

        // Save validated key
        try await sessionKeyRepository.save(sessionKey)

        // Cache organization ID (if present)
        if let organizationId {
            await sessionKeyRepository.cacheOrganizationId(organizationId)
        }

        return organizationId
    }
}
