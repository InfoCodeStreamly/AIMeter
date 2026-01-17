import Foundation
import AIMeterDomain

/// Validates OAuth token via API and saves if valid
public final class ValidateSessionKeyUseCase: Sendable {
    private let sessionKeyRepository: any SessionKeyRepository

    public init(sessionKeyRepository: any SessionKeyRepository) {
        self.sessionKeyRepository = sessionKeyRepository
    }

    /// Validates OAuth token and saves if valid
    /// - Parameter rawKey: Raw OAuth token string
    /// - Throws: DomainError or InfrastructureError
    public func execute(rawKey: String) async throws {
        // 1. Create and validate SessionKey value object
        let sessionKey = try SessionKey.create(rawKey)

        // 2. Validate token via API
        try await sessionKeyRepository.validateToken(rawKey)

        // 3. Save validated key to Keychain
        try await sessionKeyRepository.save(sessionKey)
    }
}
