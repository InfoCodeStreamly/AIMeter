import Foundation
@testable import AIMeter

enum TokenRefreshResponseFixtures {
    
    // MARK: - Token Refresh Responses
    static let validResponseJSON = """
    {
        "access_token": "sk-ant-oat01-new-access-token",
        "refresh_token": "sk-ant-ort01-new-refresh-token",
        "expires_in": 86400,
        "token_type": "Bearer"
    }
    """
    
    static let expiredRefreshTokenJSON = """
    {
        "error": "invalid_grant",
        "error_description": "Refresh token has expired"
    }
    """
}
