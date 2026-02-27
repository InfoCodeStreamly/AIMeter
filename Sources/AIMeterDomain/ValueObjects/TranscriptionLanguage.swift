import Foundation

/// Supported languages for voice transcription
public enum TranscriptionLanguage: String, Sendable, CaseIterable, Codable {
    case autoDetect = ""
    case english = "en"
    case ukrainian = "uk"
    case russian = "ru"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case polish = "pl"

    /// BCP-47 language code for API, nil for auto-detect
    public var apiCode: String? {
        switch self {
        case .autoDetect: nil
        default: rawValue
        }
    }

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .autoDetect: "Auto-detect"
        case .english: "English"
        case .ukrainian: "Ukrainian"
        case .russian: "Russian"
        case .german: "German"
        case .french: "French"
        case .spanish: "Spanish"
        case .polish: "Polish"
        }
    }
}
