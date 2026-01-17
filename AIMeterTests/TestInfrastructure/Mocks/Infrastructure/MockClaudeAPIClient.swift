import Foundation
@testable import AIMeter

actor MockClaudeAPIClient: ClaudeAPIClientProtocol {

    // MARK: - Stub Results
    var fetchUsageResult: Result<UsageAPIResponse, Error> = .failure(InfrastructureError.networkUnavailable)
    var validateTokenResult: Result<Void, Error> = .success(())

    // MARK: - Call Tracking
    private(set) var fetchUsageCallCount = 0
    private(set) var validateTokenCallCount = 0
    private(set) var lastToken: String?

    // MARK: - Protocol Implementation
    func fetchUsage(token: String) async throws -> UsageAPIResponse {
        fetchUsageCallCount += 1
        lastToken = token
        return try fetchUsageResult.get()
    }

    func validateToken(_ token: String) async throws {
        validateTokenCallCount += 1
        lastToken = token
        try validateTokenResult.get()
    }

    // MARK: - Test Helpers
    func reset() {
        fetchUsageCallCount = 0
        validateTokenCallCount = 0
        lastToken = nil
        fetchUsageResult = .failure(InfrastructureError.networkUnavailable)
        validateTokenResult = .success(())
    }

    func stubValidateTokenSuccess() {
        validateTokenResult = .success(())
    }

    func stubValidateTokenError(_ error: Error) {
        validateTokenResult = .failure(error)
    }

    func stubFetchUsageSuccess(_ response: UsageAPIResponse) {
        fetchUsageResult = .success(response)
    }

    func stubFetchUsageError(_ error: Error) {
        fetchUsageResult = .failure(error)
    }
}
