import Testing
@testable import AIMeterApplication
import AIMeterDomain

/// Tests for GetAdminKeyUseCase — get, delete and isConfigured operations.
@Suite("GetAdminKeyUseCase")
struct GetAdminKeyUseCaseTests {

    // MARK: - execute (get) Tests

    @Test("execute returns key when repository has stored key")
    func executeReturnsKeyWhenStored() async throws {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let storedKey = try AdminAPIKey.create("sk-ant-admin-abc123def456789xyz")
        await mockRepo.configure(getResult: storedKey)

        let useCase = GetAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result == storedKey)
        #expect(await mockRepo.getCallCount == 1)
    }

    @Test("execute returns nil when no key stored")
    func executeReturnsNilWhenNoKeyStored() async {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        await mockRepo.configure(getResult: nil)

        let useCase = GetAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result == nil)
        #expect(await mockRepo.getCallCount == 1)
    }

    @Test("execute calls repository get method")
    func executeCallsRepositoryGet() async {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let useCase = GetAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act
        _ = await useCase.execute()

        // Assert
        #expect(await mockRepo.getCallCount == 1)
    }

    // MARK: - delete Tests

    @Test("delete calls repository delete method")
    func deleteCallsRepositoryDelete() async {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let useCase = GetAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act
        await useCase.delete()

        // Assert
        #expect(await mockRepo.deleteCallCount == 1)
    }

    @Test("delete does not call get or exists methods")
    func deleteDoesNotCallOtherMethods() async {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let useCase = GetAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act
        await useCase.delete()

        // Assert — only delete should be called
        #expect(await mockRepo.getCallCount == 0)
        #expect(await mockRepo.existsCallCount == 0)
        #expect(await mockRepo.deleteCallCount == 1)
    }

    // MARK: - isConfigured Tests

    @Test("isConfigured returns true when key exists")
    func isConfiguredReturnsTrueWhenKeyExists() async {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        await mockRepo.configure(existsResult: true)

        let useCase = GetAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act
        let result = await useCase.isConfigured()

        // Assert
        #expect(result == true)
        #expect(await mockRepo.existsCallCount == 1)
    }

    @Test("isConfigured returns false when no key exists")
    func isConfiguredReturnsFalseWhenNoKeyExists() async {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        await mockRepo.configure(existsResult: false)

        let useCase = GetAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act
        let result = await useCase.isConfigured()

        // Assert
        #expect(result == false)
        #expect(await mockRepo.existsCallCount == 1)
    }

    @Test("isConfigured calls repository exists method")
    func isConfiguredCallsRepositoryExists() async {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let useCase = GetAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act
        _ = await useCase.isConfigured()

        // Assert
        #expect(await mockRepo.existsCallCount == 1)
    }

    // MARK: - Independent Operation Tests

    @Test("execute and isConfigured use separate repository methods")
    func executeAndIsConfiguredUseSeparateMethods() async throws {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let storedKey = try AdminAPIKey.create("sk-ant-admin-abc123def456789xyz")
        await mockRepo.configure(getResult: storedKey, existsResult: true)

        let useCase = GetAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act
        let key = await useCase.execute()
        let configured = await useCase.isConfigured()

        // Assert
        #expect(key == storedKey)
        #expect(configured == true)
        #expect(await mockRepo.getCallCount == 1)
        #expect(await mockRepo.existsCallCount == 1)
    }
}

// MARK: - Mock Implementation

private actor MockAdminKeyRepository: AdminKeyRepository {
    var saveCallCount = 0
    var getCallCount = 0
    var deleteCallCount = 0
    var existsCallCount = 0

    var getResult: AdminAPIKey? = nil
    var existsResult = false

    func configure(
        getResult: AdminAPIKey?? = nil,
        existsResult: Bool? = nil
    ) {
        if let getResult { self.getResult = getResult }
        if let existsResult { self.existsResult = existsResult }
    }

    func save(_ key: AdminAPIKey) async throws {
        saveCallCount += 1
    }

    func get() async -> AdminAPIKey? {
        getCallCount += 1
        return getResult
    }

    func delete() async {
        deleteCallCount += 1
    }

    func exists() async -> Bool {
        existsCallCount += 1
        return existsResult
    }
}
