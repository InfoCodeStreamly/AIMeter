import Foundation
import Testing
@testable import AIMeterInfrastructure
import AIMeterDomain

@Suite("VoiceInputPreferencesService")
@MainActor
struct VoiceInputPreferencesServiceTests {

    private func cleanupTestData() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "voiceInput.enabled")
        defaults.removeObject(forKey: "voiceInput.selectedLanguage")
    }

    @Test("default isEnabled is false")
    func defaultIsEnabledIsFalse() {
        cleanupTestData()
        let service = VoiceInputPreferencesService()
        #expect(service.isEnabled == false)
    }

    @Test("default selectedLanguage is autoDetect")
    func defaultLanguageIsAutoDetect() {
        cleanupTestData()
        let service = VoiceInputPreferencesService()
        #expect(service.selectedLanguage == .autoDetect)
    }

    @Test("isEnabled persists to UserDefaults")
    func isEnabledPersists() {
        cleanupTestData()
        let service = VoiceInputPreferencesService()
        service.isEnabled = true
        #expect(UserDefaults.standard.bool(forKey: "voiceInput.enabled") == true)
    }

    @Test("isEnabled persists across service instances")
    func isEnabledPersistsAcrossInstances() {
        cleanupTestData()
        let service1 = VoiceInputPreferencesService()
        service1.isEnabled = true

        let service2 = VoiceInputPreferencesService()
        #expect(service2.isEnabled == true)
        cleanupTestData()
    }

    @Test("selectedLanguage persists to UserDefaults")
    func selectedLanguagePersists() {
        cleanupTestData()
        let service = VoiceInputPreferencesService()
        service.selectedLanguage = .ukrainian
        #expect(UserDefaults.standard.string(forKey: "voiceInput.selectedLanguage") == "uk")
    }

    @Test("selectedLanguage persists across service instances")
    func selectedLanguagePersistsAcrossInstances() {
        cleanupTestData()
        let service1 = VoiceInputPreferencesService()
        service1.selectedLanguage = .ukrainian

        let service2 = VoiceInputPreferencesService()
        #expect(service2.selectedLanguage == .ukrainian)
        cleanupTestData()
    }

    @Test("setting isEnabled to true then false results in false")
    func isEnabledToggle() {
        cleanupTestData()
        let service = VoiceInputPreferencesService()
        service.isEnabled = true
        service.isEnabled = false
        #expect(service.isEnabled == false)
        cleanupTestData()
    }

    @Test("setting selectedLanguage updates correctly")
    func selectedLanguageUpdates() {
        cleanupTestData()
        let service = VoiceInputPreferencesService()
        service.selectedLanguage = .german
        #expect(service.selectedLanguage == .german)
        service.selectedLanguage = .french
        #expect(service.selectedLanguage == .french)
        cleanupTestData()
    }
}
