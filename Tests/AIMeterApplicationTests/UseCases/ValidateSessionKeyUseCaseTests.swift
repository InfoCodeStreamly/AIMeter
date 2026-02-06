import Testing
@testable import AIMeterApplication
import AIMeterDomain

/// Тести для ValidateSessionKeyUseCase.
///
/// Перевіряє валідацію та збереження ключа сесії з обробкою помилок.
@Suite("ValidateSessionKeyUseCase Tests")
struct ValidateSessionKeyUseCaseTests {

    // MARK: - Success Path Tests

    @Test("execute з валідним ключем викликає validateToken і save")
    func executeWithValidKeyCallsValidateTokenAndSave() async throws {
        // Arrange
        let validRawKey = "sk-ant-oat01-valid-test-key-value"
        let mockRepository = MockSessionKeyRepository()
        await mockRepository.configure(validateTokenError: nil, saveError: nil)
        let useCase = ValidateSessionKeyUseCase(sessionKeyRepository: mockRepository)

        // Act
        try await useCase.execute(rawKey: validRawKey)

        // Assert
        #expect(await mockRepository.validateTokenCallCount == 1)
        #expect(await mockRepository.saveCallCount == 1)

        let savedKey = await mockRepository.savedKey
        #expect(savedKey != nil)
        #expect(savedKey?.value == validRawKey)
    }

    // MARK: - Invalid Key Tests

    @Test("execute з невалідним ключем викидає DomainError і не викликає validateToken і save")
    func executeWithInvalidKeyThrowsAndDoesNotCallRepository() async throws {
        // Arrange
        let invalidRawKey = "bad-short-key"
        let mockRepository = MockSessionKeyRepository()
        await mockRepository.configure()
        let useCase = ValidateSessionKeyUseCase(sessionKeyRepository: mockRepository)

        // Act & Assert
        do {
            try await useCase.execute(rawKey: invalidRawKey)
            Issue.record("Expected DomainError to be thrown")
        } catch let error as DomainError {
            // Expected error
            #expect(await mockRepository.validateTokenCallCount == 0)
            #expect(await mockRepository.saveCallCount == 0)
        } catch {
            Issue.record("Expected DomainError but got \(type(of: error))")
        }
    }

    @Test("execute з порожнім ключем викидає помилку і не викликає validateToken і save")
    func executeWithEmptyKeyThrowsAndDoesNotCallRepository() async throws {
        // Arrange
        let emptyKey = ""
        let mockRepository = MockSessionKeyRepository()
        await mockRepository.configure()
        let useCase = ValidateSessionKeyUseCase(sessionKeyRepository: mockRepository)

        // Act & Assert
        do {
            try await useCase.execute(rawKey: emptyKey)
            Issue.record("Expected DomainError to be thrown")
        } catch is DomainError {
            // Expected error
            #expect(await mockRepository.validateTokenCallCount == 0)
            #expect(await mockRepository.saveCallCount == 0)
        } catch {
            Issue.record("Expected DomainError but got \(type(of: error))")
        }
    }

    // MARK: - ValidationToken Error Tests

    @Test("validateToken викидає помилку то save не викликається")
    func validateTokenThrowsErrorThenSaveNotCalled() async throws {
        // Arrange
        let validRawKey = "sk-ant-oat01-key-that-fails-validation"
        let validationError = DomainError.invalidSessionKeyFormat
        let mockRepository = MockSessionKeyRepository()
        await mockRepository.configure(validateTokenError: validationError)
        let useCase = ValidateSessionKeyUseCase(sessionKeyRepository: mockRepository)

        // Act & Assert
        do {
            try await useCase.execute(rawKey: validRawKey)
            Issue.record("Expected validation error to be thrown")
        } catch let error as DomainError {
            #expect(error == .invalidSessionKeyFormat)
            #expect(await mockRepository.validateTokenCallCount == 1)
            #expect(await mockRepository.saveCallCount == 0)
        } catch {
            Issue.record("Expected DomainError but got \(type(of: error))")
        }
    }

    // MARK: - Save Error Tests

    @Test("save викидає помилку то вона пробрасується")
    func saveThrowsErrorThenErrorPropagated() async throws {
        // Arrange
        let validRawKey = "sk-ant-oat01-key-that-fails-to-save"
        let saveError = DomainError.sessionKeyNotFound
        let mockRepository = MockSessionKeyRepository()
        await mockRepository.configure(validateTokenError: nil, saveError: saveError)
        let useCase = ValidateSessionKeyUseCase(sessionKeyRepository: mockRepository)

        // Act & Assert
        do {
            try await useCase.execute(rawKey: validRawKey)
            Issue.record("Expected save error to be thrown")
        } catch let error as DomainError {
            #expect(error == .sessionKeyNotFound)
            #expect(await mockRepository.validateTokenCallCount == 1)
            #expect(await mockRepository.saveCallCount == 1)
        } catch {
            Issue.record("Expected DomainError but got \(type(of: error))")
        }
    }

    // MARK: - Integration Tests

    @Test("повний успішний потік: створення -> валідація -> збереження")
    func fullSuccessFlow() async throws {
        // Arrange
        let validRawKey = "sk-ant-oat01-complete-flow-test-key"
        let mockRepository = MockSessionKeyRepository()
        await mockRepository.configure()
        let useCase = ValidateSessionKeyUseCase(sessionKeyRepository: mockRepository)

        // Act
        try await useCase.execute(rawKey: validRawKey)

        // Assert - verify complete flow
        #expect(await mockRepository.validateTokenCallCount == 1)
        #expect(await mockRepository.saveCallCount == 1)

        let savedKey = await mockRepository.savedKey
        #expect(savedKey != nil)
        #expect(savedKey?.value == validRawKey)
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
