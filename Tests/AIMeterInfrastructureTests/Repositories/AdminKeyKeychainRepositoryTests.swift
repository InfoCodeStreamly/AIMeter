import Testing
@testable import AIMeterInfrastructure
import AIMeterApplication
import AIMeterDomain

/// Tests for AdminKeyKeychainRepository — CRUD operations via KeychainService.
@Suite("AdminKeyKeychainRepository")
struct AdminKeyKeychainRepositoryTests {

    // MARK: - save Tests

    @Test("save calls keychainService save with key value and correct key name")
    func saveCallsKeychainSave() async throws {
        // Arrange
        let mockKeychain = MockKeychainService()
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)
        let key = try AdminAPIKey.create("sk-ant-admin-abc123def456789xyz")

        // Act
        try await repo.save(key)

        // Assert
        #expect(await mockKeychain.saveCallCount == 1)
        #expect(await mockKeychain.lastSavedValue == "sk-ant-admin-abc123def456789xyz")
        #expect(await mockKeychain.lastSavedKey == "adminAPIKey")
    }

    @Test("save propagates keychain errors")
    func savePropagatesKeychainErrors() async throws {
        // Arrange
        let mockKeychain = MockKeychainService()
        await mockKeychain.configure(saveError: TestKeychainError.accessDenied)
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)
        let key = try AdminAPIKey.create("sk-ant-admin-abc123def456789xyz")

        // Act & Assert
        await #expect(throws: TestKeychainError.accessDenied) {
            try await repo.save(key)
        }
    }

    // MARK: - get Tests

    @Test("get returns nil when keychain has no value")
    func getReturnsNilWhenNoValue() async {
        // Arrange
        let mockKeychain = MockKeychainService()
        await mockKeychain.configure(readResult: nil)
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)

        // Act
        let result = await repo.get()

        // Assert
        #expect(result == nil)
        #expect(await mockKeychain.readCallCount == 1)
    }

    @Test("get returns key when keychain has valid value")
    func getReturnsKeyWhenValidValueStored() async {
        // Arrange
        let mockKeychain = MockKeychainService()
        await mockKeychain.configure(readResult: "sk-ant-admin-abc123def456789xyz")
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)

        // Act
        let result = await repo.get()

        // Assert
        #expect(result?.value == "sk-ant-admin-abc123def456789xyz")
        #expect(await mockKeychain.readCallCount == 1)
    }

    @Test("get returns nil when stored value is invalid key format")
    func getReturnsNilWhenStoredValueInvalid() async {
        // Arrange — stored value doesn't pass AdminAPIKey.create validation
        let mockKeychain = MockKeychainService()
        await mockKeychain.configure(readResult: "invalid-key-format")
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)

        // Act
        let result = await repo.get()

        // Assert — AdminAPIKey.create throws, so get returns nil
        #expect(result == nil)
    }

    @Test("get reads from correct keychain key name")
    func getReadsFromCorrectKeychainKey() async {
        // Arrange
        let mockKeychain = MockKeychainService()
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)

        // Act
        _ = await repo.get()

        // Assert
        #expect(await mockKeychain.lastReadKey == "adminAPIKey")
    }

    // MARK: - delete Tests

    @Test("delete calls keychainService delete with correct key name")
    func deleteCallsKeychainDelete() async {
        // Arrange
        let mockKeychain = MockKeychainService()
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)

        // Act
        await repo.delete()

        // Assert
        #expect(await mockKeychain.deleteCallCount == 1)
        #expect(await mockKeychain.lastDeletedKey == "adminAPIKey")
    }

    @Test("delete does not throw even when keychain delete fails")
    func deleteDoesNotThrowOnError() async {
        // Arrange — delete() catches errors internally (try? pattern in source)
        let mockKeychain = MockKeychainService()
        await mockKeychain.configure(deleteError: TestKeychainError.accessDenied)
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)

        // Act — should not throw
        await repo.delete()

        // Assert — delete was attempted
        #expect(await mockKeychain.deleteCallCount == 1)
    }

    // MARK: - exists Tests

    @Test("exists returns true when keychain reports key exists")
    func existsReturnsTrueWhenKeyExists() async {
        // Arrange
        let mockKeychain = MockKeychainService()
        await mockKeychain.configure(existsResult: true)
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)

        // Act
        let result = await repo.exists()

        // Assert
        #expect(result == true)
        #expect(await mockKeychain.existsCallCount == 1)
    }

    @Test("exists returns false when keychain reports key absent")
    func existsReturnsFalseWhenKeyAbsent() async {
        // Arrange
        let mockKeychain = MockKeychainService()
        await mockKeychain.configure(existsResult: false)
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)

        // Act
        let result = await repo.exists()

        // Assert
        #expect(result == false)
    }

    @Test("exists checks correct keychain key name")
    func existsChecksCorrectKeyName() async {
        // Arrange
        let mockKeychain = MockKeychainService()
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)

        // Act
        _ = await repo.exists()

        // Assert
        #expect(await mockKeychain.lastExistsKey == "adminAPIKey")
    }

    // MARK: - Full CRUD Cycle Tests

    @Test("save then get returns the stored key")
    func saveThenGetReturnsStoredKey() async throws {
        // Arrange — use a real MockKeychainService that stores in memory
        let mockKeychain = InMemoryMockKeychainService()
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)
        let key = try AdminAPIKey.create("sk-ant-admin-abc123def456789xyz")

        // Act
        try await repo.save(key)
        let retrieved = await repo.get()

        // Assert
        #expect(retrieved == key)
    }

    @Test("save then delete then get returns nil")
    func saveThenDeleteThenGetReturnsNil() async throws {
        // Arrange
        let mockKeychain = InMemoryMockKeychainService()
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)
        let key = try AdminAPIKey.create("sk-ant-admin-abc123def456789xyz")

        // Act
        try await repo.save(key)
        await repo.delete()
        let retrieved = await repo.get()

        // Assert
        #expect(retrieved == nil)
    }

    @Test("exists returns true after save and false after delete")
    func existsReturnsTrueAfterSaveFalseAfterDelete() async throws {
        // Arrange
        let mockKeychain = InMemoryMockKeychainService()
        let repo = AdminKeyKeychainRepository(keychainService: mockKeychain)
        let key = try AdminAPIKey.create("sk-ant-admin-abc123def456789xyz")

        // Act & Assert — sequence
        #expect(await repo.exists() == false)
        try await repo.save(key)
        #expect(await repo.exists() == true)
        await repo.delete()
        #expect(await repo.exists() == false)
    }
}

