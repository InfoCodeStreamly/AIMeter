import Testing
@testable import AIMeterPresentation
import Foundation

/// Tests for SettingsState enum
@Suite("SettingsState Tests")
struct SettingsStateTests {

    // MARK: - Checking State

    @Test("checking state returns correct properties")
    func checkingStateReturnsCorrectProperties() {
        // Arrange
        let state = SettingsState.checking

        // Assert
        #expect(state.isLoading == true)
        #expect(state.canSync == false)
        #expect(state.isSuccess == false)
        #expect(state.isError == false)
        #expect(state.canRetry == false)
    }

    // MARK: - Claude Code Found State

    @Test("claudeCodeFound state with email returns correct properties")
    func claudeCodeFoundWithEmailReturnsCorrectProperties() {
        // Arrange
        let email = "user@example.com"
        let state = SettingsState.claudeCodeFound(email: email)

        // Assert
        #expect(state.isLoading == false)
        #expect(state.canSync == true)
        #expect(state.isSuccess == false)
        #expect(state.isError == false)
        #expect(state.canRetry == false)
    }

    @Test("claudeCodeFound state without email returns correct properties")
    func claudeCodeFoundWithoutEmailReturnsCorrectProperties() {
        // Arrange
        let state = SettingsState.claudeCodeFound(email: nil)

        // Assert
        #expect(state.isLoading == false)
        #expect(state.canSync == true)
        #expect(state.isSuccess == false)
        #expect(state.isError == false)
        #expect(state.canRetry == false)
    }

    // MARK: - Claude Code Not Found State

    @Test("claudeCodeNotFound state returns correct properties")
    func claudeCodeNotFoundReturnsCorrectProperties() {
        // Arrange
        let state = SettingsState.claudeCodeNotFound

        // Assert
        #expect(state.isLoading == false)
        #expect(state.canSync == false)
        #expect(state.isSuccess == false)
        #expect(state.isError == false)
        #expect(state.canRetry == true)
    }

    // MARK: - Has Key State

    @Test("hasKey state returns correct properties")
    func hasKeyReturnsCorrectProperties() {
        // Arrange
        let masked = "sk-ant-oat01-***"
        let state = SettingsState.hasKey(masked: masked)

        // Assert
        #expect(state.isLoading == false)
        #expect(state.canSync == false)
        #expect(state.isSuccess == false)
        #expect(state.isError == false)
        #expect(state.canRetry == false)
    }

    // MARK: - Syncing State

    @Test("syncing state returns correct properties")
    func syncingStateReturnsCorrectProperties() {
        // Arrange
        let state = SettingsState.syncing

        // Assert
        #expect(state.isLoading == true)
        #expect(state.canSync == false)
        #expect(state.isSuccess == false)
        #expect(state.isError == false)
        #expect(state.canRetry == false)
    }

    // MARK: - Success State

    @Test("success state returns correct properties")
    func successStateReturnsCorrectProperties() {
        // Arrange
        let message = "Successfully synced credentials"
        let state = SettingsState.success(message: message)

        // Assert
        #expect(state.isLoading == false)
        #expect(state.canSync == false)
        #expect(state.isSuccess == true)
        #expect(state.isError == false)
        #expect(state.canRetry == false)
    }

    // MARK: - Error State

    @Test("error state returns correct properties")
    func errorStateReturnsCorrectProperties() {
        // Arrange
        let message = "Failed to sync: Connection timeout"
        let state = SettingsState.error(message: message)

        // Assert
        #expect(state.isLoading == false)
        #expect(state.canSync == false)
        #expect(state.isSuccess == false)
        #expect(state.isError == true)
        #expect(state.canRetry == true)
    }

    // MARK: - Equatable

    @Test("equatable compares checking states correctly")
    func equatableComparesCheckingStates() {
        // Arrange
        let state1 = SettingsState.checking
        let state2 = SettingsState.checking

        // Assert
        #expect(state1 == state2)
    }

