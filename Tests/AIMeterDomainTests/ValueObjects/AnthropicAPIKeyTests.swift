import Testing
@testable import AIMeterDomain

/// Tests for AnthropicAPIKey value object, validating format rules and masked display.
@Suite("AnthropicAPIKey")
struct AnthropicAPIKeyTests {

    // MARK: - Valid Key Tests

    @Test("create accepts valid API key with correct prefix")
    func createAcceptsValidKey() throws {
        let key = try AnthropicAPIKey.create("sk-ant-api03-abc123def456789")
        #expect(key.value == "sk-ant-api03-abc123def456789")
    }

    @Test("create accepts valid key with longer value")
    func createAcceptsLongKey() throws {
        let key = try AnthropicAPIKey.create("sk-ant-api03-abcdefghijklmnopqrstuvwxyz0123456789")
        #expect(key.value == "sk-ant-api03-abcdefghijklmnopqrstuvwxyz0123456789")
    }

    @Test("create trims leading and trailing whitespace")
    func createTrimsWhitespace() throws {
        let key = try AnthropicAPIKey.create("  sk-ant-api03-abc123def456789  ")
        #expect(key.value == "sk-ant-api03-abc123def456789")
    }

    @Test("create trims newlines")
    func createTrimsNewlines() throws {
        let key = try AnthropicAPIKey.create("\nsk-ant-api03-abc123def456789\n")
        #expect(key.value == "sk-ant-api03-abc123def456789")
    }

    // MARK: - Invalid Prefix Tests

    @Test("create throws invalidAPIKeyFormat for admin key prefix sk-ant-admin")
    func createThrowsForAdminPrefix() {
        #expect(throws: DomainError.invalidAPIKeyFormat) {
            try AnthropicAPIKey.create("sk-ant-admin-abcdefghijklmnop")
        }
    }

    @Test("create throws invalidAPIKeyFormat for OAuth token prefix sk-ant-oat01")
    func createThrowsForOAuthPrefix() {
        #expect(throws: DomainError.invalidAPIKeyFormat) {
            try AnthropicAPIKey.create("sk-ant-oat01-abcdefghijklmnop")
        }
    }

    @Test("create throws invalidAPIKeyFormat for completely wrong prefix")
    func createThrowsForWrongPrefix() {
        #expect(throws: DomainError.invalidAPIKeyFormat) {
            try AnthropicAPIKey.create("Bearer sk-ant-api03-abcdefghijklm")
        }
    }

    @Test("create throws invalidAPIKeyFormat for key without sk-ant prefix")
    func createThrowsForNoSKANTPrefix() {
        #expect(throws: DomainError.invalidAPIKeyFormat) {
            try AnthropicAPIKey.create("api03-abcdefghijklmnopqrstuvwxyz")
        }
    }

    // MARK: - Empty Tests

    @Test("create throws invalidAPIKeyFormat for empty string")
    func createThrowsForEmpty() {
        #expect(throws: DomainError.invalidAPIKeyFormat) {
            try AnthropicAPIKey.create("")
        }
    }

    @Test("create throws invalidAPIKeyFormat for whitespace-only string")
    func createThrowsForWhitespaceOnly() {
        #expect(throws: DomainError.invalidAPIKeyFormat) {
            try AnthropicAPIKey.create("   ")
        }
    }

    // MARK: - Length Tests

    @Test("create throws when key is shorter than 20 characters")
    func createThrowsForShortKey() {
        // "sk-ant-api03-ab" = 15 chars, which is < 20
        #expect(throws: DomainError.invalidAPIKeyFormat) {
            try AnthropicAPIKey.create("sk-ant-api03-ab")
        }
    }

    @Test("create accepts key with exactly 20 characters")
    func createAcceptsExact20Chars() throws {
        // "sk-ant-api03-1234567" = 20 chars exactly
        let key = try AnthropicAPIKey.create("sk-ant-api03-1234567")
        #expect(key.value.count == 20)
    }

    @Test("create throws for key with 19 characters")
    func createThrowsFor19Chars() {
        // "sk-ant-api03-123456" = 19 chars
        #expect(throws: DomainError.invalidAPIKeyFormat) {
            try AnthropicAPIKey.create("sk-ant-api03-123456")
        }
    }

    // MARK: - Masked Property Tests

    @Test("masked returns format with first 6 chars and last 3 chars")
    func maskedReturnsCorrectFormat() throws {
        let key = try AnthropicAPIKey.create("sk-ant-api03-abc123def456")
        // prefix(6) = "sk-ant", suffix(3) = "456"
        #expect(key.masked == "sk-ant...456")
    }

    @Test("masked uses first 6 characters as prefix")
    func maskedUsesFirst6CharsAsPrefix() throws {
        let key = try AnthropicAPIKey.create("sk-ant-api03-XYZabcDEF789")
        let masked = key.masked
        #expect(masked.hasPrefix("sk-ant"))
    }

    @Test("masked uses last 3 characters as suffix")
    func maskedUsesLast3CharsAsSuffix() throws {
        let key = try AnthropicAPIKey.create("sk-ant-api03-abc123XYZ")
        let masked = key.masked
        #expect(masked.hasSuffix("XYZ"))
    }

    @Test("masked contains ellipsis separator")
    func maskedContainsEllipsis() throws {
        let key = try AnthropicAPIKey.create("sk-ant-api03-abc123def456")
        #expect(key.masked.contains("..."))
    }

    // MARK: - Equatable Tests

    @Test("two keys with same value are equal")
    func equatableSameValue() throws {
        let key1 = try AnthropicAPIKey.create("sk-ant-api03-abc123def456")
        let key2 = try AnthropicAPIKey.create("sk-ant-api03-abc123def456")
        #expect(key1 == key2)
    }

    @Test("two keys with different values are not equal")
    func equatableDifferentValues() throws {
        let key1 = try AnthropicAPIKey.create("sk-ant-api03-abc123def456")
        let key2 = try AnthropicAPIKey.create("sk-ant-api03-xyz789pqr000")
        #expect(key1 != key2)
    }
}
