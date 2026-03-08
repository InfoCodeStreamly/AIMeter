import Testing
import Foundation
@testable import AIMeterInfrastructure

@Suite("ClaudeCodeSyncService Timeout Tests")
struct ClaudeCodeSyncServiceTimeoutTests {

    @Test("waitForProcess returns true for fast process")
    func fastProcess() async throws {
        let service = ClaudeCodeSyncService()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/echo")
        process.arguments = ["hello"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try process.run()

        let result = await service.waitForProcess(process, timeout: 1.5)
        #expect(result == true)
    }

    @Test("waitForProcess returns false for slow process")
    func slowProcess() async throws {
        let service = ClaudeCodeSyncService()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sleep")
        process.arguments = ["10"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try process.run()

        let result = await service.waitForProcess(process, timeout: 0.1)
        #expect(result == false)
    }

    @Test("waitForProcess kills hung process")
    func killsHungProcess() async throws {
        let service = ClaudeCodeSyncService()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sleep")
        process.arguments = ["10"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try process.run()

        _ = await service.waitForProcess(process, timeout: 0.1)
        try await Task.sleep(for: .milliseconds(100))
        #expect(!process.isRunning)
    }
}
