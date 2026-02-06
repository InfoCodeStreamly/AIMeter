import AIMeterDomain
import SwiftUI
import Testing

@testable import AIMeterPresentation

/// Tests for UsageStatus UI extensions
///
/// This module contains unit tests for UsageStatus color, icon,
/// and status description mappings following Clean Architecture principles.
@Suite("UsageStatus UI Extensions")
struct UsageStatusUITests {

    // MARK: - Color Tests

    @Test("Safe status returns green color")
    func safeStatusColor() {
        #expect(UsageStatus.safe.color == AccessibleColors.safe)
    }

    @Test("Moderate status returns orange color")
    func moderateStatusColor() {
        #expect(UsageStatus.moderate.color == AccessibleColors.moderate)
    }

    @Test("Critical status returns red color")
    func criticalStatusColor() {
        #expect(UsageStatus.critical.color == .red)
    }

    @Test("All status cases have unique colors")
    func allStatusesHaveUniqueColors() {
        let colors = [
            UsageStatus.safe.color,
            UsageStatus.moderate.color,
            UsageStatus.critical.color,
        ]

        // Verify each color is different by checking they're not equal
        #expect(colors[0] != colors[1])
        #expect(colors[1] != colors[2])
        #expect(colors[0] != colors[2])
    }

    // MARK: - Icon Tests

    @Test("Safe status returns checkmark circle icon")
    func safeStatusIcon() {
        #expect(UsageStatus.safe.icon == "checkmark.circle.fill")
    }

    @Test("Moderate status returns exclamation triangle icon")
    func moderateStatusIcon() {
        #expect(UsageStatus.moderate.icon == "exclamationmark.triangle.fill")
    }

    @Test("Critical status returns xmark circle icon")
    func criticalStatusIcon() {
        #expect(UsageStatus.critical.icon == "xmark.circle.fill")
    }

    @Test("All status cases have non-empty SF Symbol names")
    func allStatusesHaveNonEmptyIcons() {
        for status in UsageStatus.allCases {
            #expect(!status.icon.isEmpty)
        }
    }

    @Test("All status icons are valid SF Symbol names")
    func allStatusIconsAreValidSFSymbols() {
        for status in UsageStatus.allCases {
            let icon = status.icon
            // SF Symbol names should contain letters and may contain dots
            #expect(icon.contains("."))
            #expect(!icon.contains(" "))
        }
    }

    // MARK: - Status Description Tests

    @Test("Safe status returns 'Good' description")
    func safeStatusDescription() {
        #expect(UsageStatus.safe.statusDescription == "Good")
    }

    @Test("Moderate status returns 'Moderate' description")
    func moderateStatusDescription() {
        #expect(UsageStatus.moderate.statusDescription == "Moderate")
    }

    @Test("Critical status returns 'Near Limit' description")
    func criticalStatusDescription() {
        #expect(UsageStatus.critical.statusDescription == "Near Limit")
    }

    @Test("All status cases have non-empty descriptions")
    func allStatusesHaveNonEmptyDescriptions() {
        for status in UsageStatus.allCases {
            #expect(!status.statusDescription.isEmpty)
        }
    }

    @Test("All status descriptions are unique")
    func allStatusDescriptionsAreUnique() {
        let descriptions = UsageStatus.allCases.map { $0.statusDescription }
        let uniqueDescriptions = Set(descriptions)
        #expect(descriptions.count == uniqueDescriptions.count)
    }
}