    @Test("equatable compares claudeCodeFound states with same email")
    func equatableComparesClaudeCodeFoundWithSameEmail() {
        // Arrange
        let email = "user@example.com"
        let state1 = SettingsState.claudeCodeFound(email: email)
        let state2 = SettingsState.claudeCodeFound(email: email)

        // Assert
        #expect(state1 == state2)
    }

    @Test("equatable detects different emails in claudeCodeFound")
    func equatableDetectsDifferentEmailsInClaudeCodeFound() {
        // Arrange
        let state1 = SettingsState.claudeCodeFound(email: "user1@example.com")
        let state2 = SettingsState.claudeCodeFound(email: "user2@example.com")

        // Assert
        #expect(state1 != state2)
    }

    @Test("equatable compares claudeCodeFound with nil email")
    func equatableComparesClaudeCodeFoundWithNilEmail() {
        // Arrange
        let state1 = SettingsState.claudeCodeFound(email: nil)
        let state2 = SettingsState.claudeCodeFound(email: nil)

        // Assert
        #expect(state1 == state2)
    }

    @Test("equatable detects difference between nil and non-nil email")
    func equatableDetectsDifferenceBetweenNilAndNonNilEmail() {
        // Arrange
        let state1 = SettingsState.claudeCodeFound(email: nil)
        let state2 = SettingsState.claudeCodeFound(email: "user@example.com")

        // Assert
        #expect(state1 != state2)
    }

    @Test("equatable compares claudeCodeNotFound states correctly")
    func equatableComparesClaudeCodeNotFoundStates() {
        // Arrange
        let state1 = SettingsState.claudeCodeNotFound
        let state2 = SettingsState.claudeCodeNotFound

        // Assert
        #expect(state1 == state2)
    }

    @Test("equatable compares hasKey states with same masked value")
    func equatableComparesHasKeyWithSameMaskedValue() {
        // Arrange
        let masked = "sk-ant-oat01-***"
        let state1 = SettingsState.hasKey(masked: masked)
        let state2 = SettingsState.hasKey(masked: masked)

        // Assert
        #expect(state1 == state2)
    }

    @Test("equatable detects different masked values in hasKey")
    func equatableDetectsDifferentMaskedValuesInHasKey() {
        // Arrange
        let state1 = SettingsState.hasKey(masked: "sk-ant-oat01-***AAA")
        let state2 = SettingsState.hasKey(masked: "sk-ant-oat01-***BBB")

        // Assert
        #expect(state1 != state2)
    }

    @Test("equatable compares syncing states correctly")
    func equatableComparesSyncingStates() {
        // Arrange
        let state1 = SettingsState.syncing
        let state2 = SettingsState.syncing

        // Assert
        #expect(state1 == state2)
    }

    @Test("equatable compares success states with same message")
    func equatableComparesSuccessWithSameMessage() {
        // Arrange
        let message = "Successfully synced"
        let state1 = SettingsState.success(message: message)
        let state2 = SettingsState.success(message: message)

        // Assert
        #expect(state1 == state2)
    }

    @Test("equatable detects different success messages")
    func equatableDetectsDifferentSuccessMessages() {
        // Arrange
        let state1 = SettingsState.success(message: "Synced successfully")
        let state2 = SettingsState.success(message: "All done!")

        // Assert
        #expect(state1 != state2)
    }

    @Test("equatable compares error states with same message")
    func equatableComparesErrorWithSameMessage() {
        // Arrange
        let message = "Connection failed"
        let state1 = SettingsState.error(message: message)
        let state2 = SettingsState.error(message: message)

        // Assert
        #expect(state1 == state2)
    }

    @Test("equatable detects different error messages")
    func equatableDetectsDifferentErrorMessages() {
        // Arrange
        let state1 = SettingsState.error(message: "Connection failed")
        let state2 = SettingsState.error(message: "Timeout")

        // Assert
        #expect(state1 != state2)
    }

