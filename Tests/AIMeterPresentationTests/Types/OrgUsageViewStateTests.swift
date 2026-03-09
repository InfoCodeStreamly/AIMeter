import Testing
@testable import AIMeterPresentation
import Foundation

/// Tests for OrgUsageViewState computed properties.
@Suite("OrgUsageViewState")
struct OrgUsageViewStateTests {

    // MARK: - isLoading Tests

    @Test("isLoading returns true for loading state")
    func isLoadingTrueForLoadingState() {
        let state = OrgUsageViewState.loading
        #expect(state.isLoading == true)
    }

    @Test("isLoading returns false for loaded state")
    func isLoadingFalseForLoadedState() {
        let state = OrgUsageViewState.loaded
        #expect(state.isLoading == false)
    }

    @Test("isLoading returns false for noKey state")
    func isLoadingFalseForNoKeyState() {
        let state = OrgUsageViewState.noKey
        #expect(state.isLoading == false)
    }

    @Test("isLoading returns false for error state")
    func isLoadingFalseForErrorState() {
        let state = OrgUsageViewState.error("Something went wrong")
        #expect(state.isLoading == false)
    }

    // MARK: - hasData Tests

    @Test("hasData returns true for loaded state")
    func hasDataTrueForLoadedState() {
        let state = OrgUsageViewState.loaded
        #expect(state.hasData == true)
    }

    @Test("hasData returns false for loading state")
    func hasDataFalseForLoadingState() {
        let state = OrgUsageViewState.loading
        #expect(state.hasData == false)
    }

    @Test("hasData returns false for noKey state")
    func hasDataFalseForNoKeyState() {
        let state = OrgUsageViewState.noKey
        #expect(state.hasData == false)
    }

    @Test("hasData returns false for error state")
    func hasDataFalseForErrorState() {
        let state = OrgUsageViewState.error("Network timeout")
        #expect(state.hasData == false)
    }

    // MARK: - errorMessage Tests

    @Test("errorMessage returns message string for error state")
    func errorMessageReturnsMessageForErrorState() {
        let message = "Authentication failed"
        let state = OrgUsageViewState.error(message)
        #expect(state.errorMessage == message)
    }

    @Test("errorMessage returns nil for loading state")
    func errorMessageNilForLoadingState() {
        let state = OrgUsageViewState.loading
        #expect(state.errorMessage == nil)
    }

    @Test("errorMessage returns nil for loaded state")
    func errorMessageNilForLoadedState() {
        let state = OrgUsageViewState.loaded
        #expect(state.errorMessage == nil)
    }

    @Test("errorMessage returns nil for noKey state")
    func errorMessageNilForNoKeyState() {
        let state = OrgUsageViewState.noKey
        #expect(state.errorMessage == nil)
    }

    @Test("errorMessage preserves full error message string")
    func errorMessagePreservesFullString() {
        let longMessage = "API error 429: Too many requests. Please wait 60 seconds."
        let state = OrgUsageViewState.error(longMessage)
        #expect(state.errorMessage == longMessage)
    }

    @Test("errorMessage returns empty string when error message is empty")
    func errorMessageReturnsEmptyStringWhenEmpty() {
        let state = OrgUsageViewState.error("")
        #expect(state.errorMessage == "")
    }

    // MARK: - isNoKey Tests

    @Test("isNoKey returns true for noKey state")
    func isNoKeyTrueForNoKeyState() {
        let state = OrgUsageViewState.noKey
        #expect(state.isNoKey == true)
    }

    @Test("isNoKey returns false for loading state")
    func isNoKeyFalseForLoadingState() {
        let state = OrgUsageViewState.loading
        #expect(state.isNoKey == false)
    }

    @Test("isNoKey returns false for loaded state")
    func isNoKeyFalseForLoadedState() {
        let state = OrgUsageViewState.loaded
        #expect(state.isNoKey == false)
    }

    @Test("isNoKey returns false for error state")
    func isNoKeyFalseForErrorState() {
        let state = OrgUsageViewState.error("error")
        #expect(state.isNoKey == false)
    }

    // MARK: - Equatable Tests

    @Test("loading equals loading")
    func loadingEqualsLoading() {
        #expect(OrgUsageViewState.loading == OrgUsageViewState.loading)
    }

    @Test("loaded equals loaded")
    func loadedEqualsLoaded() {
        #expect(OrgUsageViewState.loaded == OrgUsageViewState.loaded)
    }

    @Test("noKey equals noKey")
    func noKeyEqualsNoKey() {
        #expect(OrgUsageViewState.noKey == OrgUsageViewState.noKey)
    }

    @Test("error with same message equals error with same message")
    func errorEqualsSameMessage() {
        let state1 = OrgUsageViewState.error("Connection failed")
        let state2 = OrgUsageViewState.error("Connection failed")
        #expect(state1 == state2)
    }

    @Test("error with different messages are not equal")
    func errorNotEqualsDifferentMessages() {
        let state1 = OrgUsageViewState.error("Error A")
        let state2 = OrgUsageViewState.error("Error B")
        #expect(state1 != state2)
    }

    @Test("different state types are not equal")
    func differentStateTypesNotEqual() {
        let loading = OrgUsageViewState.loading
        let loaded = OrgUsageViewState.loaded
        let noKey = OrgUsageViewState.noKey
        let error = OrgUsageViewState.error("err")

        #expect(loading != loaded)
        #expect(loading != noKey)
        #expect(loading != error)
        #expect(loaded != noKey)
        #expect(loaded != error)
        #expect(noKey != error)
    }

    // MARK: - State Transition Logic Tests

    @Test("all states have mutually exclusive primary properties")
    func allStatesHaveMutuallyExclusivePrimaryProperties() {
        let states: [OrgUsageViewState] = [
            .noKey,
            .loading,
            .loaded,
            .error("test")
        ]

        // Only one state should be "loading" at a time
        let loadingCount = states.filter { $0.isLoading }.count
        #expect(loadingCount == 1)

        // Only one state should "hasData"
        let hasDataCount = states.filter { $0.hasData }.count
        #expect(hasDataCount == 1)

        // Only one state should be "noKey"
        let noKeyCount = states.filter { $0.isNoKey }.count
        #expect(noKeyCount == 1)

        // Only one state should have errorMessage
        let errorCount = states.filter { $0.errorMessage != nil }.count
        #expect(errorCount == 1)
    }
}
