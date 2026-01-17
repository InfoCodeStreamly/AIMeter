import Foundation
@testable import AIMeter

actor MockSessionKeyRepository: SessionKeyRepository {

    // MARK: - Stub Results
    var getResult: SessionKey? = nil
    var saveResult: Result<Void, Error> = .success(())
    var deleteResult: Result<Void, Error> = .success(())
    var existsResult: Bool = false
    var validateTokenResult: Result<Void, Error> = .success(())

    // MARK: - Call Tracking
    private(set) var getCallCount = 0
    private(set) var saveCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var existsCallCount = 0
    private(set) var validateTokenCallCount = 0
    private(set) var savedKeys: [SessionKey] = []
    private(set) var lastValidatedToken: String?

    // MARK: - Protocol Implementation
    func get() async -> SessionKey? {
        getCallCount += 1
        return getResult
    }

    func save(_ key: SessionKey) async throws {
        saveCallCount += 1
        savedKeys.append(key)
        try saveResult.get()
    }

    func delete() async {
        deleteCallCount += 1
    }

    func exists() async -> Bool {
        existsCallCount += 1
        return existsResult
    }

    func validateToken(_ token: String) async throws {
        validateTokenCallCount += 1
        lastValidatedToken = token
        try validateTokenResult.get()
    }

    // MARK: - Test Helpers
    func reset() {
        getResult = nil
        saveResult = .success(())
        existsResult = false
        validateTokenResult = .success(())
        getCallCount = 0
        saveCallCount = 0
        deleteCallCount = 0
        existsCallCount = 0
        validateTokenCallCount = 0
        savedKeys = []
        lastValidatedToken = nil
    }

    func stubKey(_ key: SessionKey) {
        getResult = key
        existsResult = true
    }

    func stubValidateTokenError(_ error: Error) {
        validateTokenResult = .failure(error)
    }

    func stubValidateTokenSuccess() {
        validateTokenResult = .success(())
    }
}
