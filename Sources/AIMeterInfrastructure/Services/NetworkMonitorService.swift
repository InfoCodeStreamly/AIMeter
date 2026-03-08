import Foundation
import Network
import os
import AIMeterApplication

/// Monitors network connectivity using NWPathMonitor
public final class NetworkMonitorService: NetworkMonitorProtocol, @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.codestreamly.AIMeter.networkMonitor")
    private let _isConnected = OSAllocatedUnfairLock(initialState: true)

    public init() {}

    public func isConnected() async -> Bool {
        _isConnected.withLock { $0 }
    }

    public func startMonitoring(onChange: @Sendable @escaping (Bool) -> Void) async {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            let changed = self._isConnected.withLock { current -> Bool in
                let changed = current != connected
                current = connected
                return changed
            }
            if changed {
                onChange(connected)
            }
        }
        monitor.start(queue: queue)
    }

    public func stopMonitoring() async {
        monitor.cancel()
    }
}
