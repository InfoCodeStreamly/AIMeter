import Foundation
import AIMeterDomain

/// Use case for retrieving session key status
public final class GetSessionKeyUseCase: Sendable {
    private let sessionKeyRepository: any SessionKeyRepository

    public init(sessionKeyRepository: any SessionKeyRepository) {
        self.sessionKeyRepository = sessionKeyRepository
    }

    /// Executes the use case
    /// - Returns: Session key if exists, nil otherwise
    public func execute() async -> SessionKey? {
        await sessionKeyRepository.get()
    }

    /// Checks if session key is configured
    public func isConfigured() async -> Bool {
        await sessionKeyRepository.exists()
    }

    /// Deletes stored session key
    public func delete() async {
        await sessionKeyRepository.delete()
    }
}
