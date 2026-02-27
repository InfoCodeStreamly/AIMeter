import Foundation
import Testing
@testable import AIMeterPresentation
@testable import AIMeterApplication
import AIMeterDomain

@Suite("VoiceInputViewModel", .serialized)
@MainActor
struct VoiceInputViewModelTests {

    // MARK: - Mocks

    private actor MockTranscriptionRepository: TranscriptionRepository {
        var startStreamingCallCount = 0
        var stopStreamingCallCount = 0
        var cancelStreamingCallCount = 0
        var lastLanguage: TranscriptionLanguage?
        var lastApiKey: String?
        var startStreamingError: (any Error)?
        var stopStreamingResult: TranscriptionEntity?
        var stopStreamingError: (any Error)?
        var keepStreamOpen = false
        private var streamContinuation: AsyncStream<String>.Continuation?

        func configure(
            startStreamingError: (any Error)? = nil,
            stopStreamingResult: TranscriptionEntity? = nil,
            stopStreamingError: (any Error)? = nil,
            keepStreamOpen: Bool = false
        ) {
            self.startStreamingError = startStreamingError
            self.stopStreamingResult = stopStreamingResult
            self.stopStreamingError = stopStreamingError
            self.keepStreamOpen = keepStreamOpen
        }

        func finishStream() {
            streamContinuation?.finish()
            streamContinuation = nil
        }

        func startStreaming(language: TranscriptionLanguage, apiKey: String) async throws -> AsyncStream<String> {
            startStreamingCallCount += 1
            lastLanguage = language
            lastApiKey = apiKey
            if let error = startStreamingError { throw error }

            if keepStreamOpen {
                let (stream, continuation) = AsyncStream.makeStream(of: String.self)
                streamContinuation = continuation
                return stream
            }
            return AsyncStream { $0.finish() }
        }

        func stopStreaming() async throws -> TranscriptionEntity {
            stopStreamingCallCount += 1
            if let error = stopStreamingError { throw error }
            return stopStreamingResult ?? .empty()
        }

        func cancelStreaming() async {
            cancelStreamingCallCount += 1
        }
    }

    private actor MockDeepgramAPIRepository: DeepgramAPIRepository {
        var fetchBalanceCallCount = 0
        var fetchBalanceResult: DeepgramBalance?
        var fetchBalanceError: (any Error)?

        func configure(result: DeepgramBalance? = nil, error: (any Error)? = nil) {
            self.fetchBalanceResult = result
            self.fetchBalanceError = error
        }

        func fetchBalance(apiKey: String) async throws -> DeepgramBalance {
            fetchBalanceCallCount += 1
            if let error = fetchBalanceError { throw error }
            return fetchBalanceResult ?? DeepgramBalance(amount: 0, units: "usd")
        }

        func fetchUsage(apiKey: String, start: Date, end: Date) async throws -> (totalSeconds: Double, requestCount: Int) {
            (totalSeconds: 0, requestCount: 0)
        }
    }

    @MainActor
    private final class MockTextInsertionService: TextInsertionServiceProtocol, @unchecked Sendable {
        var insertTextCallCount = 0
        var lastInsertedText: String?
        var insertTextError: (any Error)?
        var accessibilityPermission = true

        func hasAccessibilityPermission() -> Bool { accessibilityPermission }
        func insertText(_ text: String) throws {
            insertTextCallCount += 1
            lastInsertedText = text
            if let error = insertTextError { throw error }
        }
    }

    @MainActor
    private final class MockVoiceInputPreferences: VoiceInputPreferencesProtocol, @unchecked Sendable {
        var isEnabled: Bool = false
        var selectedLanguage: TranscriptionLanguage = .autoDetect
    }

    @MainActor
    private final class MockAccessibilityService: AccessibilityServiceProtocol, @unchecked Sendable {
        var isGranted: Bool = true
        var requestCallCount: Int = 0

        func isAccessibilityGranted() -> Bool { isGranted }
        func requestAccessibilityPermission() { requestCallCount += 1 }
    }

