import Foundation
import OSLog
import Security

/// Reads Claude Code CLI credentials from system Keychain
actor ClaudeCodeSyncService {

    /// Keychain service name used by Claude Code
    private let keychainService = "Claude Code-credentials"

    private let logger = Logger.sync

    // MARK: - Public API

    /// Checks if Claude Code credentials exist in system Keychain
    func hasCredentials() async -> Bool {
        do {
            return try await readCredentialsJSON() != nil
        } catch {
            return false
        }
    }

    /// Extracts session key from Claude Code credentials
    /// - Returns: Session key if found and valid
    func extractSessionKey() async throws -> String {
        logger.info("Extracting session key from Claude Code credentials")

        guard let json = try await readCredentialsJSON() else {
            logger.error("No credentials found in Keychain")
            throw ClaudeCodeSyncError.noCredentialsFound
        }

        logger.debug("Raw JSON length: \(json.count) characters")

        guard let data = json.data(using: .utf8) else {
            logger.error("Failed to convert JSON string to UTF8 data")
            throw ClaudeCodeSyncError.invalidCredentialsFormat
        }

        guard let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("Failed to parse JSON. First 200 chars: \(String(json.prefix(200)), privacy: .private)")
            throw ClaudeCodeSyncError.invalidCredentialsFormat
        }

        logger.debugJSONStructure(parsed, message: "Parsed credentials")

        guard let oauth = parsed["claudeAiOauth"] as? [String: Any] else {
            logger.error("Missing 'claudeAiOauth' key. Available keys: \(parsed.keys.joined(separator: ", "))")
            throw ClaudeCodeSyncError.invalidCredentialsFormat
        }

        logger.debug("Found claudeAiOauth with keys: \(oauth.keys.joined(separator: ", "))")

        guard let accessToken = oauth["accessToken"] as? String else {
            logger.error("Missing 'accessToken' in claudeAiOauth. Available keys: \(oauth.keys.joined(separator: ", "))")
            throw ClaudeCodeSyncError.invalidCredentialsFormat
        }

        guard !accessToken.isEmpty else {
            logger.error("accessToken is empty")
            throw ClaudeCodeSyncError.emptyAccessToken
        }

        logger.info("Successfully extracted session key (length: \(accessToken.count))")
        return accessToken
    }

    /// Gets subscription info from Claude Code credentials
    func getSubscriptionInfo() async -> (type: String, email: String?)? {
        guard let json = try? await readCredentialsJSON(),
              let data = json.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = parsed["claudeAiOauth"] as? [String: Any] else {
            return nil
        }

        let subType = oauth["subscriptionType"] as? String ?? "unknown"
        let email = oauth["email"] as? String

        return (subType, email)
    }

    // MARK: - Private

    /// Reads raw JSON from system Keychain
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

    /// Reads credentials from Keychain using native Security framework
    private nonisolated func readFromKeychain() throws -> String? {
        let logger = Logger.sync

        let username = NSUserName()
        logger.debug("Reading keychain for service: '\(self.keychainService)', account: '\(username)'")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: username,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        logger.debug("SecItemCopyMatching status: \(status) (\(SecCopyErrorMessageString(status, nil) as String? ?? "unknown"))")

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                logger.error("Result is not Data type")
                throw ClaudeCodeSyncError.invalidCredentialsFormat
            }

            logger.debug("Raw data size: \(data.count) bytes")
            logger.debugData(data, message: "First bytes")

            // Data format: first byte is 0x07, then JSON content without outer braces
            // e.g., \x07"claudeAiOauth":{...}
            guard data.count > 1 else {
                logger.error("Data too short: \(data.count) bytes")
                throw ClaudeCodeSyncError.invalidCredentialsFormat
            }

            let firstByte = data[0]
            logger.debug("First byte: 0x\(String(format: "%02x", firstByte))")

            // Detect format based on first byte
            let jsonData: Data
            if firstByte == 0x7b { // '{' - already valid JSON
                logger.debug("Detected new format: raw JSON")
                jsonData = data
            } else if firstByte == 0x07 { // Old format with prefix byte
                logger.debug("Detected old format: prefix byte + JSON without braces")
                jsonData = Data(data.dropFirst())
            } else {
                logger.error("Unknown format, first byte: 0x\(String(format: "%02x", firstByte))")
                throw ClaudeCodeSyncError.invalidCredentialsFormat
            }

            guard let content = String(data: jsonData, encoding: .utf8) else {
                logger.error("Failed to decode as UTF8")
                if let latin1 = String(data: jsonData, encoding: .isoLatin1) {
                    logger.debug("As Latin1 (first 100): \(String(latin1.prefix(100)), privacy: .private)")
                }
                throw ClaudeCodeSyncError.invalidCredentialsFormat
            }

            logger.debug("Decoded content length: \(content.count) chars")
            logger.debug("Content starts with: \(String(content.prefix(50)), privacy: .private)")

            // For old format, wrap in braces; for new format, use as-is
            let json: String
            if firstByte == 0x7b {
                json = content
            } else {
                json = "{" + content + "}"
            }
            logger.debug("Final JSON length: \(json.count) chars")

            return json

        case errSecItemNotFound:
            logger.info("No credentials found in Keychain")
            return nil

        default:
            logger.error("Keychain error: \(status)")
            throw ClaudeCodeSyncError.keychainAccessFailed(status: status)
        }
    }
}

// MARK: - Errors

enum ClaudeCodeSyncError: LocalizedError {
    case noCredentialsFound
    case invalidCredentialsFormat
    case emptyAccessToken
    case keychainAccessFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .noCredentialsFound:
            return "Claude Code not logged in. Please run 'claude' in terminal and login first."
        case .invalidCredentialsFormat:
            return "Claude Code credentials are corrupted."
        case .emptyAccessToken:
            return "Claude Code session expired. Please re-login in terminal."
        case .keychainAccessFailed(let status):
            return "Cannot access Keychain (error \(status)). Check System Preferences → Security."
        }
    }
}
