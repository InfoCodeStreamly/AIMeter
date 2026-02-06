import Testing
@testable import AIMeterApplication
import AIMeterDomain

/// Тести для GetSessionKeyUseCase.
///
/// Перевіряє отримання, існування та видалення ключа сесії через репозиторій.
@Suite("GetSessionKeyUseCase Tests")
struct GetSessionKeyUseCaseTests {

    // MARK: - Execute Tests

    @Test("execute повертає ключ коли репозиторій має збережений ключ")
    func executeReturnsKeyWhenRepositoryHasOne() async throws {
        // Arrange
        let expectedKey = try SessionKey.create("sk-ant-oat01-test-key-for-execute")
        let mockRepository = MockSessionKeyRepository()
        await mockRepository.configure(getResult: expectedKey)
        let useCase = GetSessionKeyUseCase(sessionKeyRepository: mockRepository)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result == expectedKey)
        #expect(await mockRepository.getCallCount == 1)
    }

    @Test("execute повертає nil коли репозиторій порожній")
    func executeReturnsNilWhenRepositoryHasNone() async throws {
        // Arrange
        let mockRepository = MockSessionKeyRepository()
        await mockRepository.configure(getResult: nil)
        let useCase = GetSessionKeyUseCase(sessionKeyRepository: mockRepository)

        // Act
        let result = await useCase.execute()

        // Assert
        #expect(result == nil)
        #expect(await mockRepository.getCallCount == 1)
    }

    // MARK: - IsConfigured Tests

    @Test("isConfigured повертає true коли ключ існує")
    func isConfiguredReturnsTrueWhenExists() async throws {
        // Arrange
        let mockRepository = MockSessionKeyRepository()
        await mockRepository.configure(existsResult: true)
        let useCase = GetSessionKeyUseCase(sessionKeyRepository: mockRepository)

        // Act
        let result = await useCase.isConfigured()

        // Assert
        #expect(result == true)
        #expect(await mockRepository.existsCallCount == 1)
    }

    @Test("isConfigured повертає false коли ключ не існує")
    func isConfiguredReturnsFalseWhenNotExists() async throws {
        // Arrange
        let mockRepository = MockSessionKeyRepository()
        await mockRepository.configure(existsResult: false)
        let useCase = GetSessionKeyUseCase(sessionKeyRepository: mockRepository)

        // Act
        let result = await useCase.isConfigured()

        // Assert
        #expect(result == false)
        #expect(await mockRepository.existsCallCount == 1)
    }

    // MARK: - Delete Tests

    @Test("delete викликає delete репозиторію")
    func deleteCallsRepositoryDelete() async throws {
        // Arrange
        let mockRepository = MockSessionKeyRepository()
        let useCase = GetSessionKeyUseCase(sessionKeyRepository: mockRepository)

        // Act
        await useCase.delete()

        // Assert
        #expect(await mockRepository.deleteCallCount == 1)
    }

    @Test("execute повертає nil після delete")
    func executeReturnsNilAfterDelete() async throws {
        // Arrange
        let initialKey = try SessionKey.create("sk-ant-oat01-initial-key-value")
        let mockRepository = MockSessionKeyRepository()
        await mockRepository.configure(getResult: initialKey)
        let useCase = GetSessionKeyUseCase(sessionKeyRepository: mockRepository)

        // Verify key exists initially
        let beforeDelete = await useCase.execute()
        #expect(beforeDelete == initialKey)

        // Act - delete and reconfigure repository to return nil
        await mockRepository.configure(getResult: nil)
        await useCase.delete()

        // Assert
        let afterDelete = await useCase.execute()
        #expect(afterDelete == nil)
        #expect(await mockRepository.deleteCallCount == 1)
        #expect(await mockRepository.getCallCount == 1) // Once after (configure resets counts)
    }
}

// MARK: - Mock SessionKeyRepository

private actor MockSessionKeyRepository: SessionKeyRepository {
    var saveCallCount = 0
    var getCallCount = 0
    var deleteCallCount = 0
    var existsCallCount = 0
    var validateTokenCallCount = 0

    var savedKey: SessionKey?
    var getResult: SessionKey?
    var existsResult: Bool = false
    var validateTokenError: Error?
    var saveError: Error?

    func configure(
        getResult: SessionKey? = nil,
        existsResult: Bool = false,
        validateTokenError: Error? = nil,
        saveError: Error? = nil
    ) {
        self.getResult = getResult
        self.existsResult = existsResult
        self.validateTokenError = validateTokenError
        self.saveError = saveError

        // Reset call counts
        self.saveCallCount = 0
        self.getCallCount = 0
        self.deleteCallCount = 0
        self.existsCallCount = 0
        self.validateTokenCallCount = 0
    }

    func save(_ key: SessionKey) async throws {
        saveCallCount += 1
        if let error = saveError {
            throw error
        }
        savedKey = key
    }

    func get() async -> SessionKey? {
        getCallCount += 1
        return getResult
    }

    func delete() async {
        deleteCallCount += 1
        savedKey = nil
        getResult = nil
    }

    func exists() async -> Bool {
        existsCallCount += 1
        return existsResult
    }

    func validateToken(_ token: String) async throws {
        validateTokenCallCount += 1
        if let error = validateTokenError {
            throw error
        }
    }
}
