import Foundation

/// Data Transfer Object for session key validation
struct SessionKeyDTO: Sendable {
    let value: String
    let isValid: Bool
    let organizationId: String?
}

/// Organization response from Claude API
struct OrganizationResponseDTO: Sendable, Codable {
    let memberships: [MembershipDTO]
}

/// Membership data from API
struct MembershipDTO: Sendable, Codable {
    let organization: OrganizationDataDTO
}

/// Organization data from API
struct OrganizationDataDTO: Sendable, Codable {
    let uuid: String
    let name: String?
}
