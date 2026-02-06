import AppKit
import SwiftUI
import Testing

@testable import AIMeterPresentation

/// WCAG 2.1 Color Contrast Tests
///
/// Verifies that all UI color combinations meet minimum contrast ratios:
/// - **AA Normal text:** 4.5:1
/// - **AA Large text (18pt+ or 14pt+ bold):** 3:1
/// - **AA UI components & graphical objects:** 3:1
///
/// Reference: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum
@Suite("WCAG Color Contrast")
struct WCAGContrastTests {

    // MARK: - Constants

    private static let aaNormalText: Double = 4.5
    private static let aaLargeTextAndUI: Double = 3.0

    // MARK: - Accessible Color NSColor helpers

    /// Resolves AccessibleColors.safe to NSColor in the given appearance.
    private func safeColor(dark: Bool) -> NSColor {
        resolveAccessibleColor(AccessibleColors.safe, dark: dark)
    }

    /// Resolves AccessibleColors.moderate to NSColor in the given appearance.
    private func moderateColor(dark: Bool) -> NSColor {
        resolveAccessibleColor(AccessibleColors.moderate, dark: dark)
    }

    /// Extracts and resolves the underlying NSColor from a SwiftUI Color.
    private func resolveAccessibleColor(_ color: Color, dark: Bool) -> NSColor {
        resolve(NSColor(color), dark: dark)
    }

    // MARK: - Dark Mode Tests

    @Test("Green (safe) contrast on dark background ≥ 3:1")
    func greenOnDarkContrast() {
        let ratio = contrastRatio(
            safeColor(dark: true),
            against: resolve(.windowBackgroundColor, dark: true)
        )
        #expect(ratio >= Self.aaLargeTextAndUI, "Green on dark: \(fmt(ratio)), need ≥ 3:1")
    }

    @Test("Orange (moderate) contrast on dark background ≥ 3:1")
    func orangeOnDarkContrast() {
        let ratio = contrastRatio(
            moderateColor(dark: true),
            against: resolve(.windowBackgroundColor, dark: true)
        )
        #expect(ratio >= Self.aaLargeTextAndUI, "Orange on dark: \(fmt(ratio)), need ≥ 3:1")
    }

    @Test("Red (critical) contrast on dark background ≥ 3:1")
    func redOnDarkContrast() {
        let ratio = contrastRatio(
            resolve(.systemRed, dark: true),
            against: resolve(.windowBackgroundColor, dark: true)
        )
        #expect(ratio >= Self.aaLargeTextAndUI, "Red on dark: \(fmt(ratio)), need ≥ 3:1")
    }

    @Test("Blue (accent) contrast on dark background ≥ 3:1")
    func blueOnDarkContrast() {
        let ratio = contrastRatio(
            resolve(.systemBlue, dark: true),
            against: resolve(.windowBackgroundColor, dark: true)
        )
        #expect(ratio >= Self.aaLargeTextAndUI, "Blue on dark: \(fmt(ratio)), need ≥ 3:1")
    }

    @Test("Purple (chart) contrast on dark background ≥ 3:1")
    func purpleOnDarkContrast() {
        let ratio = contrastRatio(
            resolve(.systemPurple, dark: true),
            against: resolve(.windowBackgroundColor, dark: true)
        )
        #expect(ratio >= Self.aaLargeTextAndUI, "Purple on dark: \(fmt(ratio)), need ≥ 3:1")
    }

    @Test("Primary text contrast on dark background ≥ 4.5:1")
    func primaryTextOnDarkContrast() {
        let ratio = contrastRatio(
            resolve(.labelColor, dark: true),
            against: resolve(.windowBackgroundColor, dark: true)
        )
        #expect(ratio >= Self.aaNormalText, "Primary on dark: \(fmt(ratio)), need ≥ 4.5:1")
    }

    @Test("Secondary text contrast on dark background ≥ 3:1")
    func secondaryTextOnDarkContrast() {
        let ratio = contrastRatio(
            resolve(.secondaryLabelColor, dark: true),
            against: resolve(.windowBackgroundColor, dark: true)
        )
        #expect(ratio >= Self.aaLargeTextAndUI, "Secondary on dark: \(fmt(ratio)), need ≥ 3:1")
    }

    // MARK: - Light Mode Tests

    @Test("Green (safe) contrast on light background ≥ 3:1")
    func greenOnLightContrast() {
        let ratio = contrastRatio(
            safeColor(dark: false),
            against: resolve(.windowBackgroundColor, dark: false)
        )
        #expect(ratio >= Self.aaLargeTextAndUI, "Green on light: \(fmt(ratio)), need ≥ 3:1")
    }

    @Test("Orange (moderate) contrast on light background ≥ 3:1")
    func orangeOnLightContrast() {
        let ratio = contrastRatio(
            moderateColor(dark: false),
            against: resolve(.windowBackgroundColor, dark: false)
        )
        #expect(ratio >= Self.aaLargeTextAndUI, "Orange on light: \(fmt(ratio)), need ≥ 3:1")
    }

