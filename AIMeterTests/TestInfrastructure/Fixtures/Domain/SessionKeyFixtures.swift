import Foundation
@testable import AIMeter

enum SessionKeyFixtures {

    // MARK: - Base Values (SSOT)

    /// Session key (sk-ant-sid...) - for browser authentication
    static let validRawKey = "sk-ant-sid01-valid-session-key-for-testing-purposes"

    /// OAuth token (sk-ant-oat...) - for Claude Code CLI authentication
    static let validOAuthToken = "sk-ant-oat01-valid-oauth-token-for-testing-purposes"

    static let invalidRawKey = "invalid-key"
    static let emptyRawKey = ""

    // MARK: - SessionKey Objects

    /// Session key for browser auth
    static var valid: SessionKey {
        try! SessionKey.create(validRawKey)
    }

    /// OAuth token for Claude Code auth
    static var validOAuth: SessionKey {
        try! SessionKey.create(validOAuthToken)
    }
}
