import SwiftUI

/// Session key input field component with secure toggle
struct SessionKeyInputView: View {
    @Binding var text: String
    let placeholder: String
    let isDisabled: Bool
    var onSubmit: (() -> Void)?

    @State private var isSecure = true
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: UIConstants.Spacing.sm) {
            inputField
            toggleButton
        }
        .padding(UIConstants.Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                .stroke(borderColor, lineWidth: 1)
        }
    }

    // MARK: - Input Field

    @ViewBuilder
    private var inputField: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
                    .onSubmit { onSubmit?() }
            } else {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .onSubmit { onSubmit?() }
            }
        }
        .textFieldStyle(.plain)
        .font(.system(.body, design: .monospaced))
        .disabled(isDisabled)
    }

    // MARK: - Toggle Button

    private var toggleButton: some View {
        Button {
            isSecure.toggle()
        } label: {
            Image(systemName: isSecure ? "eye.slash" : "eye")
                .foregroundStyle(.secondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .help(isSecure ? "Show key" : "Hide key")
        .disabled(isDisabled)
    }

    // MARK: - Computed

    private var borderColor: Color {
        if isFocused {
            return .accentColor.opacity(0.5)
        }
        return .secondary.opacity(0.2)
    }
}

// MARK: - Preview

#Preview("Empty") {
    SessionKeyInputView(
        text: .constant(""),
        placeholder: "Paste your session key",
        isDisabled: false
    )
    .padding()
    .frame(width: 400)
}

#Preview("With Value") {
    SessionKeyInputView(
        text: .constant("sk-ant-api-key-here-very-long-key"),
        placeholder: "Paste your session key",
        isDisabled: false
    )
    .padding()
    .frame(width: 400)
}

#Preview("Disabled") {
    SessionKeyInputView(
        text: .constant("sk-ant-api-key-here"),
        placeholder: "Paste your session key",
        isDisabled: true
    )
    .padding()
    .frame(width: 400)
}
