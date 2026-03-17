import Testing
@testable import AIMeterInfrastructure
import Foundation

/// Tests for OrgCostAPIResponse JSON decoding — nested format.
@Suite("OrgCostAPIResponse")
struct OrgCostAPIResponseTests {

    // MARK: - OrgCostAPIResponse Decoding Tests

    @Test("decodes complete response with all fields")
    func decodesCompleteResponse() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-02T00:00:00Z",
              "results": [
                {
                  "amount": "1250",
                  "currency": "USD",
                  "model": "claude-sonnet-4-6",
                  "cost_type": "tokens",
                  "token_type": "uncached_input_tokens",
                  "description": "Claude API usage",
                  "workspace_id": "ws-abc123",
                  "service_tier": "standard",
                  "context_window": "0-200k",
                  "inference_geo": "us"
                }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        #expect(response.data.count == 1)
        #expect(response.hasMore == false)
        #expect(response.nextPage == nil)

        let bucket = response.data[0]
        #expect(bucket.startingAt == "2026-01-01T00:00:00Z")
        #expect(bucket.endingAt == "2026-01-02T00:00:00Z")
        #expect(bucket.results.count == 1)

        let result = bucket.results[0]
        #expect(result.amount == "1250")
        #expect(result.currency == "USD")
        #expect(result.model == "claude-sonnet-4-6")
        #expect(result.costType == "tokens")
        #expect(result.tokenType == "uncached_input_tokens")
        #expect(result.description == "Claude API usage")
        #expect(result.workspaceId == "ws-abc123")
        #expect(result.serviceTier == "standard")
        #expect(result.contextWindow == "0-200k")
        #expect(result.inferenceGeo == "us")
    }

    @Test("decodes amount as string not number")
    func decodesAmountAsString() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-02T00:00:00Z",
              "results": [
                { "amount": "9999" }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        #expect(response.data[0].results[0].amount == "9999")
    }

    @Test("decodes amount with decimal point as string")
    func decodesAmountWithDecimalPointAsString() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-02T00:00:00Z",
              "results": [
                { "amount": "1250.00" }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        #expect(response.data[0].results[0].amount == "1250.00")
    }

    @Test("decodes amount with zero value")
    func decodesZeroAmountAsString() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-02T00:00:00Z",
              "results": [
                { "amount": "0" }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        #expect(response.data[0].results[0].amount == "0")
    }

    @Test("decodes response with empty data array")
    func decodesEmptyDataArray() throws {
        let json = """
        {
          "data": [],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        #expect(response.data.isEmpty)
    }

    @Test("decodes response with has_more and next_page for pagination")
    func decodesResponseWithPagination() throws {
        let json = """
        {
          "data": [],
          "has_more": true,
          "next_page": "page_token_xyz"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        #expect(response.hasMore == true)
        #expect(response.nextPage == "page_token_xyz")
    }

    @Test("decodes result with optional fields as nil")
    func decodesResultWithNilOptionalFields() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-02T00:00:00Z",
              "results": [
                { "amount": "500" }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        let result = response.data[0].results[0]
        #expect(result.currency == nil)
        #expect(result.model == nil)
        #expect(result.costType == nil)
        #expect(result.tokenType == nil)
        #expect(result.description == nil)
        #expect(result.workspaceId == nil)
        #expect(result.serviceTier == nil)
        #expect(result.contextWindow == nil)
        #expect(result.inferenceGeo == nil)
    }

    @Test("decodes multiple results per bucket (group_by description)")
    func decodesMultipleResultsPerBucket() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-02T00:00:00Z",
              "results": [
                {
                  "amount": "500",
                  "model": "claude-sonnet-4-6",
                  "cost_type": "tokens",
                  "token_type": "uncached_input_tokens"
                },
                {
                  "amount": "750",
                  "model": "claude-sonnet-4-6",
                  "cost_type": "tokens",
                  "token_type": "output_tokens"
                },
                {
                  "amount": "100",
                  "cost_type": "web_search"
                }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        #expect(response.data.count == 1)
        #expect(response.data[0].results.count == 3)
        #expect(response.data[0].results[0].costType == "tokens")
        #expect(response.data[0].results[2].costType == "web_search")
    }

    @Test("decodes multiple time buckets")
    func decodesMultipleTimeBuckets() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-02T00:00:00Z",
              "results": [
                { "amount": "500" }
              ]
            },
            {
              "starting_at": "2026-01-02T00:00:00Z",
              "ending_at": "2026-01-03T00:00:00Z",
              "results": [
                { "amount": "750" }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        #expect(response.data.count == 2)
        #expect(response.data[0].results[0].amount == "500")
        #expect(response.data[1].results[0].amount == "750")
    }

    @Test("snake_case field names decode correctly for cost response")
    func snakeCaseFieldNamesDecodeCorrectly() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-02T00:00:00Z",
              "results": [
                {
                  "amount": "1000",
                  "cost_type": "tokens",
                  "token_type": "output_tokens",
                  "workspace_id": "ws-test",
                  "service_tier": "batch",
                  "context_window": "200k-1M",
                  "inference_geo": "global"
                }
              ]
            }
          ],
          "has_more": true,
          "next_page": "cursor"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        let result = response.data[0].results[0]
        #expect(result.costType == "tokens")
        #expect(result.tokenType == "output_tokens")
        #expect(result.workspaceId == "ws-test")
        #expect(result.serviceTier == "batch")
        #expect(result.contextWindow == "200k-1M")
        #expect(result.inferenceGeo == "global")
        #expect(response.hasMore == true)
        #expect(response.nextPage == "cursor")
    }
}
