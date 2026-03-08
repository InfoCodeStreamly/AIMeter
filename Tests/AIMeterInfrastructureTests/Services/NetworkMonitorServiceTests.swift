import Testing
import Foundation
@testable import AIMeterInfrastructure

@Suite("NetworkMonitorService Tests")
struct NetworkMonitorServiceTests {

    @Test("isConnected returns true by default")
    func defaultConnected() async {
        let service = NetworkMonitorService()
        let connected = await service.isConnected()
        #expect(connected == true)
    }

    @Test("startMonitoring and stopMonitoring do not crash")
    func startStopDoesNotCrash() async throws {
        let service = NetworkMonitorService()
        await service.startMonitoring { _ in }
        try await Task.sleep(for: .milliseconds(50))
        await service.stopMonitoring()
    }
}
