import Foundation

/// Raw API response for organizations
struct OrganizationAPIResponse: Sendable, Codable {
    let memberships: [MembershipData]?

    /// Alternative format (direct array)
    init(from decoder: Decoder) throws {
        // Try decoding as object with memberships array
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.memberships = try container.decodeIfPresent([MembershipData].self, forKey: .memberships)
        } else {
            // Try decoding as direct array
            let container = try decoder.singleValueContainer()
            self.memberships = try container.decode([MembershipData].self)
        }
    }

    enum CodingKeys: String, CodingKey {
        case memberships
    }

    /// Returns first organization ID if available
    var firstOrganizationId: String? {
        memberships?.first?.organization.uuid
    }
}

/// Membership data from API
struct MembershipData: Sendable, Codable {
    let organization: OrganizationData

    enum CodingKeys: String, CodingKey {
        case organization
    }
}

/// Organization details
struct OrganizationData: Sendable, Codable {
    let uuid: String
    let name: String?
    let capabilities: [String]?

    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case capabilities
    }
}
