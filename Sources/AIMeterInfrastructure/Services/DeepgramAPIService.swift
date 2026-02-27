import Foundation
import AIMeterDomain

/// Service for Deepgram REST API operations (balance, usage, projects)
public actor DeepgramAPIService: DeepgramAPIRepository {
    private let baseURL = "https://api.deepgram.com/v1"

    public init() {}

    // MARK: - Public API

    public func fetchBalance(apiKey: String) async throws -> DeepgramBalance {
        let projectId = try await fetchProjectId(apiKey: apiKey)

        var request = URLRequest(url: URL(string: "\(baseURL)/projects/\(projectId)/balances")!)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TranscriptionError.connectionFailed("Balances: Invalid response")
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw TranscriptionError.authenticationFailed
        }
        guard http.statusCode == 200 else {
            throw TranscriptionError.connectionFailed("Balances: HTTP \(http.statusCode)")
        }

        let result = try JSONDecoder().decode(BalancesResponse.self, from: data)
        guard let balance = result.balances.first else {
            throw TranscriptionError.connectionFailed("No balance information found")
        }

        return DeepgramBalance(amount: balance.amount, units: balance.units)
    }

    public func fetchUsage(apiKey: String, start: Date, end: Date) async throws -> (totalSeconds: Double, requestCount: Int) {
        let projectId = try await fetchProjectId(apiKey: apiKey)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")

        var components = URLComponents(string: "\(baseURL)/projects/\(projectId)/usage")!
        components.queryItems = [
            URLQueryItem(name: "start", value: formatter.string(from: start)),
            URLQueryItem(name: "end", value: formatter.string(from: end)),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TranscriptionError.connectionFailed("Usage: Invalid response")
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw TranscriptionError.authenticationFailed
        }
        guard http.statusCode == 200 else {
            throw TranscriptionError.connectionFailed("Usage: HTTP \(http.statusCode)")
        }

        let usageResponse = try JSONDecoder().decode(UsageResponse.self, from: data)

        let totalHours = usageResponse.results.reduce(0.0) { $0 + $1.hours }
        let totalRequests = usageResponse.results.reduce(0) { $0 + $1.requests }

        return (totalSeconds: totalHours * 3600, requestCount: totalRequests)
    }

    // MARK: - Private

    private func fetchProjectId(apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: "\(baseURL)/projects")!)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TranscriptionError.connectionFailed("Invalid response")
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw TranscriptionError.authenticationFailed
        }
        guard http.statusCode == 200 else {
            throw TranscriptionError.connectionFailed("Projects: HTTP \(http.statusCode)")
        }

        let result = try JSONDecoder().decode(ProjectsResponse.self, from: data)
        guard let projectId = result.projects.first?.projectId else {
            throw TranscriptionError.connectionFailed("No projects found")
        }
        return projectId
    }
}

// MARK: - Response Types

private struct ProjectsResponse: Decodable {
    let projects: [Project]
}

private struct Project: Decodable {
    let projectId: String

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
    }
}

private struct BalancesResponse: Decodable {
    let balances: [Balance]
}

private struct Balance: Decodable {
    let amount: Double
    let units: String
}

private struct UsageResponse: Decodable {
    let results: [UsageResult]
}

private struct UsageResult: Decodable {
    let hours: Double
    let requests: Int
}
