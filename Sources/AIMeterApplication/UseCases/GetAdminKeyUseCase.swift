import Foundation
import AIMeterDomain

/// Retrieves or manages the stored Admin API key
public final class GetAdminKeyUseCase: Sendable {
    private let adminKeyRepository: any AdminKeyRepository

    public init(adminKeyRepository: any AdminKeyRepository) {
        self.adminKeyRepository = adminKeyRepository
    }

    /// Gets stored Admin API key
    public func execute() async -> AdminAPIKey? {
        await adminKeyRepository.get()
    }

    /// Deletes stored Admin API key
    public func delete() async {
        await adminKeyRepository.delete()
    }

    /// Checks if Admin API key is configured
    public func isConfigured() async -> Bool {
        await adminKeyRepository.exists()
    }
}
