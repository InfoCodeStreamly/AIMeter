import Testing
@testable import AIMeterDomain

@Suite("SessionKey")
struct SessionKeyTests {

    // MARK: - Creation Tests

    @Test("create with valid session key")
    func createValid() throws {
        let key = "sk-ant-oat01-1234567890abcdefghij"
        let sessionKey = try SessionKey.create(key)
        #expect(sessionKey.value == key)
    }

    @Test("create with long session key")
    func createLong() throws {
        let key = "sk-ant-oat01-" + String(repeating: "a", count: 100)
        let sessionKey = try SessionKey.create(key)
        #expect(sessionKey.value == key)
    }

    @Test("create throws for empty string")
    func createEmpty() {
        #expect(throws: DomainError.self) {
            try SessionKey.create("")
        }
    }

    @Test("create throws for short string")
    func createTooShort() {
        #expect(throws: DomainError.self) {
            try SessionKey.create("sk-ant-short")
        }
    }

    @Test("create throws for 19 characters")
    func createNineteenChars() {
        let key = String(repeating: "a", count: 19)
        #expect(throws: DomainError.self) {
            try SessionKey.create(key)
        }
    }

    @Test("create succeeds for exactly 20 characters")
    func createTwentyChars() throws {
        let key = String(repeating: "a", count: 20)
        let sessionKey = try SessionKey.create(key)
        #expect(sessionKey.value == key)
    }

    @Test("create trims whitespace")
    func createTrimsWhitespace() throws {
        let key = "  sk-ant-oat01-1234567890abcdefghij  "
        let sessionKey = try SessionKey.create(key)
        #expect(sessionKey.value == "sk-ant-oat01-1234567890abcdefghij")
    }

    @Test("create throws if trimmed value is too short")
    func createTrimsToShort() {
        #expect(throws: DomainError.self) {
            try SessionKey.create("  short  ")
        }
    }

    @Test("create throws if trimmed value is empty")
    func createTrimsToEmpty() {
        #expect(throws: DomainError.self) {
            try SessionKey.create("   ")
        }
    }

    // MARK: - Masked Tests

    @Test("masked shows prefix and suffix")
    func masked() throws {
        let key = "sk-ant-oat01-1234567890abcdefghij"
        let sessionKey = try SessionKey.create(key)
        #expect(sessionKey.masked == "sk-ant...hij")
    }

    @Test("masked handles short valid key")
    func maskedShort() throws {
        // 20 character key
        let key = "12345678901234567890"
        let sessionKey = try SessionKey.create(key)
        #expect(sessionKey.masked == "123456...890")
    }

    @Test("masked shows sk-ant prefix")
    func maskedPrefix() throws {
        let key = "sk-ant-oat01-xxxxxxxxxxxxxxxxxxxxxxx"
        let sessionKey = try SessionKey.create(key)
        #expect(sessionKey.masked.hasPrefix("sk-ant"))
    }

    @Test("masked contains ellipsis")
    func maskedEllipsis() throws {
        let key = "sk-ant-oat01-1234567890abcdefghij"
        let sessionKey = try SessionKey.create(key)
        #expect(sessionKey.masked.contains("..."))
    }

    @Test("masked ends with last 3 characters")
    func maskedSuffix() throws {
        let key = "sk-ant-oat01-1234567890abcdefghij"
        let sessionKey = try SessionKey.create(key)
        #expect(sessionKey.masked.hasSuffix("hij"))
    }

    @Test("masked for key with special characters")
    func maskedSpecialChars() throws {
        let key = "sk-ant-oat01-!@#$%^&*()1234567890"
        let sessionKey = try SessionKey.create(key)
        #expect(sessionKey.masked.hasSuffix("890"))
    }

    // MARK: - Equatable Tests

    @Test("equatable compares values correctly")
    func equatable() throws {
        let key1 = "sk-ant-oat01-1234567890abcdefghij"
        let key2 = "sk-ant-oat01-1234567890abcdefghij"
        let key3 = "sk-ant-oat01-xxxxxxxxxxxxxxxxxxxxxxx"

        let sessionKey1 = try SessionKey.create(key1)
        let sessionKey2 = try SessionKey.create(key2)
        let sessionKey3 = try SessionKey.create(key3)

        #expect(sessionKey1 == sessionKey2)
        #expect(sessionKey1 != sessionKey3)
    }

    // MARK: - Edge Cases

    @Test("create handles newlines and tabs")
    func createHandlesWhitespaceVariants() throws {
        let key = "\n\tsk-ant-oat01-1234567890abcdefghij\t\n"
        let sessionKey = try SessionKey.create(key)
        #expect(sessionKey.value == "sk-ant-oat01-1234567890abcdefghij")
    }

    @Test("create with unicode characters")
    func createUnicode() throws {
        let key = "sk-🔑-oat01-1234567890abcdef"
        let sessionKey = try SessionKey.create(key)
        #expect(sessionKey.value == key)
    }
}
