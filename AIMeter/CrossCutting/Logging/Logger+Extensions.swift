import OSLog

// MARK: - Build Configuration

/// Whether verbose logging is enabled (only in DEBUG builds)
#if DEBUG
let isLoggingEnabled = true
#else
let isLoggingEnabled = false
#endif

// MARK: - Signpost for Performance Tracking

/// Signpost log for Instruments profiling
let performanceLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.codestreamly.AIMeter", category: .pointsOfInterest)

/// Centralized logging for AIMeter app
/// Usage: Logger.sync.debug("Message")
///
/// View logs in Console.app:
/// - Filter by subsystem: com.codestreamly.AIMeter
/// - Filter by category: sync, api, keychain, ui, etc.
extension Logger {

    // MARK: - Subsystem

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.codestreamly.AIMeter"

    // MARK: - Categories

    /// Claude Code sync operations (keychain reading, credential parsing)
    static let sync = Logger(subsystem: subsystem, category: "sync")

    /// API calls to Claude
    static let api = Logger(subsystem: subsystem, category: "api")

    /// Keychain operations
    static let keychain = Logger(subsystem: subsystem, category: "keychain")

    /// UI/ViewModel events
    static let ui = Logger(subsystem: subsystem, category: "ui")

    /// General app lifecycle
    static let app = Logger(subsystem: subsystem, category: "app")

    /// Launch at login operations
    static let launchAtLogin = Logger(subsystem: subsystem, category: "launchAtLogin")

    /// Notifications operations
    static let notifications = Logger(subsystem: subsystem, category: "notifications")

    /// Update check operations
    static let updates = Logger(subsystem: subsystem, category: "updates")

    /// OAuth token operations
    static let oauth = Logger(subsystem: subsystem, category: "oauth")

    /// Settings screen operations
    static let settings = Logger(subsystem: subsystem, category: "settings")

    /// Voice input operations
    static let voice = Logger(subsystem: subsystem, category: "voice")
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

    /// Logs operation start with signpost
    func operation(_ name: StaticString) -> LogOperation {
        LogOperation(logger: self, name: name)
    }
}

// MARK: - Log Operation Helper

/// Helper for logging operation duration
struct LogOperation {
    private let logger: Logger
    private let name: StaticString
    private let startTime: ContinuousClock.Instant

    init(logger: Logger, name: StaticString) {
        self.logger = logger
        self.name = name
        self.startTime = ContinuousClock.now
        logger.debug("▶ \(name) started")
    }

    func success(_ message: String = "") {
        let duration = ContinuousClock.now - startTime
        let ms = duration.components.seconds * 1000 + duration.components.attoseconds / 1_000_000_000_000_000
        if message.isEmpty {
            logger.info("✓ \(self.name) completed in \(ms)ms")
        } else {
            logger.info("✓ \(self.name) completed in \(ms)ms: \(message)")
        }
    }

    func failure(_ error: Error) {
        let duration = ContinuousClock.now - startTime
        let ms = duration.components.seconds * 1000 + duration.components.attoseconds / 1_000_000_000_000_000
        logger.error("✗ \(self.name) failed in \(ms)ms: \(error.localizedDescription)")
    }
}

// MARK: - Debug-Only Logging

extension Logger {
    /// Logs only in DEBUG builds - completely compiled out in Release
    func debugOnly(_ message: String) {
        #if DEBUG
        self.debug("\(message)")
        #endif
    }

    /// Logs info only in DEBUG builds
    func infoOnly(_ message: String) {
        #if DEBUG
        self.info("\(message)")
        #endif
    }
}
