import SwiftUI

/// Card view for displaying Claude Code team analytics
struct OrgAnalyticsCardView: View {
    let data: ClaudeCodeAnalyticsDisplayData

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
            // Header
            HStack {
                Label {
                    Text("Team Activity", tableName: "MenuBar", bundle: .main)
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: "person.3")
                        .foregroundStyle(.purple)
                }

                Spacer()

                Text(data.totalCostFormatted)
                    .font(.subheadline.weight(.bold).monospacedDigit())
            }

            // Summary row
            HStack(spacing: UIConstants.Spacing.lg) {
                summaryItem(
                    icon: "terminal",
                    value: "\(data.totalSessions)",
                    label: "Sessions"
                )

                summaryItem(
                    icon: "text.line.first.and.arrowtriangle.forward",
                    value: "+\(data.totalLinesAdded)",
                    label: "Lines"
                )

                Spacer()

                // Expand toggle
                if !data.users.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Text("\(data.users.count)")
                                .font(.caption)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Per-user breakdown (expandable)
            if isExpanded {
                Divider()

                ForEach(data.users) { user in
                    HStack {
                        Text(user.email)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        Text("\(user.sessions)s")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)

                        Text("+\(user.linesAdded)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)

                        Text(user.costFormatted)
                            .font(.caption.weight(.medium).monospacedDigit())
                            .foregroundStyle(.primary)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding(UIConstants.Spacing.md)
        .glassCard()
    }

    private func summaryItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption.weight(.medium).monospacedDigit())
                Text(LocalizedStringKey(label), tableName: "MenuBar", bundle: .main)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
