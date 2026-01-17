import Foundation
@testable import AIMeter

final class MockGetSessionKeyUseCase: @unchecked Sendable {
    
    // MARK: - Stub Results
    var executeResult: SessionKey? = nil
    
    // MARK: - Call Tracking
    private(set) var executeCallCount = 0
    private(set) var deleteCallCount = 0
    
    // MARK: - Mock Implementation
    func execute() async -> SessionKey? {
        executeCallCount += 1
        return executeResult
    }
    
    func delete() async {
        deleteCallCount += 1
    }
    
    // MARK: - Test Helpers
    func stubResult(_ key: SessionKey?) {
        executeResult = key
    }
    
    func reset() {
        executeCallCount = 0
        deleteCallCount = 0
        executeResult = nil
    }
}
