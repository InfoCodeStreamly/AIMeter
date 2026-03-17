import Testing
@testable import AIMeterInfrastructure
import Foundation

/// Tests for OrgUsageAPIResponse JSON decoding — nested format.
@Suite("OrgUsageAPIResponse")
struct OrgUsageAPIResponseTests {

    // MARK: - OrgUsageAPIResponse Decoding Tests

    @Test("decodes complete response with all fields")
    func decodesCompleteResponse() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-01T01:00:00Z",
              "results": [
                {
                  "uncached_input_tokens": 1000,
                  "output_tokens": 500,
                  "cache_read_input_tokens": 200,
                  "cache_creation": {
                    "ephemeral_1h_input_tokens": 80,
                    "ephemeral_5m_input_tokens": 20
                  },
                  "model": "claude-3-opus-20240229",
                  "api_key_id": "apikey_01abc",
                  "workspace_id": "ws-abc123",
                  "service_tier": "standard",
                  "context_window": "0-200k",
                  "inference_geo": "us",
                  "server_tool_use": {
                    "web_search_requests": 3
                  }
                }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        #expect(response.data.count == 1)
        #expect(response.hasMore == false)
        #expect(response.nextPage == nil)

        let bucket = response.data[0]
        #expect(bucket.startingAt == "2026-01-01T00:00:00Z")
        #expect(bucket.endingAt == "2026-01-01T01:00:00Z")
        #expect(bucket.results.count == 1)

        let result = bucket.results[0]
        #expect(result.uncachedInputTokens == 1000)
        #expect(result.outputTokens == 500)
        #expect(result.cacheReadInputTokens == 200)
        #expect(result.cacheCreation?.ephemeral1hInputTokens == 80)
        #expect(result.cacheCreation?.ephemeral5mInputTokens == 20)
        #expect(result.model == "claude-3-opus-20240229")
        #expect(result.apiKeyId == "apikey_01abc")
        #expect(result.workspaceId == "ws-abc123")
        #expect(result.serviceTier == "standard")
        #expect(result.contextWindow == "0-200k")
        #expect(result.inferenceGeo == "us")
        #expect(result.serverToolUse?.webSearchRequests == 3)
    }

