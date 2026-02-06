import Testing
@testable import AIMeterInfrastructure
import AIMeterApplication
import Foundation

/// Tests for NotificationPreferencesService
///
/// This suite tests the notification preferences service that manages
/// user notification settings and tracks sent notifications.
/// All tests must run on the main actor due to the service being @MainActor.
///
/// IMPORTANT: This service uses UserDefaults.standard. Tests must clean up
/// after themselves to avoid state leakage between test runs.
@Suite("NotificationPreferencesService")
@MainActor
struct NotificationPreferencesServiceTests {

    // Test key prefix to isolate test data
    private static let testKeyPrefix = "test_notifications_"

    // MARK: - Helper Methods

    /// Clean up test data from UserDefaults
    func cleanupTestData() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "notificationsEnabled")
        defaults.removeObject(forKey: "notificationWarningThreshold")
        defaults.removeObject(forKey: "notificationCriticalThreshold")
        defaults.removeObject(forKey: "sentNotifications")
    }

    // MARK: - Default Values Tests

    @Test("default isEnabled is true")
    func defaultIsEnabledIsTrue() {
        // Arrange
        cleanupTestData()

        // Act
        let service = NotificationPreferencesService()

        // Assert
        #expect(service.isEnabled == true)

        // Cleanup
        cleanupTestData()
    }

    @Test("default warningThreshold is 80")
    func defaultWarningThresholdIs80() {
        // Arrange
        cleanupTestData()

        // Act
        let service = NotificationPreferencesService()

        // Assert
        #expect(service.warningThreshold == 80)

        // Cleanup
        cleanupTestData()
    }

    @Test("default criticalThreshold is 95")
    func defaultCriticalThresholdIs95() {
        // Arrange
        cleanupTestData()

        // Act
        let service = NotificationPreferencesService()

        // Assert
        #expect(service.criticalThreshold == 95)

        // Cleanup
        cleanupTestData()
    }

    // MARK: - wasSent Tests

    @Test("wasSent returns false for unknown key")
    func wasSentReturnsFalseForUnknownKey() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()
        let unknownKey = "\(Self.testKeyPrefix)unknown_key_12345"

        // Act
        let result = service.wasSent(key: unknownKey)

        // Assert
        #expect(result == false)

        // Cleanup
        cleanupTestData()
    }

    @Test("wasSent returns false for empty key")
    func wasSentReturnsFalseForEmptyKey() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()

        // Act
        let result = service.wasSent(key: "")

        // Assert
        #expect(result == false)

        // Cleanup
        cleanupTestData()
    }

    // MARK: - markSent Tests

    @Test("markSent then wasSent returns true")
    func markSentThenWasSentReturnsTrue() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()
        let testKey = "\(Self.testKeyPrefix)test_notification_key"

        // Act
        service.markSent(key: testKey)
        let result = service.wasSent(key: testKey)

        // Assert
        #expect(result == true)

        // Cleanup
        cleanupTestData()
    }

    @Test("markSent persists across service instances")
    func markSentPersistsAcrossInstances() {
        // Arrange
        cleanupTestData()
        let service1 = NotificationPreferencesService()
        let testKey = "\(Self.testKeyPrefix)persist_test_key"

        // Act
        service1.markSent(key: testKey)
        let service2 = NotificationPreferencesService()
        let result = service2.wasSent(key: testKey)

        // Assert
        #expect(result == true)

        // Cleanup
        cleanupTestData()
    }

    @Test("markSent can mark multiple different keys")
    func markSentCanMarkMultipleDifferentKeys() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()
        let key1 = "\(Self.testKeyPrefix)key1"
        let key2 = "\(Self.testKeyPrefix)key2"
        let key3 = "\(Self.testKeyPrefix)key3"

        // Act
        service.markSent(key: key1)
        service.markSent(key: key2)
        service.markSent(key: key3)

        // Assert
        #expect(service.wasSent(key: key1) == true)
        #expect(service.wasSent(key: key2) == true)
        #expect(service.wasSent(key: key3) == true)

        // Cleanup
        cleanupTestData()
    }

    // MARK: - resetAll Tests

    @Test("resetAll clears all sent notifications")
    func resetAllClearsAllSentNotifications() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()
        let key1 = "\(Self.testKeyPrefix)reset_key1"
        let key2 = "\(Self.testKeyPrefix)reset_key2"

        service.markSent(key: key1)
        service.markSent(key: key2)

        // Act
        service.resetAll()

        // Assert
        #expect(service.wasSent(key: key1) == false)
        #expect(service.wasSent(key: key2) == false)

        // Cleanup
        cleanupTestData()
    }

    @Test("resetAll affects new service instances")
    func resetAllAffectsNewServiceInstances() {
        // Arrange
        cleanupTestData()
        let service1 = NotificationPreferencesService()
        let testKey = "\(Self.testKeyPrefix)reset_persist_key"

        service1.markSent(key: testKey)
        service1.resetAll()

        // Act
        let service2 = NotificationPreferencesService()

        // Assert
        #expect(service2.wasSent(key: testKey) == false)

        // Cleanup
        cleanupTestData()
    }

    // MARK: - Threshold Getters/Setters Tests

    @Test("warningThreshold can be set and read back")
    func warningThresholdCanBeSetAndReadBack() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()
        let newThreshold = 75

        // Act
        service.warningThreshold = newThreshold

        // Assert
        #expect(service.warningThreshold == newThreshold)

        // Cleanup
        cleanupTestData()
    }

    @Test("warningThreshold persists across service instances")
    func warningThresholdPersistsAcrossInstances() {
        // Arrange
        cleanupTestData()
        let service1 = NotificationPreferencesService()
        let newThreshold = 85

        // Act
        service1.warningThreshold = newThreshold
        let service2 = NotificationPreferencesService()

        // Assert
        #expect(service2.warningThreshold == newThreshold)

        // Cleanup
        cleanupTestData()
    }

    @Test("criticalThreshold can be set and read back")
    func criticalThresholdCanBeSetAndReadBack() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()
        let newThreshold = 90

        // Act
        service.criticalThreshold = newThreshold

        // Assert
        #expect(service.criticalThreshold == newThreshold)

        // Cleanup
        cleanupTestData()
    }

    @Test("criticalThreshold persists across service instances")
    func criticalThresholdPersistsAcrossInstances() {
        // Arrange
        cleanupTestData()
        let service1 = NotificationPreferencesService()
        let newThreshold = 98

        // Act
        service1.criticalThreshold = newThreshold
        let service2 = NotificationPreferencesService()

        // Assert
        #expect(service2.criticalThreshold == newThreshold)

        // Cleanup
        cleanupTestData()
    }

    // MARK: - isEnabled Tests

    @Test("isEnabled can be toggled")
    func isEnabledCanBeToggled() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()
        let original = service.isEnabled

        // Act
        service.isEnabled = !original
        let toggled = service.isEnabled

        service.isEnabled = original
        let restored = service.isEnabled

        // Assert
        #expect(toggled == !original)
        #expect(restored == original)

        // Cleanup
        cleanupTestData()
    }

    @Test("isEnabled set to false persists")
    func isEnabledSetToFalsePersists() {
        // Arrange
        cleanupTestData()
        let service1 = NotificationPreferencesService()

        // Act
        service1.isEnabled = false
        let service2 = NotificationPreferencesService()

        // Assert
        #expect(service2.isEnabled == false)

        // Cleanup
        cleanupTestData()
    }

    @Test("isEnabled set to true persists")
    func isEnabledSetToTruePersists() {
        // Arrange
        cleanupTestData()
        let service1 = NotificationPreferencesService()

        // Act
        service1.isEnabled = true
        let service2 = NotificationPreferencesService()

        // Assert
        #expect(service2.isEnabled == true)

        // Cleanup
        cleanupTestData()
    }

    // MARK: - Edge Cases Tests

    @Test("setting threshold to 0 works")
    func settingThresholdToZeroWorks() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()

        // Act
        service.warningThreshold = 0
        service.criticalThreshold = 0

        // Assert
        // Note: On next initialization, 0 is treated as "not set" and defaults to 80/95
        // But during runtime, the value should be 0
        #expect(service.warningThreshold == 0)
        #expect(service.criticalThreshold == 0)

        // Cleanup
        cleanupTestData()
    }

    @Test("setting threshold to 100 works")
    func settingThresholdTo100Works() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()

        // Act
        service.warningThreshold = 100
        service.criticalThreshold = 100

        // Assert
        #expect(service.warningThreshold == 100)
        #expect(service.criticalThreshold == 100)

        // Cleanup
        cleanupTestData()
    }

    @Test("marking same key multiple times is idempotent")
    func markingSameKeyMultipleTimesIsIdempotent() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()
        let testKey = "\(Self.testKeyPrefix)idempotent_key"

        // Act
        service.markSent(key: testKey)
        service.markSent(key: testKey)
        service.markSent(key: testKey)

        // Assert
        #expect(service.wasSent(key: testKey) == true)

        // Cleanup
        cleanupTestData()
    }

    // MARK: - Service State Consistency Tests

    @Test("service maintains consistent state across operations")
    func serviceMaintainsConsistentState() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()

        // Act
        service.isEnabled = false
        service.warningThreshold = 70
        service.criticalThreshold = 92
        service.markSent(key: "\(Self.testKeyPrefix)state_key")

        // Assert
        #expect(service.isEnabled == false)
        #expect(service.warningThreshold == 70)
        #expect(service.criticalThreshold == 92)
        #expect(service.wasSent(key: "\(Self.testKeyPrefix)state_key") == true)

        // Cleanup
        cleanupTestData()
    }

    @Test("resetAll does not affect thresholds or isEnabled")
    func resetAllDoesNotAffectThresholdsOrIsEnabled() {
        // Arrange
        cleanupTestData()
        let service = NotificationPreferencesService()

        service.isEnabled = false
        service.warningThreshold = 65
        service.criticalThreshold = 88

        // Act
        service.resetAll()

        // Assert
        #expect(service.isEnabled == false)
        #expect(service.warningThreshold == 65)
        #expect(service.criticalThreshold == 88)

        // Cleanup
        cleanupTestData()
    }
}
