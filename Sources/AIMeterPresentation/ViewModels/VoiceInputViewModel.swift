import AIMeterApplication
import AIMeterDomain
import AppKit
import OSLog

private let voiceLog = Logger(subsystem: "com.codestreamly.AIMeter", category: "voice")

/// ViewModel for voice input feature
@MainActor
@Observable
public final class VoiceInputViewModel {
    public private(set) var status: TranscriptionStatus = .idle
    public private(set) var interimText: String = ""
    public private(set) var balance: DeepgramBalance?
    public private(set) var balanceError: String?
    public private(set) var isLoadingBalance: Bool = false

    private var streamTask: Task<Void, Never>?
    private var previousApp: NSRunningApplication?

    private let startTranscriptionUseCase: StartTranscriptionUseCase
    private let stopTranscriptionUseCase: StopTranscriptionUseCase
    private let cancelTranscriptionUseCase: CancelTranscriptionUseCase
    private let insertTextUseCase: InsertTextUseCase
    private let fetchBalanceUseCase: FetchDeepgramBalanceUseCase
    private var preferencesService: any VoiceInputPreferencesProtocol
    private let keychainService: any KeychainServiceProtocol
    private let accessibilityService: any AccessibilityServiceProtocol

    private let apiKeyKeychainKey = "deepgramApiKey"

    public init(
        startTranscriptionUseCase: StartTranscriptionUseCase,
        stopTranscriptionUseCase: StopTranscriptionUseCase,
        cancelTranscriptionUseCase: CancelTranscriptionUseCase,
        insertTextUseCase: InsertTextUseCase,
        fetchBalanceUseCase: FetchDeepgramBalanceUseCase,
        preferencesService: any VoiceInputPreferencesProtocol,
        keychainService: any KeychainServiceProtocol,
        accessibilityService: any AccessibilityServiceProtocol
    ) {
        self.startTranscriptionUseCase = startTranscriptionUseCase
        self.stopTranscriptionUseCase = stopTranscriptionUseCase
        self.cancelTranscriptionUseCase = cancelTranscriptionUseCase
        self.insertTextUseCase = insertTextUseCase
        self.fetchBalanceUseCase = fetchBalanceUseCase
        self.preferencesService = preferencesService
        self.keychainService = keychainService
        self.accessibilityService = accessibilityService
    }

    // MARK: - Lifecycle

    public func onAppear() async {
        voiceLog.info("onAppear: isEnabled=\(self.preferencesService.isEnabled)")
        guard preferencesService.isEnabled else {
            status = .idle
            voiceLog.info("onAppear: disabled → .idle")
            return
        }
        if await hasApiKey() {
            status = .ready
            voiceLog.info("onAppear: has API key → .ready")
        } else {
            status = .idle
            voiceLog.info("onAppear: no API key → .idle")
        }
    }

    // MARK: - Recording (Push-to-Talk)

    /// Called on key DOWN — starts recording if possible
    public func startRecordingIfReady() {
        voiceLog.info("startRecordingIfReady: status=\(String(describing: self.status))")
        switch status {
        case .ready:
            voiceLog.info("startRecordingIfReady: .ready → startRecording()")
            startRecording()
        case .idle:
            voiceLog.info("startRecordingIfReady: .idle → checking prerequisites")
            Task {
                guard preferencesService.isEnabled else {
                    voiceLog.warning("startRecordingIfReady: voice input disabled → beep")
                    NSSound.beep()
                    return
                }
                guard await hasApiKey() else {
                    voiceLog.warning("startRecordingIfReady: no API key → beep")
                    NSSound.beep()
                    return
                }
                voiceLog.info("startRecordingIfReady: prerequisites OK → .ready → startRecording()")
                status = .ready
                startRecording()
            }
        case .error, .result:
            voiceLog.info("startRecordingIfReady: \(String(describing: self.status)) → .ready → startRecording()")
            status = .ready
            startRecording()
        default:
            voiceLog.warning("startRecordingIfReady: ignored, status=\(String(describing: self.status))")
            break
        }
    }

    /// Called on key UP — stops recording and inserts text
    public func stopIfRecording() {
        voiceLog.info("stopIfRecording: status=\(String(describing: self.status))")
        switch status {
        case .recording:
            voiceLog.info("stopIfRecording: .recording → stopAndInsert()")
            stopAndInsert()
        case .connecting:
            // Don't cancel — wait for connection to complete, then stop
            voiceLog.info("stopIfRecording: .connecting → waiting for recording to start, then stop")
            Task {
                // Wait up to 3 seconds for status to change from .connecting
                for _ in 0..<30 {
                    try? await Task.sleep(for: .milliseconds(100))
                    if status == .recording {
                        voiceLog.info("stopIfRecording: connection ready → stopAndInsert()")
                        stopAndInsert()
                        return
                    }
                    if status != .connecting {
                        voiceLog.info("stopIfRecording: status changed to \(String(describing: self.status)), done")
                        return
                    }
                }
                // Timeout — still connecting, cancel
                voiceLog.warning("stopIfRecording: timeout waiting for connection → cancel()")
                cancel()
            }
        default:
            voiceLog.info("stopIfRecording: ignored, status=\(String(describing: self.status))")
            break
        }
    }

