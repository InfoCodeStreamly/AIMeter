import Foundation
import AIMeterDomain
import AIMeterApplication

/// Admin API endpoints configuration
/// Uses Admin API key (sk-ant-admin-...) with x-api-key header
enum AdminAPIEndpoints {

    // MARK: - Base URL

    static let baseURL = "https://api.anthropic.com"

    // MARK: - Endpoints

    /// Usage report endpoint with query parameters
    static func usageReport(
        from: Date,
        to: Date,
        bucketWidth: String,
        groupBy: [String]?,
        page: String?
    ) -> URL {
        var components = URLComponents(string: "\(baseURL)/v1/organizations/usage_report/messages")!
        var queryItems = [
            URLQueryItem(name: "starting_at", value: iso8601String(from: from)),
            URLQueryItem(name: "ending_at", value: iso8601String(from: to)),
            URLQueryItem(name: "bucket_width", value: bucketWidth)
        ]
        if let groupBy {
            for group in groupBy {
                queryItems.append(URLQueryItem(name: "group_by[]", value: group))
            }
        }
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: page))
        }
        components.queryItems = queryItems
        return components.url!
    }

    /// Cost report endpoint with query parameters
    static func costReport(
        from: Date,
        to: Date,
        groupBy: [String]?,
        page: String?
    ) -> URL {
        var components = URLComponents(string: "\(baseURL)/v1/organizations/cost_report")!
        var queryItems = [
            URLQueryItem(name: "starting_at", value: iso8601String(from: from)),
            URLQueryItem(name: "ending_at", value: iso8601String(from: to))
        ]
        if let groupBy {
            for group in groupBy {
                queryItems.append(URLQueryItem(name: "group_by[]", value: group))
            }
        }
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: page))
        }
        components.queryItems = queryItems
        return components.url!
    }

    /// Claude Code analytics endpoint
    static func claudeCodeAnalytics(
        date: Date,
        limit: Int?,
        page: String?
    ) -> URL {
        var components = URLComponents(string: "\(baseURL)/v1/organizations/usage_report/claude_code")!
        var queryItems = [
            URLQueryItem(name: "starting_at", value: dateOnlyString(from: date))
        ]
        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: page))
        }
        components.queryItems = queryItems
        return components.url!
    }

    // MARK: - Headers

    /// Admin API headers
    static func headers(apiKey: String) -> [String: String] {
        [
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "AIMeter/1.0"
        ]
    }

    // MARK: - Date Formatting

    private static func iso8601String(from date: Date) -> String {
        date.formatted(.iso8601)
    }

    private static func dateOnlyString(from date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        return String(format: "%04d-%02d-%02d", components.year!, components.month!, components.day!)
    }
}
