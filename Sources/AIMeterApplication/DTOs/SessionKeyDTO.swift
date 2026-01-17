import Foundation
import AIMeterDomain

/// Data Transfer Object for session key validation
public struct SessionKeyDTO: Sendable {
    public let value: String
    public let isValid: Bool
    public let organizationId: String?
}

/// Organization response from Claude API
public struct OrganizationResponseDTO: Sendable, Codable {
    public let memberships: [MembershipDTO]
}

/// Membership data from API
public struct MembershipDTO: Sendable, Codable {
    public let organization: OrganizationDataDTO
}

/// Organization data from API
public struct OrganizationDataDTO: Sendable, Codable {
    public let uuid: String
    public let name: String?
}
