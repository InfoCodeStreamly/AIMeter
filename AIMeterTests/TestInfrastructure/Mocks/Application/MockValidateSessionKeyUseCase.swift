import Foundation
@testable import AIMeter

final class MockValidateSessionKeyUseCase: @unchecked Sendable {
    
    // MARK: - Stub Results
    var executeResult: Result<SessionKey, Error> = .success(SessionKeyFixtures.valid)
    
    // MARK: - Call Tracking
    private(set) var executeCallCount = 0
    private(set) var lastRawKey: String?
    
    // MARK: - Mock Implementation
    func execute(rawKey: String) async throws -> SessionKey {
        executeCallCount += 1
        lastRawKey = rawKey
        return try executeResult.get()
    }
    
    // MARK: - Test Helpers
    func stubResult(_ result: Result<SessionKey, Error>) {
        executeResult = result
    }
    
    func reset() {
        executeCallCount = 0
        lastRawKey = nil
        executeResult = .success(SessionKeyFixtures.valid)
    }
}