    @Test("decodes response with has_more true and next_page cursor")
    func decodesResponseWithPagination() throws {
        let json = """
        {
          "data": [],
          "has_more": true,
          "next_page": "cursor_abc123"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        #expect(response.hasMore == true)
        #expect(response.nextPage == "cursor_abc123")
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

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        #expect(response.data.isEmpty)
    }

    @Test("decodes response with multiple buckets and results")
    func decodesMultipleBuckets() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-01T01:00:00Z",
              "results": [
                {
                  "uncached_input_tokens": 1000,
                  "output_tokens": 500,
                  "model": "claude-3-opus-20240229"
                }
              ]
            },
            {
              "starting_at": "2026-01-01T01:00:00Z",
              "ending_at": "2026-01-01T02:00:00Z",
              "results": [
                {
                  "uncached_input_tokens": 2000,
                  "output_tokens": 1000,
                  "model": "claude-3-sonnet-20240229"
                }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        #expect(response.data.count == 2)
        #expect(response.data[0].results[0].model == "claude-3-opus-20240229")
        #expect(response.data[1].results[0].model == "claude-3-sonnet-20240229")
    }

    // MARK: - Optional Fields Tests

    @Test("decodes result with all optional fields as nil")
    func decodesResultWithNilOptionalFields() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-01T01:00:00Z",
              "results": [
                {}
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        let result = response.data[0].results[0]
        #expect(result.model == nil)
        #expect(result.apiKeyId == nil)
        #expect(result.workspaceId == nil)
        #expect(result.uncachedInputTokens == nil)
        #expect(result.outputTokens == nil)
        #expect(result.cacheReadInputTokens == nil)
        #expect(result.cacheCreation == nil)
        #expect(result.serviceTier == nil)
        #expect(result.contextWindow == nil)
        #expect(result.inferenceGeo == nil)
        #expect(result.serverToolUse == nil)
    }

    @Test("decodes result with zero token counts")
    func decodesResultWithZeroTokens() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-01T01:00:00Z",
              "results": [
                {
                  "uncached_input_tokens": 0,
                  "output_tokens": 0,
                  "cache_read_input_tokens": 0,
                  "cache_creation": {
                    "ephemeral_1h_input_tokens": 0,
                    "ephemeral_5m_input_tokens": 0
                  }
                }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        let result = response.data[0].results[0]
        #expect(result.uncachedInputTokens == 0)
        #expect(result.outputTokens == 0)
        #expect(result.cacheReadInputTokens == 0)
        #expect(result.cacheCreation?.ephemeral1hInputTokens == 0)
        #expect(result.cacheCreation?.ephemeral5mInputTokens == 0)
    }

    @Test("decodes result with large token counts")
    func decodesResultWithLargeTokenCounts() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-01T01:00:00Z",
              "results": [
                {
                  "uncached_input_tokens": 10000000,
                  "output_tokens": 5000000
                }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        #expect(response.data[0].results[0].uncachedInputTokens == 10_000_000)
        #expect(response.data[0].results[0].outputTokens == 5_000_000)
    }

    @Test("decodes bucket timestamps with fractional seconds")
    func decodesBucketTimestampsWithFractionalSeconds() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00.123456Z",
              "ending_at": "2026-01-01T01:00:00.789Z",
              "results": []
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        #expect(response.data[0].startingAt == "2026-01-01T00:00:00.123456Z")
        #expect(response.data[0].endingAt == "2026-01-01T01:00:00.789Z")
    }

    @Test("decodes multiple results per bucket (group_by)")
    func decodesMultipleResultsPerBucket() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-02T00:00:00Z",
              "results": [
                {
                  "uncached_input_tokens": 1000,
                  "output_tokens": 500,
                  "model": "claude-sonnet-4-6",
                  "api_key_id": "apikey_01abc"
                },
                {
                  "uncached_input_tokens": 2000,
                  "output_tokens": 800,
                  "model": "claude-haiku-4-5",
                  "api_key_id": "apikey_01abc"
                },
                {
                  "uncached_input_tokens": 500,
                  "output_tokens": 200,
                  "model": "claude-sonnet-4-6",
                  "api_key_id": "apikey_02def"
                }
              ]
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        #expect(response.data.count == 1)
        #expect(response.data[0].results.count == 3)
        #expect(response.data[0].results[0].apiKeyId == "apikey_01abc")
        #expect(response.data[0].results[2].apiKeyId == "apikey_02def")
    }

    @Test("snake_case field names decode correctly")
    func snakeCaseFieldNamesDecode() throws {
        let json = """
        {
          "data": [
            {
              "starting_at": "2026-01-01T00:00:00Z",
              "ending_at": "2026-01-01T01:00:00Z",
              "results": [
                {
                  "uncached_input_tokens": 100,
                  "output_tokens": 50,
                  "cache_read_input_tokens": 10,
                  "cache_creation": {
                    "ephemeral_1h_input_tokens": 3,
                    "ephemeral_5m_input_tokens": 2
                  },
                  "api_key_id": "key1",
                  "workspace_id": "ws-test",
                  "service_tier": "standard",
                  "context_window": "0-200k",
                  "inference_geo": "global",
                  "server_tool_use": {
                    "web_search_requests": 1
                  }
                }
              ]
            }
          ],
          "has_more": true,
          "next_page": "next"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        let result = response.data[0].results[0]
        #expect(result.uncachedInputTokens == 100)
        #expect(result.outputTokens == 50)
        #expect(result.cacheReadInputTokens == 10)
        #expect(result.cacheCreation?.ephemeral1hInputTokens == 3)
        #expect(result.cacheCreation?.ephemeral5mInputTokens == 2)
        #expect(result.apiKeyId == "key1")
        #expect(result.workspaceId == "ws-test")
        #expect(result.serviceTier == "standard")
        #expect(result.contextWindow == "0-200k")
        #expect(result.inferenceGeo == "global")
        #expect(result.serverToolUse?.webSearchRequests == 1)
        #expect(response.hasMore == true)
        #expect(response.nextPage == "next")
    }
}
