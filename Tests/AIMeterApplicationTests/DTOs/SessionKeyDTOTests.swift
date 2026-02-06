import Testing
import Foundation
@testable import AIMeterApplication

@Suite("SessionKeyDTO Tests")
struct SessionKeyDTOTests {

    @Test("SessionKeyDTO stores value, isValid, and organizationId")
    func testSessionKeyDTOStoresProperties() {
        // Arrange & Act
        let dto = SessionKeyDTO(
            value: "sk-ant-test-key",
            isValid: true,
            organizationId: "org-123"
        )

        // Assert
        #expect(dto.value == "sk-ant-test-key")
        #expect(dto.isValid == true)
        #expect(dto.organizationId == "org-123")
    }

    @Test("SessionKeyDTO stores nil organizationId")
    func testSessionKeyDTOStoresNilOrganizationId() {
        // Arrange & Act
        let dto = SessionKeyDTO(
            value: "sk-ant-test-key",
            isValid: false,
            organizationId: nil
        )

        // Assert
        #expect(dto.value == "sk-ant-test-key")
        #expect(dto.isValid == false)
        #expect(dto.organizationId == nil)
    }
}

@Suite("OrganizationResponseDTO Tests")
struct OrganizationResponseDTOTests {

    @Test("OrganizationResponseDTO decodes JSON with memberships")
    func testDecodesJSONWithMemberships() throws {
        // Arrange
        let json = """
        {
            "memberships": [
                {
                    "organization": {
                        "uuid": "org-uuid-1",
                        "name": "Test Org"
                    }
                },
                {
                    "organization": {
                        "uuid": "org-uuid-2",
                        "name": "Another Org"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        // Act
        let decoder = JSONDecoder()
        let dto = try decoder.decode(OrganizationResponseDTO.self, from: json)

        // Assert
        #expect(dto.memberships.count == 2)
        #expect(dto.memberships[0].organization.uuid == "org-uuid-1")
        #expect(dto.memberships[0].organization.name == "Test Org")
        #expect(dto.memberships[1].organization.uuid == "org-uuid-2")
        #expect(dto.memberships[1].organization.name == "Another Org")
    }

    @Test("OrganizationResponseDTO decodes empty memberships")
    func testDecodesEmptyMemberships() throws {
        // Arrange
        let json = """
        {
            "memberships": []
        }
        """.data(using: .utf8)!

        // Act
        let decoder = JSONDecoder()
        let dto = try decoder.decode(OrganizationResponseDTO.self, from: json)

        // Assert
        #expect(dto.memberships.isEmpty)
    }

    @Test("OrganizationResponseDTO round-trip encode/decode")
    func testRoundTripEncodeDecode() throws {
        // Arrange
        let original = OrganizationResponseDTO(
            memberships: [
                MembershipDTO(
                    organization: OrganizationDataDTO(
                        uuid: "org-uuid-test",
                        name: "Test Organization"
                    )
                )
            ]
        )

        // Act
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(OrganizationResponseDTO.self, from: data)

        // Assert
        #expect(decoded.memberships.count == original.memberships.count)
        #expect(decoded.memberships[0].organization.uuid == original.memberships[0].organization.uuid)
        #expect(decoded.memberships[0].organization.name == original.memberships[0].organization.name)
    }
}

@Suite("MembershipDTO Tests")
struct MembershipDTOTests {

    @Test("MembershipDTO decodes with organization")
    func testDecodesWithOrganization() throws {
        // Arrange
        let json = """
        {
            "organization": {
                "uuid": "org-123",
                "name": "My Org"
            }
        }
        """.data(using: .utf8)!

        // Act
        let decoder = JSONDecoder()
        let dto = try decoder.decode(MembershipDTO.self, from: json)

        // Assert
        #expect(dto.organization.uuid == "org-123")
        #expect(dto.organization.name == "My Org")
    }
}

@Suite("OrganizationDataDTO Tests")
struct OrganizationDataDTOTests {

    @Test("OrganizationDataDTO decodes with name")
    func testDecodesWithName() throws {
        // Arrange
        let json = """
        {
            "uuid": "org-456",
            "name": "Organization Name"
        }
        """.data(using: .utf8)!

        // Act
        let decoder = JSONDecoder()
        let dto = try decoder.decode(OrganizationDataDTO.self, from: json)

        // Assert
        #expect(dto.uuid == "org-456")
        #expect(dto.name == "Organization Name")
    }

    @Test("OrganizationDataDTO decodes without name (null)")
    func testDecodesWithoutName() throws {
        // Arrange
        let json = """
        {
            "uuid": "org-789",
            "name": null
        }
        """.data(using: .utf8)!

        // Act
        let decoder = JSONDecoder()
        let dto = try decoder.decode(OrganizationDataDTO.self, from: json)

        // Assert
        #expect(dto.uuid == "org-789")
        #expect(dto.name == nil)
    }

    @Test("OrganizationDataDTO decodes with name field omitted")
    func testDecodesWithNameOmitted() throws {
        // Arrange
        let json = """
        {
            "uuid": "org-999"
        }
        """.data(using: .utf8)!

        // Act
        let decoder = JSONDecoder()
        let dto = try decoder.decode(OrganizationDataDTO.self, from: json)

        // Assert
        #expect(dto.uuid == "org-999")
        #expect(dto.name == nil)
    }

    @Test("OrganizationDataDTO round-trip encode/decode")
    func testRoundTripEncodeDecode() throws {
        // Arrange
        let original = OrganizationDataDTO(
            uuid: "org-roundtrip",
            name: "Round Trip Org"
        )

        // Act
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(OrganizationDataDTO.self, from: data)

        // Assert
        #expect(decoded.uuid == original.uuid)
        #expect(decoded.name == original.name)
    }

    @Test("OrganizationDataDTO round-trip with nil name")
    func testRoundTripWithNilName() throws {
        // Arrange
        let original = OrganizationDataDTO(
            uuid: "org-nil-name",
            name: nil
        )

        // Act
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(OrganizationDataDTO.self, from: data)

        // Assert
        #expect(decoded.uuid == original.uuid)
        #expect(decoded.name == nil)
    }
}
