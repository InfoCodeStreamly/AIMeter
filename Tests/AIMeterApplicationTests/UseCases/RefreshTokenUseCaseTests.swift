import Testing
import Foundation
@testable import AIMeterApplication
@testable import AIMeterDomain

/// Tests for RefreshTokenUseCase
@Suite("RefreshTokenUseCase Tests")
struct RefreshTokenUseCaseTests {

    // MARK: - Helpers

    func makeCredentials(
        accessToken: String = "valid-access-token",
        refreshToken: String = "valid-refresh-token",
        expiresAt: Date = Date().addingTimeInterval(3600),
        scopes: [String] = ["user:read"],
        subscriptionType: String? = "pro",
        rateLimitTier: String? = nil
    ) -> OAuthCredentials {
        OAuthCredentials(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            scopes: scopes,
            subscriptionType: subscriptionType,
            rateLimitTier: rateLimitTier
        )
    }

    // MARK: - execute() Tests

    @Test("execute throws noCredentials when credentials are missing")
    func executeThrowsWhenNoCredentials() async throws {
        let mockRepository = MockOAuthCredentialsRepository()
        let mockRefreshService = MockTokenRefreshService()
        await mockRepository.configure(credentials: nil)

        let useCase = RefreshTokenUseCase(
            credentialsRepository: mockRepository,
            tokenRefreshService: mockRefreshService
        )

        await #expect(throws: TokenRefreshError.noCredentials) {
            try await useCase.execute()
        }
    }

    @Test("execute returns existing credentials when refresh not needed")
    func executeReturnsExistingWhenNoRefreshNeeded() async throws {
        let mockRepository = MockOAuthCredentialsRepository()
        let mockRefreshService = MockTokenRefreshService()

        let credentials = makeCredentials(expiresAt: Date().addingTimeInterval(3600))
        await mockRepository.configure(credentials: credentials)

        let useCase = RefreshTokenUseCase(
            credentialsRepository: mockRepository,
            tokenRefreshService: mockRefreshService
        )

        let result = try await useCase.execute()

        #expect(result.accessToken == "valid-access-token")
        #expect(result.refreshToken == "valid-refresh-token")

        let refreshCallCount = await mockRefreshService.refreshCallCount
        #expect(refreshCallCount == 0)
    }

    @Test("execute calls refresh service when credentials need refresh")
    func executeCallsRefreshWhenNeeded() async throws {
        let mockRepository = MockOAuthCredentialsRepository()
        let mockRefreshService = MockTokenRefreshService()

        let oldCredentials = makeCredentials(
            accessToken: "old-access-token",
            refreshToken: "old-refresh-token",
            expiresAt: Date().addingTimeInterval(60)
        )
        await mockRepository.configure(credentials: oldCredentials)

        let refreshResponse = TokenRefreshResponse(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            expiresIn: 3600
        )
        await mockRefreshService.configure(response: refreshResponse)

        let useCase = RefreshTokenUseCase(
            credentialsRepository: mockRepository,
            tokenRefreshService: mockRefreshService
        )

        let result = try await useCase.execute()

        #expect(result.accessToken == "new-access-token")
        #expect(result.refreshToken == "new-refresh-token")

        let refreshCallCount = await mockRefreshService.refreshCallCount
        #expect(refreshCallCount == 1)

        let refreshTokenUsed = await mockRefreshService.lastRefreshToken
        #expect(refreshTokenUsed == "old-refresh-token")

        let savedCredentials = await mockRepository.savedCredentials
        #expect(savedCredentials?.accessToken == "new-access-token")
    }

    @Test("execute propagates error when refresh service fails")
    func executePropagatesRefreshServiceError() async throws {
        let mockRepository = MockOAuthCredentialsRepository()
        let mockRefreshService = MockTokenRefreshService()

        let credentials = makeCredentials(expiresAt: Date().addingTimeInterval(60))
        await mockRepository.configure(credentials: credentials)
        await mockRefreshService.configure(error: TokenRefreshError.refreshFailed(statusCode: 500))

        let useCase = RefreshTokenUseCase(
            credentialsRepository: mockRepository,
            tokenRefreshService: mockRefreshService
        )

        await #expect(throws: TokenRefreshError.refreshFailed(statusCode: 500)) {
            try await useCase.execute()
        }
    }

    @Test("execute propagates error when save fails")
    func executePropagatesSaveError() async throws {
        let mockRepository = MockOAuthCredentialsRepository()
        let mockRefreshService = MockTokenRefreshService()

        let credentials = makeCredentials(expiresAt: Date().addingTimeInterval(60))
        await mockRepository.configure(credentials: credentials)
        await mockRepository.configure(saveError: TokenRefreshError.keychainUpdateFailed)

        let refreshResponse = TokenRefreshResponse(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            expiresIn: 3600
        )
        await mockRefreshService.configure(response: refreshResponse)

        let useCase = RefreshTokenUseCase(
            credentialsRepository: mockRepository,
            tokenRefreshService: mockRefreshService
        )

        await #expect(throws: TokenRefreshError.keychainUpdateFailed) {
            try await useCase.execute()
        }
    }

    @Test("execute swallows error when updateClaudeCodeKeychain fails")
    func executeSwallowsKeychainUpdateError() async throws {
        let mockRepository = MockOAuthCredentialsRepository()
        let mockRefreshService = MockTokenRefreshService()

        let credentials = makeCredentials(expiresAt: Date().addingTimeInterval(60))
        await mockRepository.configure(credentials: credentials)
        await mockRepository.configure(updateKeychainError: TokenRefreshError.keychainUpdateFailed)

        let refreshResponse = TokenRefreshResponse(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            expiresIn: 3600
        )
        await mockRefreshService.configure(response: refreshResponse)

        let useCase = RefreshTokenUseCase(
            credentialsRepository: mockRepository,
            tokenRefreshService: mockRefreshService
        )

        let result = try await useCase.execute()

        #expect(result.accessToken == "new-access-token")
        #expect(result.refreshToken == "new-refresh-token")

        let updateKeychainCallCount = await mockRepository.updateKeychainCallCount
        #expect(updateKeychainCallCount == 1)
    }

    // MARK: - hasValidCredentials() Tests

    @Test("hasValidCredentials returns true when credentials exist with non-empty refresh token")
    func hasValidCredentialsReturnsTrueWhenValid() async {
        let mockRepository = MockOAuthCredentialsRepository()
        let mockRefreshService = MockTokenRefreshService()

        let credentials = makeCredentials()
        await mockRepository.configure(credentials: credentials)

        let useCase = RefreshTokenUseCase(
            credentialsRepository: mockRepository,
            tokenRefreshService: mockRefreshService
        )

        let result = await useCase.hasValidCredentials()
        #expect(result == true)
    }

    @Test("hasValidCredentials returns false when credentials are missing")
    func hasValidCredentialsReturnsFalseWhenMissing() async {
        let mockRepository = MockOAuthCredentialsRepository()
        let mockRefreshService = MockTokenRefreshService()
        await mockRepository.configure(credentials: nil)

        let useCase = RefreshTokenUseCase(
            credentialsRepository: mockRepository,
            tokenRefreshService: mockRefreshService
        )

        let result = await useCase.hasValidCredentials()
        #expect(result == false)
    }

    @Test("hasValidCredentials returns false when refresh token is empty")
    func hasValidCredentialsReturnsFalseWhenRefreshTokenEmpty() async {
        let mockRepository = MockOAuthCredentialsRepository()
        let mockRefreshService = MockTokenRefreshService()

        let credentials = makeCredentials(refreshToken: "")
        await mockRepository.configure(credentials: credentials)

        let useCase = RefreshTokenUseCase(
            credentialsRepository: mockRepository,
            tokenRefreshService: mockRefreshService
        )

        let result = await useCase.hasValidCredentials()
        #expect(result == false)
    }
}

