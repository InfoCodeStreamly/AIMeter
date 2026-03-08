import Foundation

/// Protocol for monitoring network connectivity changes
public protocol NetworkMonitorProtocol: Sendable {
    func isConnected() async -> Bool
    func startMonitoring(onChange: @Sendable @escaping (Bool) -> Void) async
    func stopMonitoring() async
}
