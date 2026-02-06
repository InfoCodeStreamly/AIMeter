import Testing
import Foundation
@testable import AIMeterApplication

@Suite("TokenRefreshError Tests")
struct TokenRefreshErrorTests {

    // MARK: - Error Description Tests

    @Test("errorDescription returns correct message for noCredentials")
    func testErrorDescriptionNoCredentials() {
        // Arrange
        let error = TokenRefreshError.noCredentials

        // Act
        let description = error.errorDescription

        // Assert
        #expect(description == "No OAuth credentials found. Please sync from Claude Code.")
    }

    @Test("errorDescription returns correct message for refreshTokenExpired")
    func testErrorDescriptionRefreshTokenExpired() {
        // Arrange
        let error = TokenRefreshError.refreshTokenExpired

        // Act
        let description = error.errorDescription

        // Assert
        #expect(description == "Session expired. Please re-login to Claude Code.")
    }

    @Test("errorDescription returns correct message for refreshFailed")
    func testErrorDescriptionRefreshFailed() {
        // Arrange
        let error = TokenRefreshError.refreshFailed(statusCode: 401)

        // Act
        let description = error.errorDescription

        // Assert
        #expect(description == "Token refresh failed (HTTP 401)")
    }

    @Test("errorDescription returns correct message for invalidResponse")
    func testErrorDescriptionInvalidResponse() {
        // Arrange
        let error = TokenRefreshError.invalidResponse

        // Act
        let description = error.errorDescription

        // Assert
        #expect(description == "Invalid response from auth server")
    }

    @Test("errorDescription returns correct message for keychainUpdateFailed")
    func testErrorDescriptionKeychainUpdateFailed() {
        // Arrange
        let error = TokenRefreshError.keychainUpdateFailed

        // Act
        let description = error.errorDescription

        // Assert
        #expect(description == "Failed to update credentials")
    }

    // MARK: - Requires Reauth Tests

    @Test("requiresReauth returns true for noCredentials")
    func testRequiresReauthNoCredentials() {
        // Arrange
        let error = TokenRefreshError.noCredentials

        // Act & Assert
        #expect(error.requiresReauth == true)
    }

    @Test("requiresReauth returns true for refreshTokenExpired")
    func testRequiresReauthRefreshTokenExpired() {
        // Arrange
        let error = TokenRefreshError.refreshTokenExpired

        // Act & Assert
        #expect(error.requiresReauth == true)
    }

    @Test("requiresReauth returns false for refreshFailed")
    func testRequiresReauthRefreshFailed() {
        // Arrange
        let error = TokenRefreshError.refreshFailed(statusCode: 500)

        // Act & Assert
        #expect(error.requiresReauth == false)
    }

    @Test("requiresReauth returns false for invalidResponse")
    func testRequiresReauthInvalidResponse() {
        // Arrange
        let error = TokenRefreshError.invalidResponse

        // Act & Assert
        #expect(error.requiresReauth == false)
    }

    @Test("requiresReauth returns false for keychainUpdateFailed")
    func testRequiresReauthKeychainUpdateFailed() {
        // Arrange
        let error = TokenRefreshError.keychainUpdateFailed

        // Act & Assert
        #expect(error.requiresReauth == false)
    }

    // MARK: - Equatable Tests

    @Test("Equatable: same noCredentials cases are equal")
    func testEquatableNoCredentials() {
        // Arrange
        let error1 = TokenRefreshError.noCredentials
        let error2 = TokenRefreshError.noCredentials

        // Act & Assert
        #expect(error1 == error2)
    }

    @Test("Equatable: same refreshTokenExpired cases are equal")
    func testEquatableRefreshTokenExpired() {
        // Arrange
        let error1 = TokenRefreshError.refreshTokenExpired
        let error2 = TokenRefreshError.refreshTokenExpired

        // Act & Assert
        #expect(error1 == error2)
    }

    @Test("Equatable: same refreshFailed with same statusCode are equal")
    func testEquatableRefreshFailedSameStatusCode() {
        // Arrange
        let error1 = TokenRefreshError.refreshFailed(statusCode: 401)
        let error2 = TokenRefreshError.refreshFailed(statusCode: 401)

        // Act & Assert
        #expect(error1 == error2)
    }

    @Test("Equatable: refreshFailed with different statusCodes are not equal")
    func testEquatableRefreshFailedDifferentStatusCodes() {
        // Arrange
        let error1 = TokenRefreshError.refreshFailed(statusCode: 401)
        let error2 = TokenRefreshError.refreshFailed(statusCode: 500)

        // Act & Assert
        #expect(error1 != error2)
    }

    @Test("Equatable: same invalidResponse cases are equal")
    func testEquatableInvalidResponse() {
        // Arrange
        let error1 = TokenRefreshError.invalidResponse
        let error2 = TokenRefreshError.invalidResponse

        // Act & Assert
        #expect(error1 == error2)
    }

    @Test("Equatable: same keychainUpdateFailed cases are equal")
    func testEquatableKeychainUpdateFailed() {
        // Arrange
        let error1 = TokenRefreshError.keychainUpdateFailed
        let error2 = TokenRefreshError.keychainUpdateFailed

        // Act & Assert
        #expect(error1 == error2)
    }

    @Test("Equatable: different cases are not equal")
    func testEquatableDifferentCases() {
        // Arrange
        let error1 = TokenRefreshError.noCredentials
        let error2 = TokenRefreshError.refreshTokenExpired
        let error3 = TokenRefreshError.refreshFailed(statusCode: 401)
        let error4 = TokenRefreshError.invalidResponse
        let error5 = TokenRefreshError.keychainUpdateFailed

        // Act & Assert
        #expect(error1 != error2)
        #expect(error1 != error3)
        #expect(error1 != error4)
        #expect(error1 != error5)
        #expect(error2 != error3)
        #expect(error2 != error4)
        #expect(error2 != error5)
        #expect(error3 != error4)
        #expect(error3 != error5)
        #expect(error4 != error5)
    }

    @Test("Equatable: noCredentials not equal to refreshFailed")
    func testEquatableNoCredentialsVsRefreshFailed() {
        // Arrange
        let error1 = TokenRefreshError.noCredentials
        let error2 = TokenRefreshError.refreshFailed(statusCode: 401)

        // Act & Assert
        #expect(error1 != error2)
    }

    // MARK: - Multiple Status Code Tests

    @Test("refreshFailed with different HTTP status codes have correct descriptions")
    func testRefreshFailedWithDifferentStatusCodes() {
        // Arrange & Act
        let error400 = TokenRefreshError.refreshFailed(statusCode: 400)
        let error401 = TokenRefreshError.refreshFailed(statusCode: 401)
        let error500 = TokenRefreshError.refreshFailed(statusCode: 500)

        // Assert
        #expect(error400.errorDescription == "Token refresh failed (HTTP 400)")
        #expect(error401.errorDescription == "Token refresh failed (HTTP 401)")
        #expect(error500.errorDescription == "Token refresh failed (HTTP 500)")
    }
}
