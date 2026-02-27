import Foundation
import AIMeterDomain
import AIMeterApplication

/// Service for managing voice input preferences backed by UserDefaults
@Observable
@MainActor
public final class VoiceInputPreferencesService: VoiceInputPreferencesProtocol {
    @ObservationIgnored private let defaults = UserDefaults.standard

    private var _isEnabled: Bool
    private var _selectedLanguage: TranscriptionLanguage

    public var isEnabled: Bool {
        get { _isEnabled }
        set {
            _isEnabled = newValue
            defaults.set(newValue, forKey: "voiceInput.enabled")
        }
    }

    public var selectedLanguage: TranscriptionLanguage {
        get { _selectedLanguage }
        set {
            _selectedLanguage = newValue
            defaults.set(newValue.rawValue, forKey: "voiceInput.selectedLanguage")
        }
    }

    public init() {
        _isEnabled = defaults.bool(forKey: "voiceInput.enabled")

        let savedLanguage = defaults.string(forKey: "voiceInput.selectedLanguage") ?? ""
        _selectedLanguage = TranscriptionLanguage(rawValue: savedLanguage) ?? .autoDetect
    }
}
