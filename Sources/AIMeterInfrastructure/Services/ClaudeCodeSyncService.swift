import Foundation
import OSLog
import AIMeterDomain
import AIMeterApplication

/// Reads Claude Code CLI credentials from system Keychain (Infrastructure implementation)
public actor ClaudeCodeSyncService: ClaudeCodeSyncServiceProtocol {
    private nonisolated let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "claude-sync")
    private let keychainService = "Claude Code-credentials"

    // Throttle: cache keychain reads for lightweight checks
    private var lastKeychainReadAt: Date?
    private var cachedJSON: String?
    private let keychainReadMinInterval: TimeInterval = 60

    public init() {}

    // MARK: - Public API

    /// Checks if Claude Code credentials exist in system Keychain
    public func hasCredentials() async -> Bool {
        do {
            let result = try await readCredentialsJSONCached() != nil
            logger.debug("hasCredentials: \(result)")
            return result
        } catch {
            logger.debug("hasCredentials: false (error: \(error.localizedDescription))")
            return false
        }
    }

    /// Extracts session key from Claude Code credentials
    public func extractSessionKey() async throws -> String {

        guard let json = try await readCredentialsJSONCached() else {
            throw SyncError.noCredentialsFound
        }


        guard let data = json.data(using: .utf8) else {
            throw SyncError.invalidCredentialsFormat
        }

        guard let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SyncError.invalidCredentialsFormat
        }


        guard let oauth = parsed["claudeAiOauth"] as? [String: Any] else {
            throw SyncError.invalidCredentialsFormat
        }


        guard let accessToken = oauth["accessToken"] as? String else {
            throw SyncError.invalidCredentialsFormat
        }

        guard !accessToken.isEmpty else {
            throw SyncError.emptyAccessToken
        }

        return accessToken
    }

    /// Gets subscription info from Claude Code credentials
    public func getSubscriptionInfo() async -> (type: String, email: String?)? {
        guard let json = try? await readCredentialsJSONCached(),
              let data = json.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = parsed["claudeAiOauth"] as? [String: Any] else {
            return nil
        }

        let subType = oauth["subscriptionType"] as? String ?? "unknown"
        let email = oauth["email"] as? String

        return (subType, email)
    }

    /// Extracts full OAuth credentials from Claude Code keychain
    public func extractOAuthCredentials() async throws -> OAuthCredentials {
        logger.info("extractOAuthCredentials: reading from Claude Code keychain")

        guard let json = try await readCredentialsJSON() else {
            logger.error("extractOAuthCredentials: no credentials found in keychain")
            throw SyncError.noCredentialsFound
        }

        guard let data = json.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("extractOAuthCredentials: invalid JSON format")
            throw SyncError.invalidCredentialsFormat
        }

        do {
            let credentials = try OAuthCredentials.fromClaudeCodeJSON(parsed)
            logger.info("extractOAuthCredentials: success (expired=\(credentials.isExpired))")
            return credentials
        } catch {
            logger.error("extractOAuthCredentials: failed to parse: \(error.localizedDescription)")
            throw SyncError.invalidCredentialsFormat
        }
    }

    /// Updates Claude Code keychain with refreshed credentials
    public func updateCredentials(_ credentials: OAuthCredentials) async throws {

        let json = credentials.toClaudeCodeJSON()

        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw SyncError.invalidCredentialsFormat
        }

        try await writeCredentialsJSON(jsonString)
        invalidateCache()
    }

    // MARK: - Private

    /// Waits for process to exit with timeout, kills if hung
    /// - Returns: true if process exited normally, false if timed out (process killed)
    internal nonisolated func waitForProcess(_ process: Process, timeout: TimeInterval = 1.5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        // Poll every 20ms until timeout
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.02)
        }

        guard process.isRunning else { return true }

        // Timeout — SIGTERM
        process.terminate()

        // Wait up to 400ms for graceful shutdown (poll every 50ms)
        let killDeadline = Date().addingTimeInterval(0.4)
        while process.isRunning && Date() < killDeadline {
            Thread.sleep(forTimeInterval: 0.05)
        }

        // Still running — SIGKILL
        if process.isRunning {
            kill(process.processIdentifier, SIGKILL)
        }

        return false
    }

    /// Reads raw JSON with throttle (returns cache if < 60s since last read)
    private func readCredentialsJSONCached() async throws -> String? {
        if let lastRead = lastKeychainReadAt,
           Date().timeIntervalSince(lastRead) < keychainReadMinInterval,
           let cached = cachedJSON {
            logger.debug("readCredentialsJSONCached: returning cached (\(Int(Date().timeIntervalSince(lastRead)))s ago)")
            return cached
        }
        let json = try await readCredentialsJSON()
        lastKeychainReadAt = Date()
        cachedJSON = json
        return json
    }

    /// Invalidates the keychain read cache (call after writes)
    private func invalidateCache() {
        cachedJSON = nil
        lastKeychainReadAt = nil
    }

    /// Reads raw JSON from system Keychain (always fresh, no cache)
    private func readCredentialsJSON() async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try self.readFromKeychain()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Writes JSON to system Keychain
    private func writeCredentialsJSON(_ json: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.writeToKeychain(json)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Reads credentials from Keychain using /usr/bin/security CLI
    /// (CLI tool is in ACL — reads silently without password dialog, unlike SecItemCopyMatching)
    private nonisolated func readFromKeychain() throws -> String? {
        let username = NSUserName()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", keychainService, "-a", username, "-w"]

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()

        // Read pipe data concurrently to avoid deadlock (pipe buffer = 64KB)
        let readGroup = DispatchGroup()
        var capturedOut = Data()
        var capturedErr = Data()
        readGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            capturedOut = outPipe.fileHandleForReading.readDataToEndOfFile()
            readGroup.leave()
        }
        readGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            capturedErr = errPipe.fileHandleForReading.readDataToEndOfFile()
            readGroup.leave()
        }

        guard waitForProcess(process) else {
            readGroup.wait()
            logger.error("readFromKeychain: security CLI timed out")
            throw SyncError.keychainAccessFailed(status: -1)
        }
        readGroup.wait()

        guard process.terminationStatus == 0 else {
            let errStr = String(data: capturedErr, encoding: .utf8) ?? ""
            if errStr.contains("could not be found") || errStr.contains("SecKeychainSearchCopyNext") {
                logger.info("readFromKeychain: item not found")
                return nil
            }
            logger.error("readFromKeychain: security CLI failed (exit=\(process.terminationStatus)): \(errStr)")
            throw SyncError.keychainAccessFailed(status: OSStatus(process.terminationStatus))
        }

        let data = capturedOut

        guard data.count > 1 else {
            logger.error("readFromKeychain: empty output from security CLI")
            throw SyncError.invalidCredentialsFormat
        }

        // Strip trailing newline from CLI output
        let trimmedData: Data
        if let last = data.last, last == 0x0a { // '\n'
            trimmedData = data.dropLast()
        } else {
            trimmedData = data
        }

        guard trimmedData.count > 0 else {
            throw SyncError.invalidCredentialsFormat
        }

        let firstByte = trimmedData[trimmedData.startIndex]

        // Detect format based on first byte
        let jsonData: Data
        if firstByte == 0x7b { // '{' - already valid JSON
            jsonData = trimmedData
        } else if firstByte == 0x07 { // Old format with prefix byte
            jsonData = Data(trimmedData.dropFirst())
        } else {
            throw SyncError.invalidCredentialsFormat
        }

        guard let content = String(data: jsonData, encoding: .utf8) else {
            throw SyncError.invalidCredentialsFormat
        }

        // For old format, wrap in braces; for new format, use as-is
        let json: String
        if firstByte == 0x7b {
            json = content
        } else {
            json = "{" + content + "}"
        }

        logger.debug("readFromKeychain: got \(json.count) chars via security CLI")
        return json
    }

    /// Writes credentials to Keychain using /usr/bin/security CLI
    /// (CLI tool is in ACL — writes silently without password dialog)
    private nonisolated func writeToKeychain(_ json: String) throws {
        let username = NSUserName()

        // Delete existing item first (ignore errors if not found)
        let deleteProcess = Process()
        deleteProcess.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        deleteProcess.arguments = ["delete-generic-password", "-s", keychainService, "-a", username]
        let delOutPipe = Pipe()
        let delErrPipe = Pipe()
        deleteProcess.standardOutput = delOutPipe
        deleteProcess.standardError = delErrPipe
        try? deleteProcess.run()

        // Read pipes concurrently for delete process
        let delGroup = DispatchGroup()
        delGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            _ = delOutPipe.fileHandleForReading.readDataToEndOfFile()
            delGroup.leave()
        }
        delGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            _ = delErrPipe.fileHandleForReading.readDataToEndOfFile()
            delGroup.leave()
        }
        _ = waitForProcess(deleteProcess, timeout: 3)
        delGroup.wait()

        // Add new item
        let addProcess = Process()
        addProcess.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        addProcess.arguments = ["add-generic-password", "-s", keychainService, "-a", username, "-w", json]
        let addOutPipe = Pipe()
        let addErrPipe = Pipe()
        addProcess.standardOutput = addOutPipe
        addProcess.standardError = addErrPipe

        try addProcess.run()

        // Read pipes concurrently for add process
        let addGroup = DispatchGroup()
        var addErrData = Data()
        addGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            _ = addOutPipe.fileHandleForReading.readDataToEndOfFile()
            addGroup.leave()
        }
        addGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            addErrData = addErrPipe.fileHandleForReading.readDataToEndOfFile()
            addGroup.leave()
        }

        guard waitForProcess(addProcess) else {
            addGroup.wait()
            logger.error("writeToKeychain: security CLI timed out")
            throw SyncError.keychainWriteFailed(status: -1)
        }
        addGroup.wait()

        guard addProcess.terminationStatus == 0 else {
            let errStr = String(data: addErrData, encoding: .utf8) ?? ""
            logger.error("writeToKeychain: security CLI failed (exit=\(addProcess.terminationStatus)): \(errStr)")
            throw SyncError.keychainWriteFailed(status: OSStatus(addProcess.terminationStatus))
        }

        logger.debug("writeToKeychain: written via security CLI")
    }
}