    @Test("Red (critical) contrast on light background ≥ 3:1")
    func redOnLightContrast() {
        let ratio = contrastRatio(
            resolve(.systemRed, dark: false),
            against: resolve(.windowBackgroundColor, dark: false)
        )
        #expect(ratio >= Self.aaLargeTextAndUI, "Red on light: \(fmt(ratio)), need ≥ 3:1")
    }

    @Test("Blue (accent) contrast on light background ≥ 3:1")
    func blueOnLightContrast() {
        let ratio = contrastRatio(
            resolve(.systemBlue, dark: false),
            against: resolve(.windowBackgroundColor, dark: false)
        )
        #expect(ratio >= Self.aaLargeTextAndUI, "Blue on light: \(fmt(ratio)), need ≥ 3:1")
    }

    @Test("Purple (chart) contrast on light background ≥ 3:1")
    func purpleOnLightContrast() {
        let ratio = contrastRatio(
            resolve(.systemPurple, dark: false),
            against: resolve(.windowBackgroundColor, dark: false)
        )
        #expect(ratio >= Self.aaLargeTextAndUI, "Purple on light: \(fmt(ratio)), need ≥ 3:1")
    }

    @Test("Primary text contrast on light background ≥ 4.5:1")
    func primaryTextOnLightContrast() {
        let ratio = contrastRatio(
            resolve(.labelColor, dark: false),
            against: resolve(.windowBackgroundColor, dark: false)
        )
        #expect(ratio >= Self.aaNormalText, "Primary on light: \(fmt(ratio)), need ≥ 4.5:1")
    }

    @Test("Secondary text contrast on light background ≥ 3:1")
    func secondaryTextOnLightContrast() {
        let ratio = contrastRatio(
            resolve(.secondaryLabelColor, dark: false),
            against: resolve(.windowBackgroundColor, dark: false)
        )
        #expect(ratio >= Self.aaLargeTextAndUI, "Secondary on light: \(fmt(ratio)), need ≥ 3:1")
    }

    // MARK: - Color Distinguishability

    @Test("Status colors are distinguishable in dark mode")
    func statusColorsDistinguishableInDark() {
        let green = safeColor(dark: true)
        let orange = moderateColor(dark: true)
        let red = resolve(.systemRed, dark: true)

        let greenOrange = contrastRatio(green, against: orange)
        let greenRed = contrastRatio(green, against: red)

        #expect(greenOrange > 1.1, "Green vs Orange (dark): \(fmt(greenOrange))")
        #expect(greenRed > 1.2, "Green vs Red (dark): \(fmt(greenRed))")
    }

    @Test("Status colors are distinguishable in light mode")
    func statusColorsDistinguishableInLight() {
        let green = safeColor(dark: false)
        let orange = moderateColor(dark: false)
        let red = resolve(.systemRed, dark: false)

        let greenOrange = contrastRatio(green, against: orange)
        let greenRed = contrastRatio(green, against: red)

        #expect(greenOrange > 1.1, "Green vs Orange (light): \(fmt(greenOrange))")
        #expect(greenRed > 1.2, "Green vs Red (light): \(fmt(greenRed))")
    }

    // MARK: - Helpers

    /// Resolves a dynamic NSColor for a specific appearance.
    private func resolve(_ color: NSColor, dark: Bool) -> NSColor {
        let name: NSAppearance.Name = dark ? .darkAqua : .aqua
        guard let appearance = NSAppearance(named: name) else {
            return color.usingColorSpace(.sRGB) ?? color
        }
        var resolved = color
        appearance.performAsCurrentDrawingAppearance {
            resolved = color.usingColorSpace(.sRGB) ?? color
        }
        return resolved
    }

    /// WCAG 2.1 contrast ratio: (L1 + 0.05) / (L2 + 0.05) where L1 ≥ L2
    private func contrastRatio(_ color1: NSColor, against color2: NSColor) -> Double {
        let l1 = relativeLuminance(of: color1)
        let l2 = relativeLuminance(of: color2)
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Relative luminance per WCAG 2.1.
    private func relativeLuminance(of color: NSColor) -> Double {
        let rgb = color.usingColorSpace(.sRGB) ?? color
        let r = linearize(Double(rgb.redComponent))
        let g = linearize(Double(rgb.greenComponent))
        let b = linearize(Double(rgb.blueComponent))
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Linearizes sRGB channel value.
    private func linearize(_ channel: Double) -> Double {
        channel <= 0.04045
            ? channel / 12.92
            : pow((channel + 0.055) / 1.055, 2.4)
    }

    private func fmt(_ ratio: Double) -> String {
        "\(String(format: "%.2f", ratio)):1"
    }
}