    public func toggleRecording() {
        switch status {
        case .recording:
            stopAndInsert()
        case .connecting:
            cancel()
        case .ready:
            startRecording()
        case .error, .result:
            status = .ready
            startRecording()
        default:
            NSSound.beep()
        }
    }

    public func startRecording() {
        previousApp = NSWorkspace.shared.frontmostApplication
        voiceLog.info("startRecording: playing Tink, previousApp=\(self.previousApp?.localizedName ?? "nil")")
        NSSound(named: "Tink")?.play()
        status = .connecting

        streamTask = Task {
            do {
                guard let apiKey = await keychainService.read(forKey: apiKeyKeychainKey),
                      !apiKey.isEmpty else {
                    voiceLog.error("startRecording: API key missing or empty")
                    status = .error(.apiKeyMissing)
                    return
                }

                let language = preferencesService.selectedLanguage
                voiceLog.info("startRecording: calling startTranscriptionUseCase, language=\(String(describing: language))")
                let stream = try await startTranscriptionUseCase.execute(
                    language: language,
                    apiKey: apiKey
                )

                guard !Task.isCancelled else {
                    voiceLog.info("startRecording: cancelled before recording started")
                    return
                }
                status = .recording
                voiceLog.info("startRecording: → .recording, iterating stream")

                for await text in stream {
                    interimText = text
                    voiceLog.debug("startRecording: interimText=\(text.prefix(50))")
                }

                voiceLog.info("startRecording: stream ended, isCancelled=\(Task.isCancelled)")
                // Stream ended (server closed connection, timeout, etc.)
                // Transition to ready so the shortcut works again
                if !Task.isCancelled {
                    status = .ready
                }
            } catch let error as TranscriptionError {
                voiceLog.error("startRecording: TranscriptionError: \(error.localizedDescription, privacy: .public)")
                status = .error(error)
            } catch {
                voiceLog.error("startRecording: error: \(error.localizedDescription, privacy: .public)")
                status = .error(.transcriptionFailed(error.localizedDescription))
            }
        }
    }

    public func stopAndInsert() {
        voiceLog.info("stopAndInsert: playing Pop, cancelling streamTask")
        NSSound(named: "Pop")?.play()
        streamTask?.cancel()

        Task {
            do {
                let result = try await stopTranscriptionUseCase.execute()
                voiceLog.info("stopAndInsert: result text='\(result.text.prefix(80))', isEmpty=\(result.isEmpty)")
                status = .result(result)

                if !result.isEmpty {
                    previousApp?.activate()
                    try? await Task.sleep(for: .milliseconds(200))

                    do {
                        try await insertTextUseCase.execute(text: result.text)
                        voiceLog.info("stopAndInsert: text inserted successfully")
                    } catch TranscriptionError.accessibilityDenied {
                        voiceLog.error("stopAndInsert: accessibility denied")
                        status = .error(.accessibilityDenied)
                        return
                    }
                }

                // Auto-reset to ready after showing result
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    if case .result = status { status = .ready }
                }
            } catch {
                voiceLog.error("stopAndInsert: error: \(error.localizedDescription)")
                status = .error(.transcriptionFailed(error.localizedDescription))
            }

            interimText = ""
        }
    }

    public func cancel() {
        streamTask?.cancel()
        Task {
            await cancelTranscriptionUseCase.execute()
            status = .ready
            interimText = ""
        }
    }

    // MARK: - API Key Management

    public func saveApiKey(_ key: String) async {
        do {
            try await keychainService.save(key, forKey: apiKeyKeychainKey)
            if preferencesService.isEnabled {
                status = .ready
            }
        } catch {
            // Keychain save failed silently
        }
    }

    public func deleteApiKey() async {
        do {
            try await keychainService.delete(forKey: apiKeyKeychainKey)
        } catch {
            // Keychain delete failed silently
        }
        status = .idle
        balance = nil
    }

    public func loadApiKey() async -> String {
        await keychainService.read(forKey: apiKeyKeychainKey) ?? ""
    }

    public func hasApiKey() async -> Bool {
        await keychainService.exists(forKey: apiKeyKeychainKey)
    }

    // MARK: - Balance

    public func fetchBalance() async {
        guard let apiKey = await keychainService.read(forKey: apiKeyKeychainKey) else { return }
        isLoadingBalance = true
        balanceError = nil

        do {
            balance = try await fetchBalanceUseCase.execute(apiKey: apiKey)
        } catch let error as TranscriptionError {
            balanceError = error.errorDescription
        } catch {
            balanceError = error.localizedDescription
        }

        isLoadingBalance = false
    }

    // MARK: - Enable/Disable

    public func enable() async {
        preferencesService.isEnabled = true
        if await hasApiKey() {
            status = .ready
        } else {
            status = .idle
        }
    }

    public func disable() async {
        preferencesService.isEnabled = false
        cancel()
        status = .idle
    }

    // MARK: - Permissions

    public func checkAccessibility() -> Bool {
        accessibilityService.isAccessibilityGranted()
    }

    public func requestAccessibility() {
        accessibilityService.requestAccessibilityPermission()
    }

    public func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
