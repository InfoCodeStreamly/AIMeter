import OSLog

/// Centralized logging for AIMeter app
/// Usage: Logger.sync.debug("Message")
///
/// View logs in Console.app:
/// - Filter by subsystem: com.codestreamly.AIMeter
/// - Filter by category: sync, api, keychain, ui, etc.
extension Logger {

    // MARK: - Subsystem

    private nonisolated(unsafe) static let subsystem = Bundle.main.bundleIdentifier ?? "com.codestreamly.AIMeter"

    // MARK: - Categories

    /// Claude Code sync operations (keychain reading, credential parsing)
    nonisolated(unsafe) static let sync = Logger(subsystem: subsystem, category: "sync")

    /// API calls to Claude
    nonisolated(unsafe) static let api = Logger(subsystem: subsystem, category: "api")

    /// Keychain operations
    nonisolated(unsafe) static let keychain = Logger(subsystem: subsystem, category: "keychain")

    /// UI/ViewModel events
    nonisolated(unsafe) static let ui = Logger(subsystem: subsystem, category: "ui")

    /// General app lifecycle
    nonisolated(unsafe) static let app = Logger(subsystem: subsystem, category: "app")

    /// Launch at login operations
    nonisolated(unsafe) static let launchAtLogin = Logger(subsystem: subsystem, category: "launchAtLogin")

    /// Notifications operations
    nonisolated(unsafe) static let notifications = Logger(subsystem: subsystem, category: "notifications")

    /// Update check operations
    nonisolated(unsafe) static let updates = Logger(subsystem: subsystem, category: "updates")
}

// MARK: - Convenience for Data Debugging

extension Logger {

    /// Logs data as hex string (useful for debugging binary data)
    /// Privacy: .private - won't appear in release logs
    func debugData(_ data: Data, message: String) {
        let hex = data.prefix(100).map { String(format: "%02x", $0) }.joined(separator: " ")
        let truncated = data.count > 100 ? "... (\(data.count) bytes total)" : ""
        self.debug("\(message): \(hex, privacy: .private)\(truncated)")
    }

    /// Logs JSON structure (keys only, no values for privacy)
    func debugJSONStructure(_ json: [String: Any], message: String) {
        func extractKeys(_ dict: [String: Any], prefix: String = "") -> [String] {
            var keys: [String] = []
            for (key, value) in dict {
                let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"
                keys.append(fullKey)
                if let nested = value as? [String: Any] {
                    keys.append(contentsOf: extractKeys(nested, prefix: fullKey))
                }
            }
            return keys
        }
        let structure = extractKeys(json).sorted().joined(separator: ", ")
        self.debug("\(message) keys: \(structure)")
    }
}
