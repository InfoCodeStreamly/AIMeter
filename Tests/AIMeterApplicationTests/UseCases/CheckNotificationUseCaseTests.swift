import Testing
import Foundation
@testable import AIMeterApplication
@testable import AIMeterDomain

/// Tests for CheckNotificationUseCase
@Suite("CheckNotificationUseCase Tests", .serialized)
@MainActor
struct CheckNotificationUseCaseTests {

    // MARK: - Test Cases

    @Test("execute does not send notification when notifications are disabled")
    func executeDoesNotSendWhenDisabled() async {
        let mockNotificationService = MockNotificationService()
        let mockPreferencesService = MockNotificationPreferencesService()
        mockPreferencesService.configure(isEnabled: false)

        let useCase = CheckNotificationUseCase(
            notificationService: mockNotificationService,
            preferencesService: mockPreferencesService
        )

        let usage = UsageEntity(
            type: .session,
            percentage: .clamped(90.0),
            resetTime: ResetTime(Date().addingTimeInterval(3600))
        )

        await useCase.execute(usages: [usage])

        let sendCallCount = await mockNotificationService.sendCallCount
        #expect(sendCallCount == 0)
    }

    @Test("execute does not send notification when usage is below warning threshold")
    func executeDoesNotSendWhenBelowThreshold() async {
        let mockNotificationService = MockNotificationService()
        let mockPreferencesService = MockNotificationPreferencesService()
        mockPreferencesService.configure(
            isEnabled: true,
            warningThreshold: 75,
            criticalThreshold: 90
        )

        let useCase = CheckNotificationUseCase(
            notificationService: mockNotificationService,
            preferencesService: mockPreferencesService
        )

        let usage = UsageEntity(
            type: .session,
            percentage: .clamped(50.0),
            resetTime: ResetTime(Date().addingTimeInterval(3600))
        )

        await useCase.execute(usages: [usage])

        let sendCallCount = await mockNotificationService.sendCallCount
        #expect(sendCallCount == 0)
    }

    @Test("execute sends notification when usage reaches warning threshold")
    func executeSendsNotificationAtWarningThreshold() async {
        let mockNotificationService = MockNotificationService()
        let mockPreferencesService = MockNotificationPreferencesService()
        mockPreferencesService.configure(
            isEnabled: true,
            warningThreshold: 75,
            criticalThreshold: 90
        )

        let useCase = CheckNotificationUseCase(
            notificationService: mockNotificationService,
            preferencesService: mockPreferencesService
        )

        let usage = UsageEntity(
            type: .session,
            percentage: .clamped(75.0),
            resetTime: ResetTime(Date().addingTimeInterval(3600))
        )

        await useCase.execute(usages: [usage])

        let sendCallCount = await mockNotificationService.sendCallCount
        #expect(sendCallCount == 1)

        let lastIdentifier = await mockNotificationService.lastIdentifier
        #expect(lastIdentifier != nil)
    }

    @Test("execute sends both warning and critical notifications when usage exceeds critical threshold")
    func executeSendsBothNotificationsAtCriticalThreshold() async {
        let mockNotificationService = MockNotificationService()
        let mockPreferencesService = MockNotificationPreferencesService()
        mockPreferencesService.configure(
            isEnabled: true,
            warningThreshold: 75,
            criticalThreshold: 90
        )

        let useCase = CheckNotificationUseCase(
            notificationService: mockNotificationService,
            preferencesService: mockPreferencesService
        )

        let usage = UsageEntity(
            type: .session,
            percentage: .clamped(95.0),
            resetTime: ResetTime(Date().addingTimeInterval(3600))
        )

        await useCase.execute(usages: [usage])

        let sendCallCount = await mockNotificationService.sendCallCount
        #expect(sendCallCount == 2)

        let markSentCallCount = mockPreferencesService.markSentCallCount
        #expect(markSentCallCount == 2)
    }

    @Test("execute does not send duplicate notification when already sent")
    func executeDoesNotSendDuplicateNotification() async {
        let mockNotificationService = MockNotificationService()
        let mockPreferencesService = MockNotificationPreferencesService()
        mockPreferencesService.configure(
            isEnabled: true,
            warningThreshold: 75,
            criticalThreshold: 90
        )

        let resetDate = Date().addingTimeInterval(3600)
        let usage = UsageEntity(
            type: .session,
            percentage: .clamped(75.0),
            resetTime: ResetTime(resetDate)
        )

        // Mark as already sent
        let key = "session_75_\(ISO8601DateFormatter().string(from: resetDate))"
        mockPreferencesService.configure(sentKeys: [key])

        let useCase = CheckNotificationUseCase(
            notificationService: mockNotificationService,
            preferencesService: mockPreferencesService
        )

        await useCase.execute(usages: [usage])

        let sendCallCount = await mockNotificationService.sendCallCount
        #expect(sendCallCount == 0)
    }

