import Foundation
import Testing
@testable import AIMeterApplication
@testable import AIMeterPresentation
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

        func yieldText(_ text: String) {
            streamContinuation?.yield(text)
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

    /// Helper: create a ready ViewModel with enabled prefs + API key
    private func makeReadyViewModel(
        mockRepo: MockTranscriptionRepository = MockTranscriptionRepository(),
        mockTextInsertion: MockTextInsertionService = MockTextInsertionService()
    ) async -> (VoiceInputViewModel, MockTranscriptionRepository, MockTextInsertionService, MockKeychainService) {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let vm = makeViewModel(mockRepo: mockRepo, mockTextInsertion: mockTextInsertion, mockPreferences: prefs, mockKeychain: keychain)
        await vm.onAppear()
        return (vm, mockRepo, mockTextInsertion, keychain)
    }

    // MARK: - Initial State

    @Test("initial status is idle")
    func initialStatusIsIdle() {
        let vm = makeViewModel()
        #expect(vm.status == .idle)
    }

    @Test("initial interimText is empty")
    func initialInterimTextIsEmpty() {
        let vm = makeViewModel()
        #expect(vm.interimText == "")
    }

    // MARK: - onAppear

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

    // MARK: - Enable / Disable

    @Test("enable sets ready when API key exists")
    func enableSetsReady() async {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let vm = makeViewModel(mockKeychain: keychain)

        await vm.enable()
        #expect(vm.status == .ready)
    }

    @Test("enable stays idle when no API key")
    func enableStaysIdleNoKey() async {
        let vm = makeViewModel()
        await vm.enable()
        #expect(vm.status == .idle)
    }

    @Test("disable sets idle and cancels recording")
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

    // MARK: - startRecordingIfReady — from every status

    @Test("startRecordingIfReady from .ready transitions to connecting then recording")
    func startFromReady() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        #expect(vm.status == .ready)
        vm.startRecordingIfReady()
        #expect(vm.status == .connecting)

        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)
        #expect(await repo.startStreamingCallCount == 1)

        await repo.finishStream()
    }

    @Test("startRecordingIfReady from .idle with prereqs transitions to recording")
    func startFromIdleWithPrereqs() async throws {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let vm = makeViewModel(mockRepo: repo, mockPreferences: prefs, mockKeychain: keychain)

        #expect(vm.status == .idle)
        vm.startRecordingIfReady()

        try await Task.sleep(for: .milliseconds(100))
        #expect(vm.status == .recording)
        #expect(await repo.startStreamingCallCount == 1)

        await repo.finishStream()
    }

    @Test("startRecordingIfReady from .idle when disabled stays idle")
    func startFromIdleDisabled() async throws {
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = false
        let vm = makeViewModel(mockPreferences: prefs)

        #expect(vm.status == .idle)
        vm.startRecordingIfReady()

        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .idle)
    }

    @Test("startRecordingIfReady from .idle without API key stays idle")
    func startFromIdleNoKey() async throws {
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let vm = makeViewModel(mockPreferences: prefs)

        #expect(vm.status == .idle)
        vm.startRecordingIfReady()

        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .idle)
    }

    @Test("startRecordingIfReady from .error resets and starts recording")
    func startFromError() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(startStreamingError: TranscriptionError.connectionFailed("test"))
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        // Force error state
        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        if case .error = vm.status {} else {
            Issue.record("Expected .error status, got \(vm.status)")
        }

        // Now fix the repo and try again from .error
        await repo.configure(startStreamingError: nil, keepStreamOpen: true)
        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)

        await repo.finishStream()
    }

    @Test("startRecordingIfReady from .result resets and starts recording")
    func startFromResult() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        // Get to .result state
        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)
        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(100))
        if case .result = vm.status {} else {
            Issue.record("Expected .result status, got \(vm.status)")
        }

        // Now start again from .result
        await repo.configure(keepStreamOpen: true)
        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)

        await repo.finishStream()
    }

    @Test("startRecordingIfReady from .connecting is no-op")
    func startFromConnecting() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        #expect(vm.status == .connecting)

        // Press again while connecting — should be no-op
        vm.startRecordingIfReady()
        #expect(vm.status == .connecting)

        try await Task.sleep(for: .milliseconds(50))
        await repo.finishStream()
    }

    @Test("startRecordingIfReady from .recording is no-op")
    func startFromRecording() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)

        // Press again while recording — should be no-op
        vm.startRecordingIfReady()
        #expect(vm.status == .recording)
        #expect(await repo.startStreamingCallCount == 1)

        await repo.finishStream()
    }

    // MARK: - stopIfRecording — from every status

    @Test("stopIfRecording from .recording calls stop and transitions to result")
    func stopFromRecording() async throws {
        let repo = MockTranscriptionRepository()
        let result = TranscriptionEntity(text: "hello world", language: .english, duration: 2.0)
        await repo.configure(stopStreamingResult: result, keepStreamOpen: true)
        let textService = MockTextInsertionService()
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo, mockTextInsertion: textService)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)

        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(300))
        #expect(await repo.stopStreamingCallCount == 1)
        if case .result(let entity) = vm.status {
            #expect(entity.text == "hello world")
        } else {
            Issue.record("Expected .result status, got \(vm.status)")
        }
    }

    @Test("stopIfRecording from .connecting cancels and returns to ready")
    func stopFromConnecting() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        #expect(vm.status == .connecting)

        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .ready)
        #expect(await repo.cancelStreamingCallCount == 1)
        #expect(await repo.stopStreamingCallCount == 0)
    }

    @Test("stopIfRecording from .idle is no-op")
    func stopFromIdle() {
        let vm = makeViewModel()
        #expect(vm.status == .idle)
        vm.stopIfRecording()
        #expect(vm.status == .idle)
    }

    @Test("stopIfRecording from .ready is no-op")
    func stopFromReady() async {
        let (vm, _, _, _) = await makeReadyViewModel()
        #expect(vm.status == .ready)
        vm.stopIfRecording()
        #expect(vm.status == .ready)
    }

    @Test("stopIfRecording from .error is no-op")
    func stopFromError() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(startStreamingError: TranscriptionError.connectionFailed("fail"))
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        if case .error = vm.status {} else {
            Issue.record("Expected .error, got \(vm.status)")
        }

        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(50))
        if case .error = vm.status {} else {
            Issue.record("Expected .error unchanged, got \(vm.status)")
        }
    }

    // MARK: - Full Push-to-Talk Flow

    @Test("full push-to-talk: keyDown → recording → keyUp → text inserted")
    func fullPushToTalkFlow() async throws {
        let repo = MockTranscriptionRepository()
        let result = TranscriptionEntity(text: "transcribed text", language: .english, duration: 3.0)
        await repo.configure(stopStreamingResult: result, keepStreamOpen: true)
        let textService = MockTextInsertionService()
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo, mockTextInsertion: textService)

        // Simulate key DOWN
        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)

        // Simulate key UP
        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(300))

        // Text should be inserted
        #expect(textService.insertTextCallCount == 1)
        #expect(textService.lastInsertedText == "transcribed text")
        if case .result(let entity) = vm.status {
            #expect(entity.text == "transcribed text")
        } else {
            Issue.record("Expected .result, got \(vm.status)")
        }
    }

    @Test("full push-to-talk with empty result: no text inserted")
    func fullPushToTalkEmptyResult() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(stopStreamingResult: .empty(), keepStreamOpen: true)
        let textService = MockTextInsertionService()
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo, mockTextInsertion: textService)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(300))

        #expect(textService.insertTextCallCount == 0)
    }

    @Test("push-to-talk auto-resets to ready after result")
    func pushToTalkAutoResets() async throws {
        let repo = MockTranscriptionRepository()
        let result = TranscriptionEntity(text: "hello", language: .english, duration: 1.0)
        await repo.configure(stopStreamingResult: result, keepStreamOpen: true)
        let textService = MockTextInsertionService()
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo, mockTextInsertion: textService)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(300))
        if case .result = vm.status {} else {
            Issue.record("Expected .result, got \(vm.status)")
        }

        // Wait for auto-reset (1.5s in code)
        try await Task.sleep(for: .seconds(2))
        #expect(vm.status == .ready)
    }

    @Test("consecutive push-to-talk sessions work")
    func consecutivePushToTalkSessions() async throws {
        let repo = MockTranscriptionRepository()
        let result1 = TranscriptionEntity(text: "first", language: .english, duration: 1.0)
        await repo.configure(stopStreamingResult: result1, keepStreamOpen: true)
        let textService = MockTextInsertionService()
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo, mockTextInsertion: textService)

        // Session 1
        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(300))
        #expect(textService.insertTextCallCount == 1)

        // Wait for auto-reset
        try await Task.sleep(for: .seconds(2))
        #expect(vm.status == .ready)

        // Session 2
        let result2 = TranscriptionEntity(text: "second", language: .english, duration: 2.0)
        await repo.configure(stopStreamingResult: result2, keepStreamOpen: true)
        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)
        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(300))
        #expect(textService.insertTextCallCount == 2)
        #expect(textService.lastInsertedText == "second")
    }

    // MARK: - Stream Finishes Unexpectedly (BUG DETECTOR)

    @Test("when stream finishes unexpectedly status must not stay stuck at recording")
    func streamFinishesUnexpectedly() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)

        // Server closes connection — stream finishes
        await repo.finishStream()
        try await Task.sleep(for: .milliseconds(100))

        // Status MUST transition out of .recording — otherwise shortcut will never work again
        #expect(vm.status != .recording, "BUG: Status stuck at .recording after stream ended — subsequent shortcut presses will be silently ignored")
    }

    @Test("after unexpected stream end the shortcut must work again")
    func shortcutWorksAfterUnexpectedStreamEnd() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        // Start recording
        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)
        #expect(await repo.startStreamingCallCount == 1)

        // Stream ends unexpectedly
        await repo.finishStream()
        try await Task.sleep(for: .milliseconds(100))

        // User presses shortcut again — it MUST start a new recording
        await repo.configure(keepStreamOpen: true)
        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(100))
        #expect(vm.status == .recording, "BUG: Cannot start new recording after stream ended unexpectedly")
        // Verify it's actually a NEW recording session, not stuck from the old one
        #expect(await repo.startStreamingCallCount == 2, "BUG: Second recording session did not start — shortcut is dead after stream ended")

        await repo.finishStream()
    }

    // MARK: - interimText

    @Test("interimText updates during stream")
    func interimTextUpdates() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)

        await repo.yieldText("hello")
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.interimText == "hello")

        await repo.yieldText("hello world")
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.interimText == "hello world")

        await repo.finishStream()
    }

    @Test("interimText clears after stop")
    func interimTextClearsAfterStop() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))

        await repo.yieldText("some text")
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.interimText == "some text")

        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(300))
        #expect(vm.interimText == "")
    }

    @Test("interimText clears after cancel")
    func interimTextClearsAfterCancel() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))

        await repo.yieldText("interim")
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.interimText == "interim")

        vm.cancel()
        try await Task.sleep(for: .milliseconds(100))
        #expect(vm.interimText == "")
    }

    // MARK: - Error Handling

    @Test("startRecording with empty API key in keychain sets error")
    func startRecordingEmptyApiKey() async throws {
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": ""])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        let repo = MockTranscriptionRepository()
        let vm = makeViewModel(mockRepo: repo, mockPreferences: prefs, mockKeychain: keychain)

        // Force to .ready state manually (onAppear sees key exists but startRecording checks !isEmpty)
        await vm.enable()
        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.status == .error(.apiKeyMissing), "Empty API key string should be treated as missing")
    }

    @Test("startRecording with transcription error sets error status")
    func startRecordingTranscriptionError() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(startStreamingError: TranscriptionError.connectionFailed("timeout"))
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))

        #expect(vm.status == .error(.connectionFailed("timeout")))
    }

    @Test("startRecording with auth error sets error status")
    func startRecordingAuthError() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(startStreamingError: TranscriptionError.authenticationFailed)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))

        #expect(vm.status == .error(.authenticationFailed))
    }

    @Test("stopAndInsert with accessibility denied sets error")
    func stopAndInsertAccessibilityDenied() async throws {
        let repo = MockTranscriptionRepository()
        let result = TranscriptionEntity(text: "text", language: .english, duration: 1.0)
        await repo.configure(stopStreamingResult: result, keepStreamOpen: true)
        let textService = MockTextInsertionService()
        textService.insertTextError = TranscriptionError.accessibilityDenied
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo, mockTextInsertion: textService)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(300))

        #expect(vm.status == .error(.accessibilityDenied))
    }

    @Test("stopAndInsert with stop error sets error status")
    func stopAndInsertStopError() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(stopStreamingError: TranscriptionError.transcriptionFailed("network"), keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(100))

        if case .error = vm.status {} else {
            Issue.record("Expected .error, got \(vm.status)")
        }
    }

    // MARK: - cancel()

    @Test("cancel cancels stream task and resets to ready")
    func cancelResetsToReady() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)

        vm.cancel()
        try await Task.sleep(for: .milliseconds(100))
        #expect(vm.status == .ready)
        #expect(vm.interimText == "")
        #expect(await repo.cancelStreamingCallCount == 1)
    }

    // MARK: - toggleRecording — from every status

    @Test("toggleRecording from .idle beeps (no state change)")
    func toggleFromIdleBeeps() {
        let vm = makeViewModel()
        vm.toggleRecording()
        #expect(vm.status == .idle)
    }

    @Test("toggleRecording from .ready starts recording")
    func toggleFromReady() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.toggleRecording()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)
        #expect(await repo.startStreamingCallCount == 1)

        await repo.finishStream()
    }

    @Test("toggleRecording from .recording stops and inserts")
    func toggleFromRecording() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.toggleRecording()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)

        vm.toggleRecording()
        try await Task.sleep(for: .milliseconds(100))
        #expect(await repo.stopStreamingCallCount == 1)
    }

    @Test("toggleRecording from .connecting cancels")
    func toggleFromConnecting() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.toggleRecording()
        #expect(vm.status == .connecting)

        vm.toggleRecording()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .ready)
        #expect(await repo.cancelStreamingCallCount == 1)
    }

    @Test("toggleRecording from .error starts recording")
    func toggleFromError() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(startStreamingError: TranscriptionError.connectionFailed("fail"))
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        if case .error = vm.status {} else {
            Issue.record("Expected .error, got \(vm.status)")
        }

        await repo.configure(startStreamingError: nil, keepStreamOpen: true)
        vm.toggleRecording()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)

        await repo.finishStream()
    }

    @Test("toggleRecording from .result starts recording")
    func toggleFromResult() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let (vm, _, _, _) = await makeReadyViewModel(mockRepo: repo)

        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))
        vm.stopIfRecording()
        try await Task.sleep(for: .milliseconds(100))
        if case .result = vm.status {} else {
            Issue.record("Expected .result, got \(vm.status)")
        }

        await repo.configure(keepStreamOpen: true)
        vm.toggleRecording()
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .recording)

        await repo.finishStream()
    }

    // MARK: - Language Selection

    @Test("startRecording passes selected language to repository")
    func startRecordingPassesLanguage() async throws {
        let repo = MockTranscriptionRepository()
        await repo.configure(keepStreamOpen: true)
        let keychain = MockKeychainService()
        await keychain.configure(storage: ["deepgramApiKey": "test-key"])
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = true
        prefs.selectedLanguage = .ukrainian
        let vm = makeViewModel(mockRepo: repo, mockPreferences: prefs, mockKeychain: keychain)

        await vm.onAppear()
        vm.startRecordingIfReady()
        try await Task.sleep(for: .milliseconds(50))

        #expect(await repo.lastLanguage == .ukrainian)
        #expect(await repo.lastApiKey == "test-key")

        await repo.finishStream()
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

    @Test("saveApiKey does NOT set ready when disabled")
    func saveApiKeyDoesNotSetReadyWhenDisabled() async {
        let keychain = MockKeychainService()
        let prefs = MockVoiceInputPreferences()
        prefs.isEnabled = false
        let vm = makeViewModel(mockPreferences: prefs, mockKeychain: keychain)

        await vm.saveApiKey("new-key")
        #expect(vm.status == .idle)
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

        await vm.fetchBalance()
        #expect(vm.isLoadingBalance == false)
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
