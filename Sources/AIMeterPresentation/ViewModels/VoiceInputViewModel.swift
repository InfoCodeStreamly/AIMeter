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
        voiceLog.warning("onAppear: isEnabled=\(self.preferencesService.isEnabled)")
        guard preferencesService.isEnabled else {
            status = .idle
            voiceLog.warning("onAppear: disabled → .idle")
            return
        }
        if await hasApiKey() {
            status = .ready
            voiceLog.warning("onAppear: has API key → .ready")
        } else {
            status = .idle
            voiceLog.warning("onAppear: no API key → .idle")
        }
    }

    // MARK: - Recording (Push-to-Talk)

    /// Called on key DOWN — starts recording if possible
    public func startRecordingIfReady() {
        voiceLog.warning("startRecordingIfReady: status=\(String(describing: self.status), privacy: .public)")
        switch status {
        case .ready:
            voiceLog.warning("startRecordingIfReady: .ready → startRecording()")
            startRecording()
        case .idle:
            voiceLog.warning("startRecordingIfReady: .idle → checking prerequisites")
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
                voiceLog.warning("startRecordingIfReady: prerequisites OK → .ready → startRecording()")
                status = .ready
                startRecording()
            }
        case .error, .result:
            voiceLog.warning("startRecordingIfReady: \(String(describing: self.status), privacy: .public) → .ready → startRecording()")
            status = .ready
            startRecording()
        default:
            voiceLog.warning("startRecordingIfReady: ignored, status=\(String(describing: self.status), privacy: .public)")
            break
        }
    }

    /// Called on key UP — stops recording and inserts text
    public func stopIfRecording() {
        voiceLog.warning("stopIfRecording: status=\(String(describing: self.status), privacy: .public)")
        switch status {
        case .recording:
            voiceLog.warning("stopIfRecording: .recording → stopAndInsert()")
            stopAndInsert()
        case .connecting:
            // Don't cancel — wait for connection to complete, then stop
            voiceLog.warning("stopIfRecording: .connecting → waiting for recording to start, then stop")
            Task {
                // Wait up to 3 seconds for status to change from .connecting
                for _ in 0..<30 {
                    try? await Task.sleep(for: .milliseconds(100))
                    if status == .recording {
                        voiceLog.warning("stopIfRecording: connection ready → stopAndInsert()")
                        stopAndInsert()
                        return
                    }
                    if status != .connecting {
                        voiceLog.warning("stopIfRecording: status changed to \(String(describing: self.status), privacy: .public), done")
                        return
                    }
                }
                // Timeout — still connecting, cancel
                voiceLog.warning("stopIfRecording: timeout waiting for connection → cancel()")
                cancel()
            }
        default:
            voiceLog.warning("stopIfRecording: ignored, status=\(String(describing: self.status), privacy: .public)")
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
        voiceLog.warning("startRecording: playing Tink, previousApp=\(self.previousApp?.localizedName ?? "nil", privacy: .public)")
        NSSound(named: "Tink")?.play()
        status = .connecting

        streamTask = Task {
            do {
                guard let apiKey = await keychainService.read(forKey: apiKeyKeychainKey),
                      !apiKey.isEmpty else {
                    voiceLog.warning("startRecording: API key missing or empty")
                    status = .error(.apiKeyMissing)
                    return
                }

                let language = preferencesService.selectedLanguage
                voiceLog.warning("startRecording: calling startTranscriptionUseCase, language=\(String(describing: language), privacy: .public)")
                let stream = try await startTranscriptionUseCase.execute(
                    language: language,
                    apiKey: apiKey
                )

                guard !Task.isCancelled else {
                    voiceLog.warning("startRecording: cancelled before recording started")
                    return
                }
                status = .recording
                voiceLog.warning("startRecording: → .recording, iterating stream")

                for await text in stream {
                    interimText = text
                    voiceLog.warning("startRecording: interimText='\(text.prefix(80), privacy: .public)'")
                }

                voiceLog.warning("startRecording: stream ended, isCancelled=\(Task.isCancelled)")
                // Stream ended (server closed connection, timeout, etc.)
                // Transition to ready so the shortcut works again
                if !Task.isCancelled {
                    status = .ready
                }
            } catch let error as TranscriptionError {
                voiceLog.warning("startRecording: TranscriptionError: \(error.localizedDescription, privacy: .public)")
                status = .error(error)
            } catch {
                voiceLog.warning("startRecording: error: \(error.localizedDescription, privacy: .public)")
                status = .error(.transcriptionFailed(error.localizedDescription))
            }
        }
    }

    public func stopAndInsert() {
        voiceLog.warning("stopAndInsert: playing Pop, cancelling streamTask")
        NSSound(named: "Pop")?.play()
        streamTask?.cancel()

        Task {
            do {
                let result = try await stopTranscriptionUseCase.execute()
                voiceLog.warning("stopAndInsert: result text='\(result.text.prefix(100), privacy: .public)', isEmpty=\(result.isEmpty)")
                status = .result(result)

                if !result.isEmpty {
                    voiceLog.warning("stopAndInsert: activating previousApp=\(self.previousApp?.localizedName ?? "nil", privacy: .public)")
                    previousApp?.activate()
                    try? await Task.sleep(for: .milliseconds(200))

                    do {
                        try await insertTextUseCase.execute(text: result.text)
                        voiceLog.warning("stopAndInsert: text inserted successfully ✓")
                    } catch TranscriptionError.accessibilityDenied {
                        voiceLog.warning("stopAndInsert: accessibility denied!")
                        status = .error(.accessibilityDenied)
                        return
                    }
                } else {
                    voiceLog.warning("stopAndInsert: result is EMPTY, nothing to insert")
                }

                // Auto-reset to ready after showing result
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    if case .result = status { status = .ready }
                }
            } catch {
                voiceLog.warning("stopAndInsert: error: \(error.localizedDescription, privacy: .public)")
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
