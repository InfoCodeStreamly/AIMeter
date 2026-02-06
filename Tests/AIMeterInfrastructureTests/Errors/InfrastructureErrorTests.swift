import Testing
@testable import AIMeterInfrastructure
import Foundation

@Suite("InfrastructureError")
struct InfrastructureErrorTests {

    // MARK: - errorDescription Tests

    @Test("networkUnavailable has correct error description")
    func networkUnavailableDescription() {
        // Arrange
        let error = InfrastructureError.networkUnavailable

        // Assert
        #expect(error.errorDescription == "Network is unavailable")
    }

    @Test("invalidURL includes URL in error description")
    func invalidURLDescription() {
        // Arrange
        let testURL = "https://invalid-url.com/api"
        let error = InfrastructureError.invalidURL(testURL)

        // Assert
        #expect(error.errorDescription == "Invalid URL: \(testURL)")
    }

    @Test("requestFailed includes status code in error description")
    func requestFailedDescription() {
        // Arrange
        let statusCode = 404
        let error = InfrastructureError.requestFailed(statusCode: statusCode)

        // Assert
        #expect(error.errorDescription == "Request failed with status: \(statusCode)")
    }

    @Test("decodingFailed includes underlying error description")
    func decodingFailedDescription() {
        // Arrange
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 100,
            userInfo: [NSLocalizedDescriptionKey: "Test decoding error"]
        )
        let error = InfrastructureError.decodingFailed(underlyingError)