    private actor MockKeychainService: KeychainServiceProtocol {
        var storage: [String: String] = [:]
        var saveCallCount = 0
        var deleteCallCount = 0

        func configure(storage: [String: String]) {
            self.storage = storage
        }

        func save(_ value: String, forKey key: String) async throws {
            saveCallCount += 1
            storage[key] = value
        }

        func read(forKey key: String) async -> String? {
            storage[key]
        }

        func delete(forKey key: String) async throws {
            deleteCallCount += 1
            storage.removeValue(forKey: key)
        }

        func exists(forKey key: String) async -> Bool {
            storage[key] != nil
        }
    }

    // MARK: - Helper

    private func makeViewModel(
        mockRepo: MockTranscriptionRepository = MockTranscriptionRepository(),
        mockAPI: MockDeepgramAPIRepository = MockDeepgramAPIRepository(),
        mockTextInsertion: MockTextInsertionService = MockTextInsertionService(),
        mockPreferences: MockVoiceInputPreferences = MockVoiceInputPreferences(),
        mockKeychain: MockKeychainService = MockKeychainService(),
        mockAccessibility: MockAccessibilityService = MockAccessibilityService()
    ) -> VoiceInputViewModel {
        VoiceInputViewModel(
            startTranscriptionUseCase: StartTranscriptionUseCase(transcriptionRepository: mockRepo),
            stopTranscriptionUseCase: StopTranscriptionUseCase(transcriptionRepository: mockRepo),
            cancelTranscriptionUseCase: CancelTranscriptionUseCase(transcriptionRepository: mockRepo),
            insertTextUseCase: InsertTextUseCase(textInsertionService: mockTextInsertion),
            fetchBalanceUseCase: FetchDeepgramBalanceUseCase(deepgramAPIRepository: mockAPI),
            preferencesService: mockPreferences,
            keychainService: mockKeychain,
            accessibilityService: mockAccessibility
        )
    }

    // MARK: - State Management

    @Test("initial status is idle")
    func initialStatusIsIdle() {
        let vm = makeViewModel()
        #expect(vm.status == .idle)
    }

    @Test("onAppear sets ready when enabled and has API key")
    func onAppearSetsReady() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let vm = makeViewModel(mockPreferences: prefs, mockKeychain: keychain)