// MARK: - Test Helpers

private enum TestKeychainError: Error, Equatable {
    case accessDenied
}

// MARK: - Spy Mock (records calls, configurable results)

private actor MockKeychainService: KeychainServiceProtocol {
    var saveCallCount = 0
    var readCallCount = 0
    var deleteCallCount = 0
    var existsCallCount = 0

    var lastSavedValue: String?
    var lastSavedKey: String?
    var lastReadKey: String?
    var lastDeletedKey: String?
    var lastExistsKey: String?

    var readResult: String?
    var existsResult = false
    var saveError: (any Error)?
    var deleteError: (any Error)?

    func configure(
        readResult: String?? = nil,
        existsResult: Bool? = nil,
        saveError: (any Error)? = nil,
        deleteError: (any Error)? = nil
    ) {
        if let readResult { self.readResult = readResult }
        if let existsResult { self.existsResult = existsResult }
        if let saveError { self.saveError = saveError }
        if let deleteError { self.deleteError = deleteError }
    }

    func save(_ value: String, forKey key: String) async throws {
        saveCallCount += 1
        lastSavedValue = value
        lastSavedKey = key
        if let error = saveError { throw error }
    }

    func read(forKey key: String) async -> String? {
        readCallCount += 1
        lastReadKey = key
        return readResult
    }

    func delete(forKey key: String) async throws {
        deleteCallCount += 1
        lastDeletedKey = key
        if let error = deleteError { throw error }
    }

    func exists(forKey key: String) async -> Bool {
        existsCallCount += 1
        lastExistsKey = key
        return existsResult
    }
}

// MARK: - In-Memory Mock (for CRUD cycle tests)

private actor InMemoryMockKeychainService: KeychainServiceProtocol {
    private var storage: [String: String] = [:]

    func save(_ value: String, forKey key: String) async throws {
        storage[key] = value
    }

    func read(forKey key: String) async -> String? {
        storage[key]
    }

    func delete(forKey key: String) async throws {
        storage.removeValue(forKey: key)
    }

    func exists(forKey key: String) async -> Bool {
        storage[key] != nil
    }
}
