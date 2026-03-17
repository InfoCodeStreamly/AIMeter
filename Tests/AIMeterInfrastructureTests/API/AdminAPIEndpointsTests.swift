import Testing
@testable import AIMeterInfrastructure
import AIMeterDomain
import Foundation

/// Tests for AdminAPIEndpoints — URL construction and header generation.
@Suite("AdminAPIEndpoints")
struct AdminAPIEndpointsTests {

    // MARK: - Base URL Tests

    @Test("baseURL is the Anthropic API base URL")
    func baseURLIsAnthropicAPI() {
        #expect(AdminAPIEndpoints.baseURL == "https://api.anthropic.com")
    }

    @Test("baseURL is a valid URL")
    func baseURLIsValidURL() {
        let url = URL(string: AdminAPIEndpoints.baseURL)
        #expect(url != nil)
        #expect(url?.scheme == "https")
        #expect(url?.host == "api.anthropic.com")
    }

    @Test("baseURL does not end with slash")
    func baseURLNoTrailingSlash() {
        #expect(!AdminAPIEndpoints.baseURL.hasSuffix("/"))
    }

    // MARK: - usageReport URL Tests

    @Test("usageReport URL contains correct path")
    func usageReportURLContainsCorrectPath() {
        let from = Date(timeIntervalSince1970: 1_700_000_000)
        let to   = Date(timeIntervalSince1970: 1_700_086_400)
        let url  = AdminAPIEndpoints.usageReport(
            from: from, to: to, bucketWidth: "1h", groupBy: nil, page: nil
        )

        #expect(url.path == "/v1/organizations/usage_report/messages")
    }

    @Test("usageReport URL contains starting_at query parameter")
    func usageReportURLContainsStartingAt() {
        let from = Date(timeIntervalSince1970: 1_700_000_000)
        let to   = Date(timeIntervalSince1970: 1_700_086_400)
        let url  = AdminAPIEndpoints.usageReport(
            from: from, to: to, bucketWidth: "1h", groupBy: nil, page: nil
        )

        #expect(url.query?.contains("starting_at") == true)
    }

    @Test("usageReport URL contains ending_at query parameter")
    func usageReportURLContainsEndingAt() {
        let from = Date(timeIntervalSince1970: 1_700_000_000)
        let to   = Date(timeIntervalSince1970: 1_700_086_400)
        let url  = AdminAPIEndpoints.usageReport(
            from: from, to: to, bucketWidth: "1h", groupBy: nil, page: nil
        )

        #expect(url.query?.contains("ending_at") == true)
    }

    @Test("usageReport URL contains bucket_width query parameter")
    func usageReportURLContainsBucketWidth() {
        let from = Date(timeIntervalSince1970: 1_700_000_000)
        let to   = Date(timeIntervalSince1970: 1_700_086_400)
        let url  = AdminAPIEndpoints.usageReport(
            from: from, to: to, bucketWidth: "1d", groupBy: nil, page: nil
        )

        #expect(url.query?.contains("bucket_width=1d") == true)
    }

    @Test("usageReport URL with groupBy adds group_by parameters")
    func usageReportURLWithGroupByAddsParameters() {
        let from = Date(timeIntervalSince1970: 1_700_000_000)
        let to   = Date(timeIntervalSince1970: 1_700_086_400)
        let url  = AdminAPIEndpoints.usageReport(
            from: from, to: to, bucketWidth: "1h", groupBy: ["model"], page: nil
        )

        #expect(url.query?.contains("group_by%5B%5D=model") == true || url.query?.contains("group_by[]=model") == true)
    }

    @Test("usageReport URL with page adds page parameter")
    func usageReportURLWithPageAddsParameter() {
        let from = Date(timeIntervalSince1970: 1_700_000_000)
        let to   = Date(timeIntervalSince1970: 1_700_086_400)
        let url  = AdminAPIEndpoints.usageReport(
            from: from, to: to, bucketWidth: "1h", groupBy: nil, page: "cursor123"
        )

        #expect(url.query?.contains("page=cursor123") == true)
    }

    @Test("usageReport URL without page has no page parameter")
    func usageReportURLWithoutPageHasNoPageParam() {
        let from = Date(timeIntervalSince1970: 1_700_000_000)
        let to   = Date(timeIntervalSince1970: 1_700_086_400)
        let url  = AdminAPIEndpoints.usageReport(
            from: from, to: to, bucketWidth: "1h", groupBy: nil, page: nil
        )

        #expect(url.query?.contains("page=") != true)
    }

    @Test("usageReport URL is valid")
    func usageReportURLIsValid() {
        let from = Date(timeIntervalSince1970: 1_700_000_000)
        let to   = Date(timeIntervalSince1970: 1_700_086_400)
        let url  = AdminAPIEndpoints.usageReport(
            from: from, to: to, bucketWidth: "1h", groupBy: nil, page: nil
        )

        #expect(url.scheme == "https")
        #expect(url.host == "api.anthropic.com")
    }

    // MARK: - costReport URL Tests

