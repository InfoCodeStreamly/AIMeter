import Testing
@testable import AIMeterInfrastructure
import Foundation

/// Tests for OrgUsageAPIResponse JSON decoding.
@Suite("OrgUsageAPIResponse")
struct OrgUsageAPIResponseTests {

    // MARK: - OrgUsageAPIResponse Decoding Tests

    @Test("decodes complete response with all fields")
    func decodesCompleteResponse() throws {
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z",
              "model": "claude-3-opus-20240229",
              "workspace_id": "ws-abc123",
              "input_tokens": 1000,
              "output_tokens": 500,
              "cache_read_input_tokens": 200,
              "cache_creation_input_tokens": 100
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
        #expect(bucket.snapshotStartTime == "2026-01-01T00:00:00Z")
        #expect(bucket.snapshotEndTime == "2026-01-01T01:00:00Z")
        #expect(bucket.model == "claude-3-opus-20240229")
        #expect(bucket.workspaceId == "ws-abc123")
        #expect(bucket.inputTokens == 1000)
        #expect(bucket.outputTokens == 500)
        #expect(bucket.cacheReadInputTokens == 200)
        #expect(bucket.cacheCreationInputTokens == 100)
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

    @Test("decodes response with multiple buckets")
    func decodesMultipleBuckets() throws {
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z",
              "model": "claude-3-opus-20240229",
              "workspace_id": null,
              "input_tokens": 1000,
              "output_tokens": 500
            },
            {
              "snapshot_start_time": "2026-01-01T01:00:00Z",
              "snapshot_end_time": "2026-01-01T02:00:00Z",
              "model": "claude-3-sonnet-20240229",
              "workspace_id": "ws-abc",
              "input_tokens": 2000,
              "output_tokens": 1000
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        #expect(response.data.count == 2)
        #expect(response.data[0].model == "claude-3-opus-20240229")
        #expect(response.data[1].model == "claude-3-sonnet-20240229")
    }

    // MARK: - OrgUsageBucketData Optional Fields Tests

    @Test("decodes bucket with optional fields as nil")
    func decodesBucketWithNilOptionalFields() throws {
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z"
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        let bucket = response.data[0]
        #expect(bucket.model == nil)
        #expect(bucket.workspaceId == nil)
        #expect(bucket.inputTokens == nil)
        #expect(bucket.outputTokens == nil)
        #expect(bucket.cacheReadInputTokens == nil)
        #expect(bucket.cacheCreationInputTokens == nil)
    }

    @Test("decodes bucket with zero token counts")
    func decodesBucketWithZeroTokens() throws {
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z",
              "input_tokens": 0,
              "output_tokens": 0,
              "cache_read_input_tokens": 0,
              "cache_creation_input_tokens": 0
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        let bucket = response.data[0]
        #expect(bucket.inputTokens == 0)
        #expect(bucket.outputTokens == 0)
        #expect(bucket.cacheReadInputTokens == 0)
        #expect(bucket.cacheCreationInputTokens == 0)
    }

    @Test("decodes bucket with large token counts")
    func decodesBucketWithLargeTokenCounts() throws {
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z",
              "input_tokens": 10000000,
              "output_tokens": 5000000
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        #expect(response.data[0].inputTokens == 10_000_000)
        #expect(response.data[0].outputTokens == 5_000_000)
    }

    @Test("decodes bucket timestamps with fractional seconds")
    func decodesBucketTimestampsWithFractionalSeconds() throws {
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00.123456Z",
              "snapshot_end_time": "2026-01-01T01:00:00.789Z"
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        #expect(response.data[0].snapshotStartTime == "2026-01-01T00:00:00.123456Z")
        #expect(response.data[0].snapshotEndTime == "2026-01-01T01:00:00.789Z")
    }

    @Test("snake_case field names decode correctly")
    func snakeCaseFieldNamesDecode() throws {
        // Verify that CodingKeys mapping works for all snake_case fields
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z",
              "workspace_id": "ws-test",
              "input_tokens": 100,
              "output_tokens": 50,
              "cache_read_input_tokens": 10,
              "cache_creation_input_tokens": 5
            }
          ],
          "has_more": true,
          "next_page": "next"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgUsageAPIResponse.self, from: json)

        let bucket = response.data[0]
        #expect(bucket.workspaceId == "ws-test")
        #expect(bucket.inputTokens == 100)
        #expect(bucket.outputTokens == 50)
        #expect(bucket.cacheReadInputTokens == 10)
        #expect(bucket.cacheCreationInputTokens == 5)
        #expect(response.hasMore == true)
        #expect(response.nextPage == "next")
    }
}