        await vm.onAppear()
        #expect(vm.status == .ready)
    }

    @Test("onAppear stays idle when disabled")
    func onAppearStaysIdleWhenDisabled() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = false
        let vm = makeViewModel(mockPreferences: prefs, mockKeychain: keychain)

        await vm.onAppear()
        #expect(vm.status == .idle)
    }

    @Test("onAppear stays idle when no API key")
    func onAppearStaysIdleWhenNoKey() async {
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let vm = makeViewModel(mockPreferences: prefs)

        await vm.onAppear()
        #expect(vm.status == .idle)
    }

    @Test("enable sets ready when API key exists")
    func enableSetsReady() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let vm = makeViewModel(mockKeychain: keychain)

        await vm.enable()
        #expect(vm.status == .ready)
    }

    @Test("disable sets idle")
    func disableSetsIdle() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let vm = makeViewModel(mockPreferences: prefs, mockKeychain: keychain)

        await vm.onAppear()
        #expect(vm.status == .ready)

        await vm.disable()
        #expect(vm.status == .idle)
    }

    // MARK: - toggleRecording

    @Test("toggleRecording from idle beeps (no state change)")
    func toggleFromIdleBeeps() {
        let vm = makeViewModel()
        vm.toggleRecording()
        #expect(vm.status == .idle)
    }

    // MARK: - API Key Management

    @Test("saveApiKey saves to keychain")
    func saveApiKeySavesToKeychain() async {
        let keychain = MockKeychainService()
        let vm = makeViewModel(mockKeychain: keychain)

        await vm.saveApiKey("new-key")
        #expect(await keychain.saveCallCount == 1)
        #expect(await keychain.read(forKey: "deepgramApiKey") == "new-key")
    }

    @Test("saveApiKey sets ready when enabled")
    func saveApiKeySetsReady() async {
        let keychain = MockKeychainService()
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let vm = makeViewModel(mockPreferences: prefs, mockKeychain: keychain)

        await vm.saveApiKey("new-key")
        #expect(vm.status == .ready)
    }

    @Test("deleteApiKey removes from keychain and sets idle")
    func deleteApiKeyRemovesAndSetsIdle() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "existing-key"])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let vm = makeViewModel(mockPreferences: prefs, mockKeychain: keychain)

        await vm.onAppear()
        #expect(vm.status == .ready)

        await vm.deleteApiKey()
        #expect(vm.status == .idle)
        #expect(await keychain.deleteCallCount == 1)
        #expect(await keychain.read(forKey: "deepgramApiKey") == nil)
    }

    @Test("deleteApiKey clears balance")
    func deleteApiKeyClearsBalance() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "key"])
        let api = MockDeepgramAPIRepository()
        await api.configure(result: DeepgramBalance(amount: 100, units: "usd"))
        let vm = makeViewModel(mockAPI: api, mockKeychain: keychain)

        await vm.fetchBalance()
        #expect(vm.balance != nil)

        await vm.deleteApiKey()
        #expect(vm.balance == nil)
    }

    @Test("loadApiKey returns key from keychain")
    func loadApiKeyReturnsKey() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "my-key"])
        let vm = makeViewModel(mockKeychain: keychain)

        let key = await vm.loadApiKey()
        #expect(key == "my-key")
    }

    @Test("loadApiKey returns empty string when no key")
    func loadApiKeyReturnsEmptyWhenNoKey() async {
        let vm = makeViewModel()
        let key = await vm.loadApiKey()
        #expect(key == "")
    }

    @Test("hasApiKey returns true when key exists")
    func hasApiKeyReturnsTrue() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "key"])
        let vm = makeViewModel(mockKeychain: keychain)

        let has = await vm.hasApiKey()
        #expect(has == true)
    }

    @Test("hasApiKey returns false when no key")
    func hasApiKeyReturnsFalse() async {
        let vm = makeViewModel()
        let has = await vm.hasApiKey()
        #expect(has == false)
    }

    // MARK: - Balance

    @Test("fetchBalance sets balance from repository")
    func fetchBalanceSetsBalance() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "key"])
        let api = MockDeepgramAPIRepository()
        let expectedBalance = DeepgramBalance(amount: 187.50, units: "usd")
        await api.configure(result: expectedBalance)
        let vm = makeViewModel(mockAPI: api, mockKeychain: keychain)

        await vm.fetchBalance()
        #expect(vm.balance == expectedBalance)
        #expect(vm.balanceError == nil)
    }

    @Test("fetchBalance sets error on failure")
    func fetchBalanceSetsError() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "key"])
        let api = MockDeepgramAPIRepository()
        await api.configure(error: TranscriptionError.authenticationFailed)
        let vm = makeViewModel(mockAPI: api, mockKeychain: keychain)

        await vm.fetchBalance()
        #expect(vm.balance == nil)
        #expect(vm.balanceError == "Invalid API key")
    }

    @Test("fetchBalance does nothing without API key")
    func fetchBalanceNoKey() async {
        let vm = makeViewModel()
        await vm.fetchBalance()
        #expect(vm.balance == nil)
        #expect(vm.balanceError == nil)
    }

    @Test("fetchBalance sets isLoadingBalance during fetch")
    func fetchBalanceLoading() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "key"])
        let vm = makeViewModel(mockKeychain: keychain)

        // After fetch completes, isLoadingBalance should be false
        await vm.fetchBalance()
        #expect(vm.isLoadingBalance == false)
    }

    // MARK: - Push-to-Talk (startRecordingIfReady / stopIfRecording)

    @Test("startRecordingIfReady from ready transitions connecting → recording")
    func startRecordingIfReadyFromReady() async throws {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let vm = makeViewModel(mockRepo: repo, mockPreferences: prefs, mockKeychain: keychain)

        await vm.onAppear()
        #expect(vm.status == .ready)

        vm.startRecordingIfReady()
        #expect(vm.status == .connecting)

        // Let the Task run — stream stays open, so status settles on .recording
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)
        #expect(await repo.startStreamingCallCount == 1)

        await repo.finishStream()
    }

    @Test("startRecordingIfReady from idle when disabled stays idle")
    func startRecordingIfReadyFromIdleDisabled() async throws {
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = false
        let vm = makeViewModel(mockPreferences: prefs)

        #expect(vm.status == .idle)
        vm.startRecordingIfReady()

        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .idle)
    }

    @Test("startRecordingIfReady from idle without API key stays idle")
    func startRecordingIfReadyFromIdleNoKey() async throws {
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let vm = makeViewModel(mockPreferences: prefs)

        #expect(vm.status == .idle)
        vm.startRecordingIfReady()

        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .idle)
    }

    @Test("startRecordingIfReady from idle with prerequisites transitions to recording")
    func startRecordingIfReadyFromIdleWithPrereqs() async throws {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let vm = makeViewModel(mockRepo: repo, mockPreferences: prefs, mockKeychain: keychain)

        #expect(vm.status == .idle)
        vm.startRecordingIfReady()

        // Internal Task: checks enabled → checks API key → .ready → startRecording() → .connecting → .recording
        try await Task.sleep(for: .milliseconds(100))
        #expect(vm.status == .recording)
        #expect(await repo.startStreamingCallCount == 1)

        await repo.finishStream()
    }

    @Test("stopIfRecording from recording calls stopStreaming")
    func stopIfRecordingFromRecording() async throws {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let vm = makeViewModel(mockRepo: repo, mockPreferences: prefs, mockKeychain: keychain)

        await vm.onAppear()
        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)

        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(100))
        #expect(await repo.stopStreamingCallCount == 1)
    }

    @Test("stopIfRecording from connecting cancels without transitioning to recording")
    func stopIfRecordingFromConnecting() async throws {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let vm = makeViewModel(mockRepo: repo, mockPreferences: prefs, mockKeychain: keychain)

        await vm.onAppear()
        vm.startRecordingIfReady()
        #expect(vm.status == .connecting)

        // Immediately stop while still connecting (Task hasn't run yet)
        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .ready)
        #expect(await repo.cancelStreamingCallCount == 1)
        // Cancelled task should NOT have transitioned to .recording
        #expect(await repo.stopStreamingCallCount == 0)
    }

    @Test("stopIfRecording from idle is no-op")
    func stopIfRecordingFromIdle() {
        let vm = makeViewModel()
        #expect(vm.status == .idle)
        vm.stopIfRecording()
        #expect(vm.status == .idle)
    }

    @Test("stopIfRecording from ready is no-op")
    func stopIfRecordingFromReady() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let vm = makeViewModel(mockPreferences: prefs, mockKeychain: keychain)

        await vm.onAppear()
        #expect(vm.status == .ready)

        vm.stopIfRecording()
        #expect(vm.status == .ready)
    }

    // MARK: - Accessibility Delegation

    @Test("checkAccessibility delegates to AccessibilityService")
    func checkAccessibilityDelegates() {
        let mockAccessibility = MockAccessibilityService()
        mockAccessibility.isGranted = false
        let vm = makeViewModel(mockAccessibility: mockAccessibility)

        #expect(vm.checkAccessibility() == false)

        mockAccessibility.isGranted = true
        #expect(vm.checkAccessibility() == true)
    }

    @Test("requestAccessibility delegates to AccessibilityService")
    func requestAccessibilityDelegates() {
        let mockAccessibility = MockAccessibilityService()
        let vm = makeViewModel(mockAccessibility: mockAccessibility)

        vm.requestAccessibility()
        #expect(mockAccessibility.requestCallCount == 1)

        vm.requestAccessibility()
        #expect(mockAccessibility.requestCallCount == 2)
    }
}
