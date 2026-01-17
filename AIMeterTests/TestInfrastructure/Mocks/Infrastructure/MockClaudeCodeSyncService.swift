import Foundation
@testable import AIMeter

actor MockClaudeCodeSyncService: ClaudeCodeSyncServiceProtocol {

    // MARK: - Stub Results
    var hasCredentialsResult: Bool = true
    var extractOAuthCredentialsResult: Result<OAuthCredentials, Error> = .success(OAuthCredentialsFixtures.valid)
    var subscriptionInfo: (type: String, email: String?)? = ("pro", "test@example.com")

    // MARK: - Call Tracking
    private(set) var hasCredentialsCallCount = 0
    private(set) var extractCallCount = 0
    private(set) var getSubscriptionInfoCallCount = 0
    private(set) var updateCredentialsCallCount = 0
    var updateCredentialsResult: Result<Void, Error> = .success(())

    // MARK: - Protocol Implementation
    func hasCredentials() async -> Bool {
        hasCredentialsCallCount += 1
        return hasCredentialsResult
    }

    func extractOAuthCredentials() async throws -> OAuthCredentials {
        extractCallCount += 1
        return try extractOAuthCredentialsResult.get()
    }

    func getSubscriptionInfo() async -> (type: String, email: String?)? {
        getSubscriptionInfoCallCount += 1
        return subscriptionInfo
    }

    func updateCredentials(_ credentials: OAuthCredentials) async throws {
        updateCredentialsCallCount += 1
        try updateCredentialsResult.get()
    }

    // MARK: - Test Helpers
    func reset() {
        hasCredentialsResult = true
        extractOAuthCredentialsResult = .success(OAuthCredentialsFixtures.valid)
        subscriptionInfo = ("pro", "test@example.com")
        hasCredentialsCallCount = 0
        extractCallCount = 0
        getSubscriptionInfoCallCount = 0
    }

    func stubHasCredentials(_ value: Bool) {
        hasCredentialsResult = value
    }

    func stubExtractResult(_ result: Result<OAuthCredentials, Error>) {
        extractOAuthCredentialsResult = result
    }

    func stubNoCredentials() {
        hasCredentialsResult = false
        subscriptionInfo = nil
    }

    func stubUpdateCredentialsError(_ error: Error) {
        updateCredentialsResult = .failure(error)
    }
}
