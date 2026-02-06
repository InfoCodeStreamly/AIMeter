import SwiftUI

// MARK: - Glass Card Modifier

/// Applies Liquid Glass on macOS 26+ (Xcode 26 / Swift 6.1+), falls back to material background.
struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        #if compiler(>=6.1)
            if #available(macOS 26.0, *) {
                content
                    .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            } else {
                fallbackCard(content)
            }
        #else
            fallbackCard(content)
        #endif
    }

    private func fallbackCard(_ content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        Color.gray.opacity(UIConstants.SettingsCard.borderOpacity),
                        lineWidth: UIConstants.SettingsCard.borderWidth
                    )
            )
    }
}

// MARK: - Glass Button Style Modifier

/// Applies `.buttonStyle(.glass)` on macOS 26+, falls back to `.bordered`.
struct GlassButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if compiler(>=6.1)
            if #available(macOS 26.0, *) {
                content.buttonStyle(.glass)
            } else {
                content.buttonStyle(.bordered)
            }
        #else
            content.buttonStyle(.bordered)
        #endif
    }
}

// MARK: - Glass Tab Modifier (interactive)

/// Applies interactive glass effect on macOS 26+, falls back to tinted background.
struct GlassTabModifier: ViewModifier {
    let isSelected: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        #if compiler(>=6.1)
            if #available(macOS 26.0, *) {
                content
                    .glassEffect(
                        isSelected ? .regular.interactive() : .clear.interactive(),
                        in: .rect(cornerRadius: cornerRadius)
                    )
            } else {
                fallbackTab(content)
            }
        #else
            fallbackTab(content)
        #endif
    }

    private func fallbackTab(_ content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(isSelected ? Color.blue.opacity(0.12) : Color.clear)
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Glass card background with availability fallback.
    func glassCard(cornerRadius: CGFloat = UIConstants.CornerRadius.medium) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    /// Glass button style with availability fallback.
    func glassButton() -> some View {
        modifier(GlassButtonModifier())
    }

    /// Glass tab effect with availability fallback.
    func glassTab(isSelected: Bool, cornerRadius: CGFloat = UIConstants.CornerRadius.medium)
        -> some View
    {
        modifier(GlassTabModifier(isSelected: isSelected, cornerRadius: cornerRadius))
    }
}
