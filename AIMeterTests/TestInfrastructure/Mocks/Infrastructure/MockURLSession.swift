import Foundation
@testable import AIMeter

actor MockURLSession {
    
    // MARK: - Stub Results
    var dataResult: Result<(Data, URLResponse), Error> = .failure(URLError(.notConnectedToInternet))
    
    // MARK: - Call Tracking
    private(set) var dataCallCount = 0
    private(set) var lastRequest: URLRequest?
    
    // MARK: - Mock Implementation
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        dataCallCount += 1
        lastRequest = request
        return try dataResult.get()
    }
    
    // MARK: - Test Helpers
    func reset() {
        dataCallCount = 0
        lastRequest = nil
    }
    
    func stubResponse(data: Data, statusCode: Int = 200) {
        let response = HTTPURLResponse(
            url: URL(string: "https://api.anthropic.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        dataResult = .success((data, response))
    }
    
    func stubError(_ error: Error) {
        dataResult = .failure(error)
    }
}