        // Assert
        #expect(error.errorDescription?.contains("Failed to decode") == true)
        #expect(error.errorDescription?.contains("Test decoding error") == true)
    }

    @Test("unauthorized has correct error description")
    func unauthorizedDescription() {
        // Arrange
        let error = InfrastructureError.unauthorized

        // Assert
        #expect(error.errorDescription == "OAuth token is invalid or expired")
    }

    @Test("keychainSaveFailed includes status code")
    func keychainSaveFailedDescription() {
        // Arrange
        let status: OSStatus = -25299 // errSecDuplicateItem
        let error = InfrastructureError.keychainSaveFailed(status)

        // Assert
        #expect(error.errorDescription == "Failed to save to Keychain: \(status)")
    }

    @Test("keychainReadFailed includes status code")
    func keychainReadFailedDescription() {
        // Arrange
        let status: OSStatus = -25308 // errSecInteractionNotAllowed
        let error = InfrastructureError.keychainReadFailed(status)

        // Assert
        #expect(error.errorDescription == "Failed to read from Keychain: \(status)")
    }

    @Test("keychainDeleteFailed includes status code")
    func keychainDeleteFailedDescription() {
        // Arrange
        let status: OSStatus = -25300 // errSecItemNotFound
        let error = InfrastructureError.keychainDeleteFailed(status)

        // Assert
        #expect(error.errorDescription == "Failed to delete from Keychain: \(status)")
    }

    @Test("keychainItemNotFound has correct error description")
    func keychainItemNotFoundDescription() {
        // Arrange
        let error = InfrastructureError.keychainItemNotFound

        // Assert
        #expect(error.errorDescription == "Item not found in Keychain")
    }

    // MARK: - recoverySuggestion Tests

    @Test("networkUnavailable has recovery suggestion")
    func networkUnavailableRecoverySuggestion() {
        // Arrange
        let error = InfrastructureError.networkUnavailable

        // Assert
        #expect(error.recoverySuggestion == "Check your internet connection")
    }

    @Test("unauthorized has recovery suggestion")
    func unauthorizedRecoverySuggestion() {
        // Arrange
        let error = InfrastructureError.unauthorized

        // Assert
        #expect(error.recoverySuggestion == "Please re-sync from Claude Code in Settings")
    }

    @Test("requestFailed with 429 has rate limit recovery suggestion")
    func requestFailed429RecoverySuggestion() {
        // Arrange
        let error = InfrastructureError.requestFailed(statusCode: 429)

        // Assert
        #expect(error.recoverySuggestion == "Rate limited. Please wait")
    }

    @Test("requestFailed with 404 has no recovery suggestion")
    func requestFailed404NoRecoverySuggestion() {
        // Arrange
        let error = InfrastructureError.requestFailed(statusCode: 404)

        // Assert
        #expect(error.recoverySuggestion == nil)
    }

    @Test("requestFailed with 500 has no recovery suggestion")
    func requestFailed500NoRecoverySuggestion() {
        // Arrange
        let error = InfrastructureError.requestFailed(statusCode: 500)

        // Assert
        #expect(error.recoverySuggestion == nil)
    }

    @Test("invalidURL has no recovery suggestion")
    func invalidURLNoRecoverySuggestion() {
        // Arrange
        let error = InfrastructureError.invalidURL("test")

        // Assert
        #expect(error.recoverySuggestion == nil)
    }

    @Test("decodingFailed has no recovery suggestion")
    func decodingFailedNoRecoverySuggestion() {
        // Arrange
        let error = InfrastructureError.decodingFailed(NSError(domain: "Test", code: 1))

        // Assert
        #expect(error.recoverySuggestion == nil)
    }

    @Test("keychainSaveFailed has no recovery suggestion")
    func keychainSaveFailedNoRecoverySuggestion() {
        // Arrange
        let error = InfrastructureError.keychainSaveFailed(-25299)

        // Assert
        #expect(error.recoverySuggestion == nil)
    }

    @Test("keychainReadFailed has no recovery suggestion")
    func keychainReadFailedNoRecoverySuggestion() {
        // Arrange
        let error = InfrastructureError.keychainReadFailed(-25308)

        // Assert
        #expect(error.recoverySuggestion == nil)
    }

    @Test("keychainDeleteFailed has no recovery suggestion")
    func keychainDeleteFailedNoRecoverySuggestion() {
        // Arrange
        let error = InfrastructureError.keychainDeleteFailed(-25300)

        // Assert
        #expect(error.recoverySuggestion == nil)
    }

    @Test("keychainItemNotFound has no recovery suggestion")
    func keychainItemNotFoundNoRecoverySuggestion() {
        // Arrange
        let error = InfrastructureError.keychainItemNotFound

        // Assert
        #expect(error.recoverySuggestion == nil)
    }

    // MARK: - LocalizedError Protocol Tests

    @Test("error conforms to LocalizedError protocol")
    func conformsToLocalizedError() {
        // Arrange
        let error: LocalizedError = InfrastructureError.networkUnavailable

        // Assert
        #expect(error.errorDescription != nil)
    }

    @Test("error is Sendable")
    func isSendable() {
        // This test verifies compilation only
        // If InfrastructureError is not Sendable, this will fail to compile
        let error: any Sendable = InfrastructureError.networkUnavailable
        #expect(error is InfrastructureError)
    }

    // MARK: - Edge Cases Tests

    @Test("requestFailed with zero status code")
    func requestFailedZeroStatusCode() {
        // Arrange
        let error = InfrastructureError.requestFailed(statusCode: 0)

        // Assert
        #expect(error.errorDescription == "Request failed with status: 0")
    }

    @Test("requestFailed with negative status code")
    func requestFailedNegativeStatusCode() {
        // Arrange
        let error = InfrastructureError.requestFailed(statusCode: -1)

        // Assert
        #expect(error.errorDescription == "Request failed with status: -1")
    }

    @Test("invalidURL with empty string")
    func invalidURLEmptyString() {
        // Arrange
        let error = InfrastructureError.invalidURL("")

        // Assert
        #expect(error.errorDescription == "Invalid URL: ")
    }

    @Test("keychainSaveFailed with zero status")
    func keychainSaveFailedZeroStatus() {
        // Arrange
        let error = InfrastructureError.keychainSaveFailed(0)

        // Assert
        #expect(error.errorDescription == "Failed to save to Keychain: 0")
    }
}
