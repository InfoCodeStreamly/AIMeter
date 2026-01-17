import Foundation
@testable import AIMeter

actor MockOAuthCredentialsRepository: OAuthCredentialsRepository {
    
    // MARK: - Stub Results
    var getResult: OAuthCredentials? = OAuthCredentialsFixtures.valid
    var saveResult: Result<Void, Error> = .success(())
    var updateClaudeCodeResult: Result<Void, Error> = .success(())
    
    // MARK: - Call Tracking
    private(set) var getCallCount = 0
    private(set) var saveCallCount = 0
    private(set) var savedCredentials: [OAuthCredentials] = []
    private(set) var updateClaudeCodeCallCount = 0
    
    // MARK: - Protocol Implementation
    func getOAuthCredentials() async -> OAuthCredentials? {
        getCallCount += 1
        return getResult
    }
    
    func saveOAuthCredentials(_ credentials: OAuthCredentials) async throws {
        saveCallCount += 1
        savedCredentials.append(credentials)
        try saveResult.get()
    }
    
    func updateClaudeCodeKeychain(_ credentials: OAuthCredentials) async throws {
        updateClaudeCodeCallCount += 1
        try updateClaudeCodeResult.get()
    }
    
    // MARK: - Test Helpers
    func reset() {
        getResult = OAuthCredentialsFixtures.valid
        saveResult = .success(())
        updateClaudeCodeResult = .success(())
        getCallCount = 0
        saveCallCount = 0
        savedCredentials = []
        updateClaudeCodeCallCount = 0
    }
    
    func stubNoCredentials() {
        getResult = nil
    }
    
    func stubCredentials(_ credentials: OAuthCredentials) {
        getResult = credentials
    }
    
    func stubSaveError(_ error: Error) {
        saveResult = .failure(error)
    }

    func stubUpdateClaudeCodeError(_ error: Error) {
        updateClaudeCodeResult = .failure(error)
    }
}