    @Test("costReport URL contains correct path")
    func costReportURLContainsCorrectPath() {
        let from = Date(timeIntervalSince1970: 1_700_000_000)
        let to   = Date(timeIntervalSince1970: 1_700_086_400)
        let url  = AdminAPIEndpoints.costReport(from: from, to: to, groupBy: nil, page: nil)

        #expect(url.path == "/v1/organizations/cost_report")
    }

    @Test("costReport URL contains starting_at and ending_at parameters")
    func costReportURLContainsDateParameters() {
        let from = Date(timeIntervalSince1970: 1_700_000_000)
        let to   = Date(timeIntervalSince1970: 1_700_086_400)
        let url  = AdminAPIEndpoints.costReport(from: from, to: to, groupBy: nil, page: nil)

        #expect(url.query?.contains("starting_at") == true)
        #expect(url.query?.contains("ending_at") == true)
    }

    @Test("costReport URL with page adds page parameter")
    func costReportURLWithPageAddsParameter() {
        let from = Date(timeIntervalSince1970: 1_700_000_000)
        let to   = Date(timeIntervalSince1970: 1_700_086_400)
        let url  = AdminAPIEndpoints.costReport(from: from, to: to, groupBy: nil, page: "nextPage")

        #expect(url.query?.contains("page=nextPage") == true)
    }

    // MARK: - claudeCodeAnalytics URL Tests

    @Test("claudeCodeAnalytics URL contains correct path")
    func claudeCodeAnalyticsURLContainsCorrectPath() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let url  = AdminAPIEndpoints.claudeCodeAnalytics(date: date, limit: nil, page: nil)

        #expect(url.path == "/v1/organizations/usage_report/claude_code")
    }

    @Test("claudeCodeAnalytics URL contains starting_at parameter")
    func claudeCodeAnalyticsURLContainsStartingAt() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let url  = AdminAPIEndpoints.claudeCodeAnalytics(date: date, limit: nil, page: nil)

        #expect(url.query?.contains("starting_at") == true)
    }

    @Test("claudeCodeAnalytics URL with limit adds limit parameter")
    func claudeCodeAnalyticsURLWithLimitAddsParameter() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let url  = AdminAPIEndpoints.claudeCodeAnalytics(date: date, limit: 50, page: nil)

        #expect(url.query?.contains("limit=50") == true)
    }

    @Test("claudeCodeAnalytics URL without limit has no limit parameter")
    func claudeCodeAnalyticsURLWithoutLimitHasNoLimitParam() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let url  = AdminAPIEndpoints.claudeCodeAnalytics(date: date, limit: nil, page: nil)

        #expect(url.query?.contains("limit=") != true)
    }

    @Test("claudeCodeAnalytics URL with page adds page parameter")
    func claudeCodeAnalyticsURLWithPageAddsParameter() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let url  = AdminAPIEndpoints.claudeCodeAnalytics(date: date, limit: nil, page: "abc")

        #expect(url.query?.contains("page=abc") == true)
    }

    // MARK: - Headers Tests

    @Test("headers contains x-api-key with provided key")
    func headersContainsApiKey() {
        let apiKey = "sk-ant-admin-testkey123456789xyz"
        let headers = AdminAPIEndpoints.headers(apiKey: apiKey)

        #expect(headers["x-api-key"] == apiKey)
    }

    @Test("headers contains anthropic-version header")
    func headersContainsAnthropicVersion() {
        let headers = AdminAPIEndpoints.headers(apiKey: "test-key")

        #expect(headers["anthropic-version"] == "2023-06-01")
    }

    @Test("headers contains Content-Type application/json")
    func headersContainsContentType() {
        let headers = AdminAPIEndpoints.headers(apiKey: "test-key")

        #expect(headers["Content-Type"] == "application/json")
    }

    @Test("headers contains Accept application/json")
    func headersContainsAccept() {
        let headers = AdminAPIEndpoints.headers(apiKey: "test-key")

        #expect(headers["Accept"] == "application/json")
    }

    @Test("headers contains User-Agent AIMeter/1.0")
    func headersContainsUserAgent() {
        let headers = AdminAPIEndpoints.headers(apiKey: "test-key")

        #expect(headers["User-Agent"] == "AIMeter/1.0")
    }

    @Test("headers contains all required keys")
    func headersContainsAllRequiredKeys() {
        let requiredKeys = ["x-api-key", "anthropic-version", "Content-Type", "Accept", "User-Agent"]
        let headers = AdminAPIEndpoints.headers(apiKey: "test-key")

        for key in requiredKeys {
            #expect(headers[key] != nil, "Missing required header: \(key)")
        }
    }

    @Test("headers do not use Bearer prefix for admin key")
    func headersDoNotUseBearerPrefix() {
        let apiKey = "sk-ant-admin-testkey123456789xyz"
        let headers = AdminAPIEndpoints.headers(apiKey: apiKey)

        // Admin API uses x-api-key header (no Bearer), unlike OAuth which uses Authorization: Bearer
        #expect(headers["Authorization"] == nil)
        #expect(headers["x-api-key"] == apiKey)
    }
}
