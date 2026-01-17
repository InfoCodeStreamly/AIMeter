import Foundation

/// Use case for retrieving session key status
final class GetSessionKeyUseCase: Sendable {
    private let sessionKeyRepository: any SessionKeyRepository

    init(sessionKeyRepository: any SessionKeyRepository) {
        self.sessionKeyRepository = sessionKeyRepository
    }

    /// Executes the use case
    /// - Returns: Session key if exists, nil otherwise
    func execute() async -> SessionKey? {
        await sessionKeyRepository.get()
    }

    /// Checks if session key is configured
    /// - Returns: True if key exists
    func isConfigured() async -> Bool {
        await sessionKeyRepository.exists()
    }

    /// Deletes stored session key
    func delete() async {
        await sessionKeyRepository.delete()
    }
}
