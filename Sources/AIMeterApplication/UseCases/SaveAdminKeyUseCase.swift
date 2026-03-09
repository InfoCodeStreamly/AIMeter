import Foundation
import AIMeterDomain

/// Validates and saves an Admin API key
public final class SaveAdminKeyUseCase: Sendable {
    private let adminKeyRepository: any AdminKeyRepository

    public init(adminKeyRepository: any AdminKeyRepository) {
        self.adminKeyRepository = adminKeyRepository
    }

    /// Validates key format and saves to secure storage
    /// - Returns: Validated AdminAPIKey
    /// - Throws: `DomainError.invalidAdminKeyFormat` if invalid
    public func execute(rawKey: String) async throws -> AdminAPIKey {
        let key = try AdminAPIKey.create(rawKey)
        try await adminKeyRepository.save(key)
        return key
    }
}
