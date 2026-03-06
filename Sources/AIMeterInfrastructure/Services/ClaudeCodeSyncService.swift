import Foundation
import OSLog
import AIMeterDomain
import AIMeterApplication
import Security

/// Reads Claude Code CLI credentials from system Keychain (Infrastructure implementation)
public actor ClaudeCodeSyncService: ClaudeCodeSyncServiceProtocol {
    private nonisolated let logger = Logger(subsystem: "com.codestreamly.AIMeter", category: "claude-sync")
    private let keychainService = "Claude Code-credentials"

    public init() {}

    // MARK: - Public API

    /// Checks if Claude Code credentials exist in system Keychain
    public func hasCredentials() async -> Bool {
        do {
            let result = try await readCredentialsJSON() != nil
            logger.debug("hasCredentials: \(result)")
            return result
        } catch {
            logger.debug("hasCredentials: false (error: \(error.localizedDescription))")
            return false
        }
    }

    /// Extracts session key from Claude Code credentials
    public func extractSessionKey() async throws -> String {

        guard let json = try await readCredentialsJSON() else {
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

    /// Reads credentials from Keychain using native Security framework
    private nonisolated func readFromKeychain() throws -> String? {
        let username = NSUserName()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: username,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)


        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                logger.error("readFromKeychain: result is not Data")
                throw SyncError.invalidCredentialsFormat
            }
            logger.debug("readFromKeychain: got \(data.count) bytes")


            // Data format: first byte is 0x07, then JSON content without outer braces
            // e.g., \x07"claudeAiOauth":{...}
            guard data.count > 1 else {
                throw SyncError.invalidCredentialsFormat
            }

            let firstByte = data[0]

            // Detect format based on first byte
            let jsonData: Data
            if firstByte == 0x7b { // '{' - already valid JSON
                jsonData = data
            } else if firstByte == 0x07 { // Old format with prefix byte
                jsonData = Data(data.dropFirst())
            } else {
                throw SyncError.invalidCredentialsFormat
            }

            guard let content = String(data: jsonData, encoding: .utf8) else {
                if let latin1 = String(data: jsonData, encoding: .isoLatin1) {
                }
                throw SyncError.invalidCredentialsFormat
            }


            // For old format, wrap in braces; for new format, use as-is
            let json: String
            if firstByte == 0x7b {
                json = content
            } else {
                json = "{" + content + "}"
            }

            return json

        case errSecItemNotFound:
            logger.info("readFromKeychain: item not found")
            return nil

        case errSecInteractionNotAllowed:
            logger.warning("readFromKeychain: interaction not allowed (keychain locked?)")
            throw SyncError.keychainAccessFailed(status: status)

        default:
            logger.error("readFromKeychain: failed with OSStatus=\(status)")
            throw SyncError.keychainAccessFailed(status: status)
        }
    }

    /// Writes credentials to Keychain using native Security framework
    private nonisolated func writeToKeychain(_ json: String) throws {
        guard let data = json.data(using: .utf8) else {
            throw SyncError.invalidCredentialsFormat
        }

        let username = NSUserName()

        // First, try to update existing item
        // Use kSecUseAuthenticationUISkip to avoid password dialog
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: username,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            // Item doesn't exist, create it
            var newItem = query
            newItem[kSecValueData as String] = data

            status = SecItemAdd(newItem as CFDictionary, nil)
        }

        // Accept both success and interaction-not-allowed (skip dialog case)
        guard status == errSecSuccess || status == errSecInteractionNotAllowed else {
            throw SyncError.keychainWriteFailed(status: status)
        }

    }
}

