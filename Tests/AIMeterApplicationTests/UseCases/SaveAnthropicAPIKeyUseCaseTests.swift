import Testing
@testable import AIMeterApplication
import AIMeterDomain

/// Tests for SaveAnthropicAPIKeyUseCase — validates key format before saving.
@Suite("SaveAnthropicAPIKeyUseCase")
struct SaveAnthropicAPIKeyUseCaseTests {

    // MARK: - Success Path Tests

    @Test("execute saves valid key to repository")
    func executeSavesValidKeyToRepository() async throws {
        // Arrange
        let mockRepo = MockAPIKeyRepository()
        let useCase = SaveAnthropicAPIKeyUseCase(apiKeyRepository: mockRepo)

        // Act
        _ = try await useCase.execute(rawKey: "sk-ant-api03-abc123def456789xyz")

        // Assert
        #expect(await mockRepo.saveCallCount == 1)
    }

    @Test("execute returns validated AnthropicAPIKey")
    func executeReturnsValidatedKey() async throws {
        // Arrange
        let mockRepo = MockAPIKeyRepository()
        let useCase = SaveAnthropicAPIKeyUseCase(apiKeyRepository: mockRepo)
        let rawKey = "sk-ant-api03-abc123def456789xyz"

        // Act
        let returnedKey = try await useCase.execute(rawKey: rawKey)

        // Assert
        #expect(returnedKey.value == rawKey)
    }

    @Test("execute saves trimmed key when input has whitespace")
    func executeSavesTrimmedKey() async throws {
        // Arrange
        let mockRepo = MockAPIKeyRepository()
        let useCase = SaveAnthropicAPIKeyUseCase(apiKeyRepository: mockRepo)

        // Act
        let key = try await useCase.execute(rawKey: "  sk-ant-api03-abc123def456789xyz  ")

        // Assert
        #expect(key.value == "sk-ant-api03-abc123def456789xyz")
        #expect(await mockRepo.saveCallCount == 1)
        #expect(await mockRepo.lastSavedKey?.value == "sk-ant-api03-abc123def456789xyz")
    }

    // MARK: - Failure Path Tests

    @Test("execute throws invalidAPIKeyFormat for wrong prefix and does not call repository")
    func executeThrowsForWrongPrefix() async {
        // Arrange
        let mockRepo = MockAPIKeyRepository()
        let useCase = SaveAnthropicAPIKeyUseCase(apiKeyRepository: mockRepo)

        // Act & Assert
        await #expect(throws: DomainError.invalidAPIKeyFormat) {
            try await useCase.execute(rawKey: "sk-ant-admin-abcdefghijklmnop")
        }

        // Verify repository was NOT called when validation fails
        #expect(await mockRepo.saveCallCount == 0)
    }

    @Test("execute throws invalidAPIKeyFormat for empty key and does not call repository")
    func executeThrowsForEmptyKey() async {
        // Arrange
        let mockRepo = MockAPIKeyRepository()
        let useCase = SaveAnthropicAPIKeyUseCase(apiKeyRepository: mockRepo)

        // Act & Assert
        await #expect(throws: DomainError.invalidAPIKeyFormat) {
            try await useCase.execute(rawKey: "")
        }

        #expect(await mockRepo.saveCallCount == 0)
    }

    @Test("execute throws invalidAPIKeyFormat for too short key and does not call repository")
    func executeThrowsForTooShortKey() async {
        // Arrange
        let mockRepo = MockAPIKeyRepository()
        let useCase = SaveAnthropicAPIKeyUseCase(apiKeyRepository: mockRepo)

        // Act & Assert
        await #expect(throws: DomainError.invalidAPIKeyFormat) {
            try await useCase.execute(rawKey: "sk-ant-api03-ab")
        }

        #expect(await mockRepo.saveCallCount == 0)
    }

    @Test("execute throws invalidAPIKeyFormat for whitespace-only key and does not call repository")
    func executeThrowsForWhitespaceOnlyKey() async {
        // Arrange
        let mockRepo = MockAPIKeyRepository()
        let useCase = SaveAnthropicAPIKeyUseCase(apiKeyRepository: mockRepo)

        // Act & Assert
        await #expect(throws: DomainError.invalidAPIKeyFormat) {
            try await useCase.execute(rawKey: "   ")
        }

        #expect(await mockRepo.saveCallCount == 0)
    }

    @Test("execute propagates save errors from repository")
    func executePropagatesRepositorySaveErrors() async {
        // Arrange
        let mockRepo = MockAPIKeyRepository()
        await mockRepo.configure(saveError: TestSaveError.keychainFailed)
        let useCase = SaveAnthropicAPIKeyUseCase(apiKeyRepository: mockRepo)

        // Act & Assert
        await #expect(throws: TestSaveError.keychainFailed) {
            try await useCase.execute(rawKey: "sk-ant-api03-abc123def456789xyz")
        }
    }
}

// MARK: - Test Helpers

private enum TestSaveError: Error, Equatable {
    case keychainFailed
}

// MARK: - Mock Implementation

private actor MockAPIKeyRepository: APIKeyRepository {
    var saveCallCount = 0
    var lastSavedKey: AnthropicAPIKey?
    var saveError: (any Error)?

    func configure(saveError: (any Error)? = nil) {
        if let saveError { self.saveError = saveError }
    }

    func save(_ key: AnthropicAPIKey) async throws {
        saveCallCount += 1
        lastSavedKey = key
        if let error = saveError { throw error }
    }

    func get() async -> AnthropicAPIKey? { nil }

    func delete() async {}

    func exists() async -> Bool { false }
}
