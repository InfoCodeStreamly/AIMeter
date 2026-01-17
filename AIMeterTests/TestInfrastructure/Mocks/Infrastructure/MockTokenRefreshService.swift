import Foundation
@testable import AIMeter

actor MockTokenRefreshService: TokenRefreshServiceProtocol {

    // MARK: - Stub Results
    var refreshResult: Result<TokenRefreshService.TokenRefreshResponse, Error> = .success(
        TokenRefreshService.TokenRefreshResponse(
            accessToken: "sk-ant-oat01-refreshed-token",
            refreshToken: "sk-ant-ort01-refreshed-token",
            expiresIn: 86400
        )
    )

    // MARK: - Call Tracking
    private(set) var refreshCallCount = 0
    private(set) var lastRefreshToken: String?

    // MARK: - Protocol Implementation
    func refresh(using refreshToken: String) async throws -> TokenRefreshService.TokenRefreshResponse {
        refreshCallCount += 1
        lastRefreshToken = refreshToken
        return try refreshResult.get()
    }

    // MARK: - Test Helpers
    func reset() {
        refreshCallCount = 0
        lastRefreshToken = nil
        refreshResult = .success(
            TokenRefreshService.TokenRefreshResponse(
                accessToken: "sk-ant-oat01-refreshed-token",
                refreshToken: "sk-ant-ort01-refreshed-token",
                expiresIn: 86400
            )
        )
    }

    func stubError(_ error: Error) {
        refreshResult = .failure(error)
    }

    func stubSuccess(accessToken: String, refreshToken: String, expiresIn: Int) {
        refreshResult = .success(
            TokenRefreshService.TokenRefreshResponse(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn
            )
        )
    }
}