    @Test("equatable detects different state types")
    func equatableDetectsDifferentStateTypes() {
        // Arrange
        let state1 = SettingsState.checking
        let state2 = SettingsState.syncing
        let state3 = SettingsState.claudeCodeNotFound
        let state4 = SettingsState.claudeCodeFound(email: nil)
        let state5 = SettingsState.hasKey(masked: "***")
        let state6 = SettingsState.success(message: "Done")
        let state7 = SettingsState.error(message: "Failed")

        // Assert - checking vs others
        #expect(state1 != state2)
        #expect(state1 != state3)
        #expect(state1 != state4)
        #expect(state1 != state5)
        #expect(state1 != state6)
        #expect(state1 != state7)

        // Assert - syncing vs others
        #expect(state2 != state3)
        #expect(state2 != state4)
        #expect(state2 != state5)
        #expect(state2 != state6)
        #expect(state2 != state7)
    }

    // MARK: - State Transitions

    @Test("loading states are only checking and syncing")
    func loadingStatesAreOnlyCheckingAndSyncing() {
        // Arrange
        let loadingStates: [SettingsState] = [.checking, .syncing]
        let nonLoadingStates: [SettingsState] = [
            .claudeCodeFound(email: nil),
            .claudeCodeNotFound,
            .hasKey(masked: "***"),
            .success(message: "Done"),
            .error(message: "Failed")
        ]

        // Assert
        for state in loadingStates {
            #expect(state.isLoading == true)
        }
        for state in nonLoadingStates {
            #expect(state.isLoading == false)
        }
    }

    @Test("canSync is only true for claudeCodeFound")
    func canSyncOnlyTrueForClaudeCodeFound() {
        // Arrange
        let canSyncStates: [SettingsState] = [
            .claudeCodeFound(email: "user@example.com"),
            .claudeCodeFound(email: nil)
        ]
        let cannotSyncStates: [SettingsState] = [
            .checking,
            .claudeCodeNotFound,
            .hasKey(masked: "***"),
            .syncing,
            .success(message: "Done"),
            .error(message: "Failed")
        ]

        // Assert
        for state in canSyncStates {
            #expect(state.canSync == true)
        }
        for state in cannotSyncStates {
            #expect(state.canSync == false)
        }
    }

    @Test("canRetry is true for claudeCodeNotFound and error")
    func canRetryTrueForNotFoundAndError() {
        // Arrange
        let canRetryStates: [SettingsState] = [
            .claudeCodeNotFound,
            .error(message: "Failed")
        ]
        let cannotRetryStates: [SettingsState] = [
            .checking,
            .claudeCodeFound(email: nil),
            .hasKey(masked: "***"),
            .syncing,
            .success(message: "Done")
        ]

        // Assert
        for state in canRetryStates {
            #expect(state.canRetry == true)
        }
        for state in cannotRetryStates {
            #expect(state.canRetry == false)
        }
    }

    @Test("typical workflow state transitions")
    func typicalWorkflowStateTransitions() {
        // Arrange - simulate typical workflow
        let workflow: [SettingsState] = [
            .checking,
            .claudeCodeFound(email: "user@example.com"),
            .syncing,
            .success(message: "Synced"),
            .hasKey(masked: "sk-ant-***")
        ]

        // Assert initial state
        #expect(workflow[0].isLoading == true)
        #expect(workflow[0].canSync == false)

        // Assert found state
        #expect(workflow[1].isLoading == false)
        #expect(workflow[1].canSync == true)

        // Assert syncing state
        #expect(workflow[2].isLoading == true)
        #expect(workflow[2].canSync == false)

        // Assert success state
        #expect(workflow[3].isLoading == false)
        #expect(workflow[3].isSuccess == true)

        // Assert final state
        #expect(workflow[4].isLoading == false)
        #expect(workflow[4].canSync == false)
    }

    @Test("error workflow with retry")
    func errorWorkflowWithRetry() {
        // Arrange - simulate error and retry
        let workflow: [SettingsState] = [
            .checking,
            .error(message: "Network error"),
            .checking,
            .claudeCodeFound(email: "user@example.com")
        ]

        // Assert error state
        #expect(workflow[1].isError == true)
        #expect(workflow[1].canRetry == true)

        // Assert retry (checking again)
        #expect(workflow[2].isLoading == true)
        #expect(workflow[2].canRetry == false)

        // Assert successful retry
        #expect(workflow[3].canSync == true)
        #expect(workflow[3].canRetry == false)
    }
}
