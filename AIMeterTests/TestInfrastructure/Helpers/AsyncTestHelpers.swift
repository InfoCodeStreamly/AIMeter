import Foundation
import Testing

// MARK: - Async Test Helpers

func waitFor(
    timeout: TimeInterval = TestConstants.defaultTimeout,
    condition: @escaping () async -> Bool
) async throws {
    let start = Date()
    while Date().timeIntervalSince(start) < timeout {
        if await condition() {
            return
        }
        try await Task.sleep(for: .milliseconds(100))
    }
    Issue.record("Timeout waiting for condition")
}

func expectEventually(
    timeout: TimeInterval = TestConstants.defaultTimeout,
    _ condition: @escaping () async -> Bool
) async {
    do {
        try await waitFor(timeout: timeout, condition: condition)
    } catch {
        Issue.record("Condition not met within timeout")
    }
}
