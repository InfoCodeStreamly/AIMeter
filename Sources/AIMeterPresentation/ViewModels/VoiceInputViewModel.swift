import AIMeterApplication
import AIMeterDomain
import AIMeterInfrastructure
import AppKit

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

    private let apiKeyKeychainKey = "deepgramApiKey"

    public init(
        startTranscriptionUseCase: StartTranscriptionUseCase,
        stopTranscriptionUseCase: StopTranscriptionUseCase,
        cancelTranscriptionUseCase: CancelTranscriptionUseCase,
        insertTextUseCase: InsertTextUseCase,
        fetchBalanceUseCase: FetchDeepgramBalanceUseCase,
        preferencesService: any VoiceInputPreferencesProtocol,
        keychainService: any KeychainServiceProtocol
    ) {
        self.startTranscriptionUseCase = startTranscriptionUseCase
        self.stopTranscriptionUseCase = stopTranscriptionUseCase
        self.cancelTranscriptionUseCase = cancelTranscriptionUseCase
        self.insertTextUseCase = insertTextUseCase
        self.fetchBalanceUseCase = fetchBalanceUseCase
        self.preferencesService = preferencesService
        self.keychainService = keychainService
    }

    // MARK: - Lifecycle

    public func onAppear() async {
        guard preferencesService.isEnabled else {
            status = .idle
            return
        }
        if await hasApiKey() {
            status = .ready
        } else {
            status = .idle
        }
    }

    // MARK: - Recording (Push-to-Talk)

    /// Called on key DOWN — starts recording if possible
    public func startRecordingIfReady() {
        switch status {
        case .ready:
            startRecording()
        case .idle:
            // First use or after restart — check prerequisites and start
            Task {
                guard preferencesService.isEnabled else {
                    NSSound.beep()
                    return
                }
                guard await hasApiKey() else {
                    NSSound.beep()
                    return
                }
                status = .ready
                startRecording()
            }
        case .error, .result:
            status = .ready
            startRecording()
        default:
            break
        }
    }

    /// Called on key UP — stops recording and inserts text
    public func stopIfRecording() {
        switch status {
        case .recording:
            stopAndInsert()
        case .connecting:
            cancel()
        default:
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
        NSSound(named: "Tink")?.play()
        status = .connecting

        streamTask = Task {
            do {
                guard let apiKey = await keychainService.read(forKey: apiKeyKeychainKey),
                      !apiKey.isEmpty else {
                    status = .error(.apiKeyMissing)
                    return
                }

                let language = preferencesService.selectedLanguage
                let stream = try await startTranscriptionUseCase.execute(
                    language: language,
                    apiKey: apiKey
                )

                guard !Task.isCancelled else { return }
                status = .recording

                for await text in stream {
                    interimText = text
                }
            } catch let error as TranscriptionError {
                status = .error(error)
            } catch {
                status = .error(.transcriptionFailed(error.localizedDescription))
            }
        }
    }

    public func stopAndInsert() {
        NSSound(named: "Pop")?.play()
        streamTask?.cancel()

        Task {
            do {
                let result = try await stopTranscriptionUseCase.execute()
                status = .result(result)

                if !result.isEmpty {
                    previousApp?.activate()
                    try? await Task.sleep(for: .milliseconds(200))

                    do {
                        try await insertTextUseCase.execute(text: result.text)
                    } catch TranscriptionError.accessibilityDenied {
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
        AXIsProcessTrusted()
    }

    public func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
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
