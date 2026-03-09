import Testing
@testable import AIMeterApplication
import AIMeterDomain

/// Tests for SaveAdminKeyUseCase — validates key format before saving.
@Suite("SaveAdminKeyUseCase")
struct SaveAdminKeyUseCaseTests {

    // MARK: - Success Path Tests

    @Test("execute saves valid key to repository")
    func executeSavesValidKeyToRepository() async throws {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let useCase = SaveAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act
        _ = try await useCase.execute(rawKey: "sk-ant-admin-abc123def456789xyz")

        // Assert
        #expect(await mockRepo.saveCallCount == 1)
    }

    @Test("execute returns validated AdminAPIKey")
    func executeReturnsValidatedKey() async throws {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let useCase = SaveAdminKeyUseCase(adminKeyRepository: mockRepo)
        let rawKey = "sk-ant-admin-abc123def456789xyz"

        // Act
        let returnedKey = try await useCase.execute(rawKey: rawKey)

        // Assert
        #expect(returnedKey.value == rawKey)
    }

    @Test("execute saves trimmed key when input has whitespace")
    func executeSavesTrimmedKey() async throws {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let useCase = SaveAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act
        let key = try await useCase.execute(rawKey: "  sk-ant-admin-abc123def456789xyz  ")

        // Assert
        #expect(key.value == "sk-ant-admin-abc123def456789xyz")
        #expect(await mockRepo.saveCallCount == 1)
        #expect(await mockRepo.lastSavedKey?.value == "sk-ant-admin-abc123def456789xyz")
    }

    // MARK: - Failure Path Tests

    @Test("execute throws invalidAdminKeyFormat for wrong prefix")
    func executeThrowsForWrongPrefix() async {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let useCase = SaveAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act & Assert
        await #expect(throws: DomainError.invalidAdminKeyFormat) {
            try await useCase.execute(rawKey: "sk-ant-api03-abcdefghijklmnop")
        }

        // Verify repository was NOT called when validation fails
        #expect(await mockRepo.saveCallCount == 0)
    }

    @Test("execute throws invalidAdminKeyFormat for empty key")
    func executeThrowsForEmptyKey() async {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let useCase = SaveAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act & Assert
        await #expect(throws: DomainError.invalidAdminKeyFormat) {
            try await useCase.execute(rawKey: "")
        }

        #expect(await mockRepo.saveCallCount == 0)
    }

    @Test("execute throws invalidAdminKeyFormat for too short key")
    func executeThrowsForTooShortKey() async {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let useCase = SaveAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act & Assert
        await #expect(throws: DomainError.invalidAdminKeyFormat) {
            try await useCase.execute(rawKey: "sk-ant-admin-abc")
        }

        #expect(await mockRepo.saveCallCount == 0)
    }

    @Test("execute throws invalidAdminKeyFormat for whitespace-only key")
    func executeThrowsForWhitespaceOnlyKey() async {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        let useCase = SaveAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act & Assert
        await #expect(throws: DomainError.invalidAdminKeyFormat) {
            try await useCase.execute(rawKey: "   ")
        }

        #expect(await mockRepo.saveCallCount == 0)
    }

    @Test("execute propagates save errors from repository")
    func executePropagatesRepositorySaveErrors() async {
        // Arrange
        let mockRepo = MockAdminKeyRepository()
        await mockRepo.configure(saveError: TestSaveError.keychainFailed)
        let useCase = SaveAdminKeyUseCase(adminKeyRepository: mockRepo)

        // Act & Assert
        await #expect(throws: TestSaveError.keychainFailed) {
            try await useCase.execute(rawKey: "sk-ant-admin-abc123def456789xyz")
        }
    }
}

// MARK: - Test Helpers

private enum TestSaveError: Error, Equatable {
    case keychainFailed
}

// MARK: - Mock Implementation

private actor MockAdminKeyRepository: AdminKeyRepository {
    var saveCallCount = 0
    var lastSavedKey: AdminAPIKey?
    var saveError: (any Error)?

    func configure(saveError: (any Error)? = nil) {
        if let saveError { self.saveError = saveError }
    }

    func save(_ key: AdminAPIKey) async throws {
        saveCallCount += 1
        lastSavedKey = key
        if let error = saveError { throw error }
    }

    func get() async -> AdminAPIKey? { nil }

    func delete() async {}

    func exists() async -> Bool { false }
}
