import Foundation

/// Validates session key via API and saves if valid
final class ValidateSessionKeyUseCase: Sendable {
    private let sessionKeyRepository: any SessionKeyRepository

    init(sessionKeyRepository: any SessionKeyRepository) {
        self.sessionKeyRepository = sessionKeyRepository
    }

    /// Validates session key and saves if valid
    /// - Parameter rawKey: Raw session key string from user input
    /// - Returns: OrganizationId if valid (nil for OAuth tokens)
    /// - Throws: DomainError or InfrastructureError
    func execute(rawKey: String) async throws -> OrganizationId? {
        // 1. Create and validate SessionKey value object
        let sessionKey = try SessionKey.create(rawKey)

        // 2. Validate by fetching organization (proves key works)
        // For OAuth tokens, this returns nil (no org ID needed)
        let organizationId = try await sessionKeyRepository.fetchOrganizationId(using: sessionKey)

        // 3. Save validated key to Keychain
        try await sessionKeyRepository.save(sessionKey)

        // 4. Cache organization ID (if present)
        if let organizationId {
            await sessionKeyRepository.cacheOrganizationId(organizationId)
        }

        return organizationId
    }
}
