import Testing
@testable import AIMeterDomain

/// Tests for AdminAPIKey value object, validating format rules and masked display.
@Suite("AdminAPIKey")
struct AdminAPIKeyTests {

    // MARK: - Valid Key Tests

    @Test("create accepts valid admin key with correct prefix")
    func createAcceptsValidKey() throws {
        let key = try AdminAPIKey.create("sk-ant-admin-abc123def456")
        #expect(key.value == "sk-ant-admin-abc123def456")
    }

    @Test("create accepts valid key with longer value")
    func createAcceptsLongKey() throws {
        let key = try AdminAPIKey.create("sk-ant-admin-abcdefghijklmnopqrstuvwxyz0123456789")
        #expect(key.value == "sk-ant-admin-abcdefghijklmnopqrstuvwxyz0123456789")
    }

    @Test("create trims leading and trailing whitespace")
    func createTrimsWhitespace() throws {
        let key = try AdminAPIKey.create("  sk-ant-admin-abc123def456  ")
        #expect(key.value == "sk-ant-admin-abc123def456")
    }

    @Test("create trims newlines")
    func createTrimsNewlines() throws {
        let key = try AdminAPIKey.create("\nsk-ant-admin-abc123def456\n")
        #expect(key.value == "sk-ant-admin-abc123def456")
    }

    // MARK: - Invalid Prefix Tests

    @Test("create throws for wrong prefix sk-ant-api03")
    func createThrowsForApiPrefix() {
        #expect(throws: DomainError.invalidAdminKeyFormat) {
            try AdminAPIKey.create("sk-ant-api03-abcdefghijklmnop")
        }
    }

    @Test("create throws for OAuth token prefix sk-ant-oat01")
    func createThrowsForOAuthPrefix() {
        #expect(throws: DomainError.invalidAdminKeyFormat) {
            try AdminAPIKey.create("sk-ant-oat01-abcdefghijklmnop")
        }
    }

    @Test("create throws for completely wrong prefix")
    func createThrowsForWrongPrefix() {
        #expect(throws: DomainError.invalidAdminKeyFormat) {
            try AdminAPIKey.create("Bearer sk-ant-admin-abcdefghijklm")
        }
    }

    @Test("create throws for key without sk-ant prefix")
    func createThrowsForNoSKANTPrefix() {
        #expect(throws: DomainError.invalidAdminKeyFormat) {
            try AdminAPIKey.create("admin-abcdefghijklmnopqrstuvwxyz")
        }
    }

    // MARK: - Empty Tests

    @Test("create throws for empty string")
    func createThrowsForEmpty() {
        #expect(throws: DomainError.invalidAdminKeyFormat) {
            try AdminAPIKey.create("")
        }
    }

    @Test("create throws for whitespace-only string")
    func createThrowsForWhitespaceOnly() {
        #expect(throws: DomainError.invalidAdminKeyFormat) {
            try AdminAPIKey.create("   ")
        }
    }

    // MARK: - Length Tests

    @Test("create throws when key is shorter than 20 characters")
    func createThrowsForShortKey() {
        // "sk-ant-admin-abc" = 16 chars, which is < 20
        #expect(throws: DomainError.invalidAdminKeyFormat) {
            try AdminAPIKey.create("sk-ant-admin-abc")
        }
    }

    @Test("create accepts key with exactly 20 characters")
    func createAcceptsExact20Chars() throws {
        // "sk-ant-admin-1234567" = 20 chars exactly
        let key = try AdminAPIKey.create("sk-ant-admin-1234567")
        #expect(key.value.count == 20)
    }

    @Test("create throws for key with 19 characters")
    func createThrowsFor19Chars() {
        // "sk-ant-admin-123456" = 19 chars
        #expect(throws: DomainError.invalidAdminKeyFormat) {
            try AdminAPIKey.create("sk-ant-admin-123456")
        }
    }

    // MARK: - Masked Property Tests

    @Test("masked returns format with prefix and last 3 chars")
    func maskedReturnsCorrectFormat() throws {
        let key = try AdminAPIKey.create("sk-ant-admin-abc123def456")
        // prefix(6) = "sk-ant", suffix(3) = "456"
        #expect(key.masked == "sk-ant...456")
    }

    @Test("masked uses first 6 characters as prefix")
    func maskedUsesFirst6CharsAsPrefix() throws {
        let key = try AdminAPIKey.create("sk-ant-admin-XYZabcDEF789")
        let masked = key.masked
        #expect(masked.hasPrefix("sk-ant"))
    }

    @Test("masked uses last 3 characters as suffix")
    func maskedUsesLast3CharsAsSuffix() throws {
        let key = try AdminAPIKey.create("sk-ant-admin-abc123XYZ")
        let masked = key.masked
        #expect(masked.hasSuffix("XYZ"))
    }

    @Test("masked contains ellipsis separator")
    func maskedContainsEllipsis() throws {
        let key = try AdminAPIKey.create("sk-ant-admin-abc123def456")
        #expect(key.masked.contains("..."))
    }

    // MARK: - Equatable Tests

    @Test("two keys with same value are equal")
    func equatableSameValue() throws {
        let key1 = try AdminAPIKey.create("sk-ant-admin-abc123def456")
        let key2 = try AdminAPIKey.create("sk-ant-admin-abc123def456")
        #expect(key1 == key2)
    }

    @Test("two keys with different values are not equal")
    func equatableDifferentValues() throws {
        let key1 = try AdminAPIKey.create("sk-ant-admin-abc123def456")
        let key2 = try AdminAPIKey.create("sk-ant-admin-xyz789pqr000")
        #expect(key1 != key2)
    }
}
