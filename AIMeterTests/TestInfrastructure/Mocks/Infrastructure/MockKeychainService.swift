import Foundation
@testable import AIMeter

actor MockKeychainService: KeychainServiceProtocol {
    
    // MARK: - Storage
    private var storage: [String: String] = [:]
    
    // MARK: - Call Tracking
    private(set) var saveCallCount = 0
    private(set) var readCallCount = 0
    private(set) var deleteCallCount = 0
    
    // MARK: - Mock Implementation
    func save(_ value: String, forKey key: String) async throws {
        saveCallCount += 1
        storage[key] = value
    }
    
    func read(forKey key: String) async -> String? {
        readCallCount += 1
        return storage[key]
    }
    
    func delete(forKey key: String) async throws {
        deleteCallCount += 1
        storage.removeValue(forKey: key)
    }
    
    func exists(forKey key: String) async -> Bool {
        storage[key] != nil
    }
    
    // MARK: - Test Helpers
    func reset() {
        storage = [:]
        saveCallCount = 0
        readCallCount = 0
        deleteCallCount = 0
    }
    
    func preload(_ data: [String: String]) {
        storage = data
    }
}