    @Test("execute does not send notification for empty usages array")
    func executeDoesNotSendForEmptyArray() async {
        let mockNotificationService = MockNotificationService()
        let mockPreferencesService = MockNotificationPreferencesService()
        mockPreferencesService.configure(
            isEnabled: true,
            warningThreshold: 75,
            criticalThreshold: 90
        )

        let useCase = CheckNotificationUseCase(
            notificationService: mockNotificationService,
            preferencesService: mockPreferencesService
        )

        await useCase.execute(usages: [])

        let sendCallCount = await mockNotificationService.sendCallCount
        #expect(sendCallCount == 0)
    }

    @Test("execute checks and notifies for multiple usages")
    func executeChecksMultipleUsages() async {
        let mockNotificationService = MockNotificationService()
        let mockPreferencesService = MockNotificationPreferencesService()
        mockPreferencesService.configure(
            isEnabled: true,
            warningThreshold: 75,
            criticalThreshold: 90
        )

        let useCase = CheckNotificationUseCase(
            notificationService: mockNotificationService,
            preferencesService: mockPreferencesService
        )

        let resetDate = Date().addingTimeInterval(3600)
        let usage1 = UsageEntity(
            type: .session,
            percentage: .clamped(80.0),
            resetTime: ResetTime(resetDate)
        )
        let usage2 = UsageEntity(
            type: .weekly,
            percentage: .clamped(85.0),
            resetTime: ResetTime(resetDate)
        )

        await useCase.execute(usages: [usage1, usage2])

        let sendCallCount = await mockNotificationService.sendCallCount
        #expect(sendCallCount == 2)

        let markSentCallCount = mockPreferencesService.markSentCallCount
        #expect(markSentCallCount == 2)
    }

    @Test("execute uses correct threshold values from preferences")
    func executeUsesCorrectThresholdValues() async {
        let mockNotificationService = MockNotificationService()
        let mockPreferencesService = MockNotificationPreferencesService()
        mockPreferencesService.configure(
            isEnabled: true,
            warningThreshold: 60,
            criticalThreshold: 80
        )

        let useCase = CheckNotificationUseCase(
            notificationService: mockNotificationService,
            preferencesService: mockPreferencesService
        )

        let usage = UsageEntity(
            type: .session,
            percentage: .clamped(65.0),
            resetTime: ResetTime(Date().addingTimeInterval(3600))
        )

        await useCase.execute(usages: [usage])

        let sendCallCount = await mockNotificationService.sendCallCount
        #expect(sendCallCount == 1)
    }

    @Test("execute generates unique keys per usage type and reset date")
    func executeGeneratesUniqueKeys() async {
        let mockNotificationService = MockNotificationService()
        let mockPreferencesService = MockNotificationPreferencesService()
        mockPreferencesService.configure(
            isEnabled: true,
            warningThreshold: 75,
            criticalThreshold: 90
        )

        let resetDate1 = Date().addingTimeInterval(3600)
        let resetDate2 = Date().addingTimeInterval(7200)

        let usage1 = UsageEntity(
            type: .session,
            percentage: .clamped(80.0),
            resetTime: ResetTime(resetDate1)
        )
        let usage2 = UsageEntity(
            type: .session,
            percentage: .clamped(80.0),
            resetTime: ResetTime(resetDate2)
        )

        let useCase = CheckNotificationUseCase(
            notificationService: mockNotificationService,
            preferencesService: mockPreferencesService
        )

        await useCase.execute(usages: [usage1, usage2])

        let sendCallCount = await mockNotificationService.sendCallCount
        #expect(sendCallCount == 2)

        let markedKeys = mockPreferencesService.markedKeys
        #expect(markedKeys.count == 2)
        #expect(markedKeys[0] != markedKeys[1])
    }
}

// MARK: - Mock Implementations

actor MockNotificationService: NotificationServiceProtocol {
    private(set) var sendCallCount = 0
    private(set) var lastTitle: String?
    private(set) var lastBody: String?
    private(set) var lastIdentifier: String?

    func requestPermission() async -> Bool { true }

    func isPermissionGranted() async -> Bool { true }

    func send(title: String, body: String, identifier: String) async {
        sendCallCount += 1
        lastTitle = title
        lastBody = body
        lastIdentifier = identifier
    }

    func removePending(identifiers: [String]) async {}

    func removeDelivered(identifiers: [String]) async {}
}

@MainActor
final class MockNotificationPreferencesService: NotificationPreferencesProtocol {
    var isEnabled: Bool = false
    var warningThreshold: Int = 75
    var criticalThreshold: Int = 90

    private var sentKeys: Set<String> = []
    private(set) var markSentCallCount = 0
    private(set) var markedKeys: [String] = []

    func configure(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func configure(isEnabled: Bool, warningThreshold: Int, criticalThreshold: Int) {
        self.isEnabled = isEnabled
        self.warningThreshold = warningThreshold
        self.criticalThreshold = criticalThreshold
    }

    func configure(sentKeys: Set<String>) {
        self.sentKeys = sentKeys
    }

    func wasSent(key: String) -> Bool {
        return sentKeys.contains(key)
    }

    func markSent(key: String) {
        markSentCallCount += 1
        markedKeys.append(key)
        sentKeys.insert(key)
    }

    func clearExpired() {}

    func resetAll() {
        sentKeys.removeAll()
        markSentCallCount = 0
        markedKeys.removeAll()
    }
}
