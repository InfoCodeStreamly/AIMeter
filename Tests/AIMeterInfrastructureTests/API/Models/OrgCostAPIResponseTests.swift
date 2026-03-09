import Testing
@testable import AIMeterInfrastructure
import Foundation

/// Tests for OrgCostAPIResponse JSON decoding — including amount as String.
@Suite("OrgCostAPIResponse")
struct OrgCostAPIResponseTests {

    // MARK: - OrgCostAPIResponse Decoding Tests

    @Test("decodes complete response with all fields")
    func decodesCompleteResponse() throws {
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z",
              "workspace_id": "ws-abc123",
              "description": "Claude API usage",
              "amount": "1250"
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
        #expect(bucket.snapshotStartTime == "2026-01-01T00:00:00Z")
        #expect(bucket.snapshotEndTime == "2026-01-01T01:00:00Z")
        #expect(bucket.workspaceId == "ws-abc123")
        #expect(bucket.description == "Claude API usage")
        #expect(bucket.amount == "1250")
    }

    @Test("decodes amount as string not number")
    func decodesAmountAsString() throws {
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z",
              "amount": "9999"
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        #expect(response.data[0].amount == "9999")
    }

    @Test("decodes amount with decimal point as string")
    func decodesAmountWithDecimalPointAsString() throws {
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z",
              "amount": "1250.00"
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        #expect(response.data[0].amount == "1250.00")
    }

    @Test("decodes amount with zero value")
    func decodesZeroAmountAsString() throws {
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z",
              "amount": "0"
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        #expect(response.data[0].amount == "0")
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

    @Test("decodes bucket with optional fields as nil")
    func decodesBucketWithNilOptionalFields() throws {
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z",
              "amount": "500"
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        let bucket = response.data[0]
        #expect(bucket.workspaceId == nil)
        #expect(bucket.description == nil)
    }

    @Test("decodes multiple cost buckets")
    func decodesMultipleCostBuckets() throws {
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z",
              "amount": "500"
            },
            {
              "snapshot_start_time": "2026-01-01T01:00:00Z",
              "snapshot_end_time": "2026-01-01T02:00:00Z",
              "amount": "750"
            }
          ],
          "has_more": false,
          "next_page": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        #expect(response.data.count == 2)
        #expect(response.data[0].amount == "500")
        #expect(response.data[1].amount == "750")
    }

    @Test("snake_case field names decode correctly for cost response")
    func snakeCaseFieldNamesDecodeCorrectly() throws {
        // Verify CodingKeys work for all snake_case fields
        let json = """
        {
          "data": [
            {
              "snapshot_start_time": "2026-01-01T00:00:00Z",
              "snapshot_end_time": "2026-01-01T01:00:00Z",
              "workspace_id": "ws-test",
              "description": "test desc",
              "amount": "1000"
            }
          ],
          "has_more": true,
          "next_page": "cursor"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OrgCostAPIResponse.self, from: json)

        let bucket = response.data[0]
        #expect(bucket.workspaceId == "ws-test")
        #expect(bucket.description == "test desc")
        #expect(response.hasMore == true)
        #expect(response.nextPage == "cursor")
    }
}
