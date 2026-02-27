import Foundation
import AIMeterDomain
import AIMeterApplication
import Security

/// Reads Claude Code CLI credentials from system Keychain (Infrastructure implementation)
public actor ClaudeCodeSyncService: ClaudeCodeSyncServiceProtocol {
    private let keychainService = "Claude Code-credentials"

    public init() {}

    // MARK: - Public API

    /// Checks if Claude Code credentials exist in system Keychain
    public func hasCredentials() async -> Bool {
        do {
            return try await readCredentialsJSON() != nil
        } catch {
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

        guard let json = try await readCredentialsJSON() else {
            throw SyncError.noCredentialsFound
        }

        guard let data = json.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SyncError.invalidCredentialsFormat
        }

        do {
            let credentials = try OAuthCredentials.fromClaudeCodeJSON(parsed)
            return credentials
        } catch {
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
                throw SyncError.invalidCredentialsFormat
            }


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
            return nil

        default:
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