// MARK: - Mock Implementations

actor MockOAuthCredentialsRepository: OAuthCredentialsRepository {
    private var credentials: OAuthCredentials?
    private var saveErrorToThrow: Error?
    private var updateKeychainErrorToThrow: Error?

    private(set) var savedCredentials: OAuthCredentials?
    private(set) var updateKeychainCallCount = 0

    func configure(credentials: OAuthCredentials?) {
        self.credentials = credentials
    }

    func configure(saveError: Error?) {
        self.saveErrorToThrow = saveError
    }

    func configure(updateKeychainError: Error?) {
        self.updateKeychainErrorToThrow = updateKeychainError
    }

    func getOAuthCredentials() async -> OAuthCredentials? {
        return credentials
    }

    func saveOAuthCredentials(_ credentials: OAuthCredentials) async throws {
        if let error = saveErrorToThrow {
            throw error
        }
        self.savedCredentials = credentials
        self.credentials = credentials
    }

    func updateClaudeCodeKeychain(_ credentials: OAuthCredentials) async throws {
        updateKeychainCallCount += 1
        if let error = updateKeychainErrorToThrow {
            throw error
        }
    }
}

actor MockTokenRefreshService: TokenRefreshServiceProtocol {
    private var response: TokenRefreshResponse?
    private var errorToThrow: Error?

    private(set) var refreshCallCount = 0
    private(set) var lastRefreshToken: String?

    func configure(response: TokenRefreshResponse) {
        self.response = response
        self.errorToThrow = nil
    }

    func configure(error: Error) {
        self.errorToThrow = error
        self.response = nil
    }

    func refresh(using refreshToken: String) async throws -> TokenRefreshResponse {
        refreshCallCount += 1
        lastRefreshToken = refreshToken

        if let error = errorToThrow {
            throw error
        }

        guard let response = response else {
            throw TokenRefreshError.invalidResponse
        }

        return response
    }
}
